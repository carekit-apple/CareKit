/*
 Copyright (c) 2022, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CoreData
import Foundation
import os.log
import Synchronization

/// A wrapper around Core Data that allows for starting and stopping a live query.
final class CoreDataQueryMonitor<Element: OCKCDVersionedObject>: NSObject, Sendable, NSFetchedResultsControllerDelegate {

    private struct State {
        nonisolated(unsafe) var controller: NSFetchedResultsController<Element>?
        var resultHandler: @Sendable (Result<[OCKVersionedObjectCompatible], Error>) -> Void = { _ in }
    }

    private let state: Mutex<State>

    private nonisolated(unsafe) let request: NSFetchRequest<Element>
    private nonisolated(unsafe) let context: NSManagedObjectContext

    var resultHandler: @Sendable (Result<[OCKVersionedObjectCompatible], Error>) -> Void {
        get {
            return state.withLock { $0.resultHandler }
        } set {
            state.withLock { $0.resultHandler = newValue }
        }
    }

    /// A wrapper around Core Data that allows for starting and stopping a live query.
    init(
        _ elementType: Element.Type,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor],
        context: NSManagedObjectContext,
        resultHandler: @Sendable @escaping (Result<[OCKVersionedObjectCompatible], Error>) -> Void = { _ in }
    ) {
        let request = NSFetchRequest<Element>(
            entityName: Element.entity().name!
        )

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.returnsObjectsAsFaults = false

        self.request = request
        self.context = context
        state = Mutex(State(resultHandler: resultHandler))
    }
    
    func startQuery() {

        let initialResult: Result<[OCKVersionedObjectCompatible], Error>? = state.withLock { state in

            // Don't perform the query again if it's already running
            guard state.controller == nil else {
                return nil
            }

            // Create a controller that will be used to fetch Core Data entities

            state.controller = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            state.controller?.delegate = self

            // Fetch the initial data from the Core Data store

            do {
                try state.controller!.performFetch()
            } catch {
                os_log(.error, log: .store, "Query failed: %@", error as NSError)
                return .failure(error)
            }

            let results = state.controller?.fetchedObjects ?? []
            let transformedResults = results.map { $0.makeValue() }
            return .success(transformedResults)
        }

        if let initialResult {
            resultHandler(initialResult)
        }
    }

    func stopQuery() {
        state.withLock { state in
            state.controller?.delegate = nil
            state.controller = nil
        }
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        let results: [OCKVersionedObjectCompatible]? = state.withLock { state in

            guard
                let storedController = state.controller,
                storedController == controller
            else {
                return nil
            }

            let results = storedController.fetchedObjects ?? []
            let transformedResults = results.map { $0.makeValue() }
            return transformedResults
        }

        // Forward an updated query result whenever a change is detected
        if let results {
            resultHandler(.success(results))
        }
    }
}

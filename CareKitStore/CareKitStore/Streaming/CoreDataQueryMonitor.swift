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

/// A wrapper around Core Data that allows for starting and stopping a live query.
final class CoreDataQueryMonitor<
    QueryResultElement: NSManagedObject
>: NSObject, QueryMonitor, NSFetchedResultsControllerDelegate {

    private let request: NSFetchRequest<QueryResultElement>
    private let context: NSManagedObjectContext

    private var controller: NSFetchedResultsController<QueryResultElement>?

    var resultHandler: (Result<[QueryResultElement], Error>) -> Void = { _ in }

    /// A wrapper around Core Data that allows for starting and stopping a live query.
    init(
        _ elementType: QueryResultElement.Type,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor],
        context: NSManagedObjectContext
    ) {
        let request = NSFetchRequest<QueryResultElement>(
            entityName: QueryResultElement.entity().name!
        )

        request.predicate = predicate
        request.sortDescriptors = sortDescriptors

        self.request = request
        self.context = context
    }
    
    func startQuery() {

        // Don't perform the query again if it's already running
        guard controller == nil else { return }

        // Create a controller that will be used to fetch Core Data entities

        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        controller?.delegate = self

        // Fetch the initial data from the Core Data store

        do {
            try controller!.performFetch()
        } catch {
            os_log(.error, log: .store, "Query failed: %@", error as NSError)
            resultHandler(.failure(error))
            return
        }

        let result = controller!.fetchedObjects ?? []
        resultHandler(.success(result))
    }

    func stopQuery() {
        controller?.delegate = nil
        controller = nil
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        // Forward an updated query result whenever a change is detected

        guard
            let storedController = self.controller,
            storedController == controller
        else {
            return
        }

        let result = storedController.fetchedObjects ?? []
        resultHandler(.success(result))
    }
}

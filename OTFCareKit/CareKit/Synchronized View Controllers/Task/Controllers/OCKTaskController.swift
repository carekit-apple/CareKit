/*
 Copyright (c) 2019, Apple Inc. All rights reserved.

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

import CareKitStore
import Combine
import Foundation

/// A basic controller capable of watching and updating tasks.
open class OCKTaskController: OCKTaskControllerProtocol, ObservableObject {

    // MARK: OCKTaskControllerProtocol

    public let objectWillChange: CurrentValueSubject<OCKTaskEvents?, Never>
    public var store: OCKAnyOutcomeStore { storeManager.store }

    // MARK: - Properties

    /// The store manager against which the task will be synchronized.
    public let storeManager: OCKSynchronizedStoreManager

    private var cancellables: Set<AnyCancellable> = Set()

    // MARK: - Life Cycle

    /// Initialize with a store manager.
    public required init(storeManager: OCKSynchronizedStoreManager) {
        self.storeManager = storeManager
        self.objectWillChange = .init(nil)
    }

    // MARK: - Methods

    /// Begin observing a task.
    ///
    /// - Parameters:
    ///   - task: The task to watch for changes.
    ///   - eventQuery: A query describing the date range over which to watch for changes.
    open func fetchAndObserveEvents(forTask task: OCKAnyTask, eventQuery: OCKEventQuery, errorHandler: ((Error) -> Void)? = nil) {
        fetchAndObserveEvents(forTaskIDs: [task.id], eventQuery: eventQuery, errorHandler: errorHandler)
    }

    /// Begin watching events from multiple tasks for changes.
    ///
    /// - Parameters:
    ///   - taskIDs: The user-chosen unique identifiers for the tasks to be watched.
    ///   - eventQuery: A query describing the date range over which to watch for changes.
    open func fetchAndObserveEvents(forTaskIDs taskIDs: [String], eventQuery: OCKEventQuery, errorHandler: ((Error) -> Void)? = nil) {
        cancellables = Set()

        // Build the task query from the event query
        var taskQuery = OCKTaskQuery(dateInterval: eventQuery.dateInterval)
        taskQuery.ids = taskIDs

        // Fetch the tasks, then fetch and subscribe to events for the tasks
        storeManager.store.fetchAnyTasks(query: taskQuery, callbackQueue: .main) { [weak self] result in
            switch result {
            case .failure(let error): errorHandler?(error)
            case .success(let tasks):
                tasks.forEach {
                    guard let self = self else { return }
                    self.fetchAndSubscribeToEvents(forTask: $0, query: eventQuery, errorHandler: errorHandler)
                    self.storeManager.publisher(forTask: $0, categories: [.add, .update, .delete]).sink { [weak self] _ in
                        self?.fetchAndObserveEvents(forTaskIDs: taskIDs, eventQuery: eventQuery, errorHandler: errorHandler)
                    }.store(in: &self.cancellables)
                }
            }
        }
    }

    /// Begin watching a single task's events for changes.
    ///
    /// - Parameters:
    ///   - taskID: The user-chosen unique identifier for the task to be watched.
    ///   - eventQuery: A query describing the date range over which to watch for changes.
    open func fetchAndObserveEvents(forTaskID taskID: String, eventQuery: OCKEventQuery, errorHandler: ((Error) -> Void)? = nil) {
        fetchAndObserveEvents(forTaskIDs: [taskID], eventQuery: eventQuery, errorHandler: errorHandler)
    }

    func updateViewModel(withEvents events: [OCKAnyEvent]) {
        let taskIds = events.map { $0.task.id }
        assert(taskIds.dropFirst().allSatisfy { $0 == taskIds.first }, "Events should belong to the same task.")

        // Add each event to the view model and set the view model value
        var viewModel = OCKTaskEvents()
        events.map { self.modified(event: $0) }
            .sorted(by: { $0.scheduleEvent.start < $1.scheduleEvent.start })
            .forEach { viewModel.addEvent($0) }
        self.objectWillChange.value = viewModel
    }

    func modified(event: OCKAnyEvent) -> OCKAnyEvent {
        return event
    }

    // Update the view model when events for a particular task change
    func subscribeTo(eventsBelongingToTask task: OCKAnyTask, eventQuery: OCKEventQuery) {
        storeManager.publisher(forEventsBelongingToTask: task, query: eventQuery, categories: [.update, .add, .delete])
            .sink { [weak self] newValue in
                guard let self = self else { return }
                let modifiedEvent = self.modified(event: newValue)
                self.objectWillChange.value?.containsEvent(modifiedEvent) ?? false ?
                    self.objectWillChange.value?.updateEvent(modifiedEvent) :
                    self.objectWillChange.value?.addEvent(modifiedEvent)
        }.store(in: &cancellables)
    }

    private func fetchAndSubscribeToEvents(forTask task: OCKAnyTask, query: OCKEventQuery, errorHandler: ((Error) -> Void)? = nil) {
        storeManager.store.fetchAnyEvents(taskID: task.id, query: query, callbackQueue: .main) { [weak self] result in
            switch result {
            case .failure(let error): errorHandler?(error)
            case .success(let events):
                self?.updateViewModel(withEvents: events)
                self?.subscribeTo(eventsBelongingToTask: task, eventQuery: query)
            }
        }
    }
}

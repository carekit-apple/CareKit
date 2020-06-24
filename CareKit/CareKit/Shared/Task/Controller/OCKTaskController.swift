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
import CareKitUI
import Combine
import Foundation
import UIKit

/// A basic controller capable of watching and updating tasks.
open class OCKTaskController: ObservableObject {

    // MARK: - Properties

    /// The current task events. Subscribe to the projected value to be notified when the task and events change.
    @Published public final var taskEvents = OCKTaskEvents()

    /// The error encountered by the controller.
    @Published public internal(set) var error: Error?

    /// The store manager against which the task will be synchronized.
    public let storeManager: OCKSynchronizedStoreManager

    private var cancellables: Set<AnyCancellable> = []                  // More general cancellables, often for task and event queries
    private var taskCancellables: [String: Set<AnyCancellable>] = [:]   // Maps a task's ID to relevant cancellables

    // MARK: - Life Cycle

    /// Initialize with a store manager.
    public required init(storeManager: OCKSynchronizedStoreManager) {
        self.storeManager = storeManager
    }

    // MARK: - Synchronization

    /// Fetch tasks and events based on the given queries. Once the events are received, the view model will be updated and this controller will
    /// subscribe to any changes that occur in the store that affect the tasks and events received by the given queries.
    ///
    /// Calling this method clears the current state of the controller. Any existing view model will be cleared in favor of results from
    /// a new fetch query.
    ///
    /// This is an asynchronous method. In order to determine when the fetching is complete and the view model has been updated, hook into
    /// the `objectWillChange` publisher. On success, the view model will be filled with events. On failure, the view model will be cleared.
    ///
    /// - Parameters:
    ///   - taskQuery: A query used to fetch tasks in the store.
    ///   - eventQuery: A query used to fetch events in the store.
    open func fetchAndObserveEvents(forTaskQuery taskQuery: OCKTaskQuery, eventQuery: OCKEventQuery) {
        clearSubscriptions()

        // We only subscribe to changes for the tasks and events that we receive in a query. It's possible that after initially fetching tasks and
        // events, a new task is added that matches the given task query. When that happens we must re-query.
        refreshOnAddedTaskNotificationFor(taskQuery: taskQuery, eventQuery: eventQuery)

        storeManager
            // Fetch tasks for the given query.
            .fetchAnyTasksPublisher(query: taskQuery)
            // If there was an error fetching tasks, clear the view model and notify the developer.
            // SomePublisher<[OCKAnyTask], Never>
            .catch { [unowned self] error -> Empty<[OCKAnyTask], Never> in
                self.taskEvents = .init()
                self.error = error
                return .init()
            }
            // Fetch events for the newly received tasks and observe changes to tasks and events.
            .sink { [unowned self] tasks in
                let ids = Array(Set(tasks.map { $0.id }))
                self.fetchAndObserveEvents(forTaskIDs: ids, eventQuery: eventQuery, overwritesViewModel: true, clearsViewModelOnFailure: true)
            }.store(in: &cancellables)
    }

    /// Fetch events for the given tasks. Once the events are received, the view model will be updated and this controller will
    /// subscribe to any changes that occur in the store that affect the tasks and events received by the given queries.
    ///
    /// Calling this method clears the current state of the controller. Any existing view model will be cleared in favor of results from
    /// a new fetch query.
    ///
    /// This is an asynchronous method. In order to determine when the fetching is complete and the view model has been updated, hook into
    /// the `objectWillChange` publisher. On success, the view model will be filled with events. On failure, the view model will be cleared.
    ///
    /// - Parameters:
    ///   - tasks: Fetch events for these tasks.
    ///   - eventQuery: A query used to fetch events in the store.
    open func fetchAndObserveEvents(forTasks tasks: [OCKAnyTask], eventQuery: OCKEventQuery) {
        let ids = Array(Set(tasks.map { $0.id }))
        fetchAndObserveEvents(forTaskIDs: ids, eventQuery: eventQuery)
    }

    /// Fetch tasks and events based on the given task IDs. Once the events are received, the view model will be updated and this controller will
    /// subscribe to any changes that occur in the store that affect the tasks and events received by the given queries.
    ///
    /// Calling this method clears the current state of the controller. Any existing view model will be cleared in favor of results from
    /// a new fetch query.
    ///
    /// This is an asynchronous method. In order to determine when the fetching is complete and the view model has been updated, hook into
    /// the `objectWillChange` publisher. On success, the view model will be filled with events. On failure, the view model will be cleared.
    ///
    /// - Parameters:
    ///   - taskIDs: Fetch events whose tasks have the given IDs.
    ///   - eventQuery: A query used to fetch events in the store.
    open func fetchAndObserveEvents(forTaskIDs taskIDs: [String], eventQuery: OCKEventQuery) {
        clearSubscriptions()
        refreshOnAddedTaskNotificationFor(taskIDs: taskIDs, query: eventQuery)
        fetchAndObserveEvents(forTaskIDs: taskIDs, eventQuery: eventQuery, overwritesViewModel: true, clearsViewModelOnFailure: true)
    }

    /// Override this method to modify events before they are inserted into the view model.
    func modified(event: OCKAnyEvent) -> OCKAnyEvent {
        return event
    }

    /// Set the view model directly and subscribe to any changes that occur in the store that affect the events.
    ///
    /// Calling this method clears the current state of the controller. Any existing view model will be cleared in favor of the new events.
    ///
    /// - Parameters:
    ///   - events: The events used to populate the view model.
    ///   - query: The query that was used to fetch the events.
    func setViewModelAndObserve(events: [OCKAnyEvent], query: OCKEventQuery) {
        clearSubscriptions()

        let modifiedEvents = events.map { modified(event: $0 ) }
        let viewModel = OCKTaskEvents(events: modifiedEvents)
        self.taskEvents = viewModel
        subscribeTo(tasks: viewModel.tasks, query: query)
    }

    func refreshOnAddedTaskNotificationFor(taskIDs: [String], query: OCKEventQuery) {
        storeManager
            .publisherForTasks(categories: [.add])
            .filter { taskIDs.contains($0.task.id) }
            .sink { [unowned self] _ in
                // Re-query for tasks and events
                self.fetchAndObserveEvents(forTaskIDs: taskIDs, eventQuery: query)
            }.store(in: &self.cancellables)

        storeManager.notificationPublisher
            .filter { $0 is OCKUnknownChangeNotification }
            .sink { [unowned self] _ in
                // Re-query for tasks and events
                self.fetchAndObserveEvents(forTaskIDs: taskIDs, eventQuery: query)
            }.store(in: &self.cancellables)
    }

    func refreshOnAddedTaskNotificationFor(taskQuery: OCKTaskQuery, eventQuery: OCKEventQuery) {
        storeManager
            .publisherForTasks(categories: [.add])
            .sink { [unowned self] _ in
                // Re-query for tasks and events
                self.fetchAndObserveEvents(forTaskQuery: taskQuery, eventQuery: eventQuery)
            }.store(in: &self.cancellables)

        storeManager.notificationPublisher
            .filter { $0 is OCKUnknownChangeNotification }
            .sink { [unowned self] _ in
                // Re-query for tasks and events
                self.fetchAndObserveEvents(forTaskQuery: taskQuery, eventQuery: eventQuery)
            }.store(in: &self.cancellables)
    }

    /// Subscribe to changes for the given tasks and associated events that fit the event query.
    func subscribeTo(tasks: [OCKAnyTask], query: OCKEventQuery) {
        tasks.forEach {
            subscribeTo(task: $0, query: query)
            subscribeToEventsBelongingTo(task: $0, query: query)
        }
    }

    /// Fetch events and subscribe to changes. When the events are fetched, the view model will be updated.
    /// - Parameters:
    ///   - taskIDs: Fetch events whose tasks have the given IDs.
    ///   - eventQuery: A query used to fetch events in the store.
    ///   - overwritesViewModel: If true, the view model will be overwritten with the newly fetched events. Else, the events will be appended.
    ///   - clearsViewModelOnFailure: True if the view model should be cleared when an error is encountered.
    private func fetchAndObserveEvents(forTaskIDs taskIDs: [String], eventQuery: OCKEventQuery,
                                       overwritesViewModel: Bool, clearsViewModelOnFailure: Bool) {
        // Fetch events for the given task IDs.
        storeManager.fetchAnyEventsPublisher(taskIDs: taskIDs, query: eventQuery) { [unowned self] error in
            // No need to clear the state when we receive an error when fetching events for a single task. We may successfully find
            // events for other tasks. Just let the developer know an error has occurred.
            self.error = error
        }
        .sink { [unowned self] events in

            // If no events were found, clear the view model
            if clearsViewModelOnFailure && events.isEmpty {
                self.taskEvents = .init()
                return
            }

            // Remove any stale events from the current view model, and stop listening to changes for them.
            var currentViewModel = overwritesViewModel ? OCKTaskEvents() : self.taskEvents
            currentViewModel
                .flatMap { $0 }
                .filter { taskIDs.contains($0.task.id) }
                .forEach { currentViewModel.remove(event: $0) }
            taskIDs.forEach { self.taskCancellables[$0] = nil }

            // Update the current view model and begin listen to changes for the new events and tasks.
            let modifiedEvents = events
                .flatMap { $0 }
                .map { self.modified(event: $0 ) }
            let viewModelUpdates = OCKTaskEvents(events: modifiedEvents)
            modifiedEvents.forEach { currentViewModel.append(event: $0) }
            self.taskEvents = currentViewModel
            self.subscribeTo(tasks: viewModelUpdates.tasks, query: eventQuery)
        }
        .store(in: &cancellables)
    }

    private func subscribeToEventsBelongingTo(task: OCKAnyTask, query: OCKEventQuery) {
        storeManager
            .publisher(forEventsBelongingToTask: task, query: query, categories: [.add, .update, .delete])
            .sink { [unowned self] event in
                self.taskEvents.update(event: self.modified(event: event))
            }
        .store(in: &taskCancellables, key: task.id)
    }

    private func subscribeTo(task: OCKAnyTask, query: OCKEventQuery) {
        storeManager
            .publisher(forTask: task, categories: [.add, .update, .delete])
            .sink { [unowned self] _ in
                self.fetchAndObserveEvents(forTaskIDs: [task.id], eventQuery: query, overwritesViewModel: false, clearsViewModelOnFailure: false)
            }.store(in: &taskCancellables, key: task.id)
    }

    private func clearSubscriptions() {
        cancellables = []
        taskCancellables = [:]
    }

    // MARK: - Utilities

    /// Set the completion state for an event.
    /// - Parameters:
    ///   - indexPath: Index path of the event.
    ///   - isComplete: True if the event is complete.
    ///   - completion: Result after setting the completion for the event.
    open func setEvent(atIndexPath indexPath: IndexPath, isComplete: Bool, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        let event: OCKAnyEvent
        do {
            _ = try validatedViewModel()
            event = try validatedEvent(forIndexPath: indexPath)
        } catch {
            completion?(.failure(error))
            return
        }

        // If the event is complete, create an outcome with a `true` value
        if isComplete {
            do {
                let outcome = try makeOutcomeFor(event: event, withValues: [.init(true)])
                storeManager.store.addAnyOutcome(outcome) { result in
                    switch result {
                    case .failure(let error): completion?(.failure(error))
                    case .success(let outcome): completion?(.success(outcome))
                    }
                }
            } catch {
                completion?(.failure(error))
            }

        // if the event is incomplete, delete the outcome
        } else {
            guard let outcome = event.outcome else { return }
            storeManager.store.deleteAnyOutcome(outcome) { result in
                switch result {
                case .failure(let error): completion?(.failure(error))
                case .success(let outcome): completion?(.success(outcome))
                }
            }
        }
    }

    /// Append an outcome value to an event's outcome.
    /// - Parameters:
    ///   - value: The value for the outcome value that is being created.
    ///   - indexPath: Index path of the event to which the outcome will be added.
    ///   - completion: Result after creating the outcome value.
    open func appendOutcomeValue(
        value: OCKOutcomeValueUnderlyingType,
        at indexPath: IndexPath,
        completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {

        let event: OCKAnyEvent
        do {
            _ = try validatedViewModel()
            event = try validatedEvent(forIndexPath: indexPath)
        } catch {
            completion?(.failure(error))
            return
        }

        let value = OCKOutcomeValue(value)

        // Update the outcome with the new value
        if var outcome = event.outcome {
            outcome.values.append(value)
            storeManager.store.updateAnyOutcome(outcome, callbackQueue: .main) { result in
                completion?(result.mapError { $0 as Error })
            }

        // Else Save a new outcome if one does not exist
        } else {
            do {
                let outcome = try makeOutcomeFor(event: event, withValues: [value])
                storeManager.store.addAnyOutcome(outcome, callbackQueue: .main) { result in
                    completion?(result.mapError { $0 as Error })
                }
            } catch {
                completion?(.failure(error))
            }
        }
    }

    /// Append an outcome value to an event's outcome.
    /// - Parameters:
    ///   - underlyingType: The value for the outcome value that is being created.
    ///   - indexPath: Index path of the event to which the outcome will be added.
    ///   - completion: Result after creating the outcome value.
    @available(*, deprecated, renamed: "appendOutcomeValue(value:at:completion:)")
    open func appendOutcomeValue(
        withType underlyingType: OCKOutcomeValueUnderlyingType,
        at indexPath: IndexPath,
        completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {

        appendOutcomeValue(
            value: underlyingType,
            at: indexPath,
            completion: completion)
    }

    /// Make an outcome for an event with the given outcome values.
    /// - Parameters:
    ///   - event: The event for which to create the outcome.
    ///   - values: The outcome values to attach to the outcome.
    open func makeOutcomeFor(event: OCKAnyEvent, withValues values: [OCKOutcomeValue]) throws -> OCKAnyOutcome {
        guard
            let task = event.task as? OCKAnyVersionableTask,
            let taskID = task.uuid else { throw OCKTaskControllerError.cannotMakeOutcomeFor(event) }
        return OCKOutcome(taskUUID: taskID, taskOccurrenceIndex: event.scheduleEvent.occurrence, values: values)
    }

    /// Return an event for a particular index path. Customize this method to define the index path behavior used by other functions in this class.
    /// - Parameter indexPath: The index path used to locate a particular event.
    open func eventFor(indexPath: IndexPath) -> OCKAnyEvent? {
        return taskEvents[indexPath.section][indexPath.row]
    }

    func validatedViewModel() throws -> OCKTaskEvents {
        guard !taskEvents.isEmpty else {
            throw OCKTaskControllerError.emptyTaskEvents
        }
        return taskEvents
    }

    func validatedEvent(forIndexPath indexPath: IndexPath) throws -> OCKAnyEvent {
        guard let event = eventFor(indexPath: indexPath) else {
            throw OCKTaskControllerError.invalidIndexPath(indexPath)
        }
        return event
    }

    private func deleteOutcomeValue(at index: Int, for outcome: OCKAnyOutcome, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        // delete the whole outcome if there is only one outcome value remaining
        guard outcome.values.count > 1 else {
            storeManager.store.deleteAnyOutcome(outcome, callbackQueue: .main) { result in
                completion?(result.mapError { $0 as Error })
            }
            return
        }

        // Else delete the value from the outcome
        var newOutcome = outcome
        newOutcome.values.remove(at: index)
        storeManager.store.updateAnyOutcome(newOutcome, callbackQueue: .main) { result in
            completion?(result.mapError { $0 as Error })
        }
    }

    #if os(iOS)

    /// Create a view with an option to delete an outcome value.
    /// - Parameters:
    ///   - index: The index of the outcome value to delete.
    ///   - eventIndexPath: The index path of the event for which the outcome value will be deleted.
    ///   - deletionCompletion: The result from attempting to delete the outcome value.
    open func initiateDeletionForOutcomeValue(atIndex index: Int, eventIndexPath: IndexPath,
                                              deletionCompletion: ((Result<OCKAnyOutcome, Error>) -> Void)?) throws -> UIAlertController {
        _ = try validatedViewModel()
        let event = try validatedEvent(forIndexPath: eventIndexPath)

        // Make sure there is an outcome value to delete
        guard
            let outcome = event.outcome,
            index < outcome.values.count else {
                throw OCKTaskControllerError.noOutcomeValueForEvent(event, index)
            }

        // Make an action sheet to delete the outcome value
        let actionSheet = UIAlertController(title: loc("LOG_ENTRY"), message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: loc("CANCEL"), style: .default, handler: nil)
        let delete = UIAlertAction(title: loc("DELETE"), style: .destructive) { [weak self] _ in
            self?.deleteOutcomeValue(at: index, for: outcome, completion: deletionCompletion)
        }
        [delete, cancel].forEach { actionSheet.addAction($0) }
        return actionSheet
    }

    /// Create a detail view that displays information about a task.
    /// - Parameter indexPath: Index path of the event whose task should be displayed.
    open func initiateDetailsViewController(forIndexPath indexPath: IndexPath) throws -> OCKDetailViewController {
        _ = try validatedViewModel()
        let task = try validatedEvent(forIndexPath: indexPath).task

        let detailViewController = OCKDetailViewController(showsCloseButton: true)
        detailViewController.detailView.titleLabel.text = task.title
        detailViewController.detailView.bodyLabel.text = task.instructions
        return detailViewController
    }

    #endif
}

private extension OCKSynchronizedStoreManager {

    func fetchAnyTasksPublisher(query: OCKAnyTaskQuery) -> AnyPublisher<[OCKAnyTask], OCKStoreError> {
        Future { [unowned self] completion in
            self.store.fetchAnyTasks(query: query, callbackQueue: .main, completion: completion)
        }
        .eraseToAnyPublisher()
    }

    func fetchAnyEventsPublisher(taskIDs: [String], query: OCKEventQuery,
                                 errorHandler: ((OCKStoreError) -> Void)?) -> AnyPublisher<[[OCKAnyEvent]], Never> {
        let publishers = taskIDs.map { id in
            fetchAnyEventsPublisher(taskID: id, query: query)
                // Catch the error to continue the stream when an error occurs. I.E when we fail to find events for one task, continue to look
                // for events for other tasks.
                // SomePublisher<[OCKAnyEvent], Never>
                .catch { error -> Empty<[OCKAnyEvent], Never> in
                    errorHandler?(error)
                    return .init()
                }
        }

        return Publishers.Sequence(sequence: publishers)
            .flatMap { $0 }
            // Publish all retrieved events at the same time.
            // SomePublisher<[[OCKAnyEvent]], Never>
            .collect()
            .eraseToAnyPublisher()
    }

    private func fetchAnyEventsPublisher(taskID: String, query: OCKEventQuery) -> AnyPublisher<[OCKAnyEvent], OCKStoreError> {
        Future { [unowned self] completion in
            self.store.fetchAnyEvents(taskID: taskID, query: query, callbackQueue: .main, completion: completion)
        }
        .eraseToAnyPublisher()
    }
}

private extension AnyCancellable {
    func store<Key: Hashable>(in dictionary: inout [Key: Set<AnyCancellable>], key: Key) {
        var values = dictionary[key] ?? []
        values.insert(self)
        dictionary[key] = values
    }
}

enum OCKTaskControllerError: Error, LocalizedError {

    case emptyTaskEvents
    case invalidIndexPath(_ indexPath: IndexPath)
    case noOutcomeValueForEvent(_ event: OCKAnyEvent, _ index: Int)
    case cannotMakeOutcomeFor(_ event: OCKAnyEvent)

    var errorDescription: String? {
        switch self {
        case .emptyTaskEvents: return "Task events is empty"
        case let .noOutcomeValueForEvent(event, index): return "Event has no outcome value at index \(index): \(event)"
        case .invalidIndexPath(let indexPath): return "Invalid index path \(indexPath)"
        case .cannotMakeOutcomeFor(let event): return "Cannot make outcome for event: \(event)"
        }
    }
}

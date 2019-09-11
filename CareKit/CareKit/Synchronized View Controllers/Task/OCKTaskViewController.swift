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

import CareKitUI
import Combine
import UIKit

/// An abstract superclass to all view controllers that are synchronized with a task and its events. Actions in the view sent through the
/// `OCKEventViewDelegate` protocol will be automatically hooked up to controller logic.
///
/// Alternatively, subclass and use your custom view by specializing the `View` generic and overriding the `makeView()` method. Override the
/// `updateView(view:context)` method to hook up the events to the view. This method will be called any time any of the events for the specified
/// task are added, updated, or deleted.
open class OCKTaskViewController<View: UIView & OCKTaskDisplayable, Store: OCKStoreProtocol>:
OCKSynchronizedViewController<View, [Store.Event]>, OCKTaskViewDelegate, OCKTaskDisplayer {
    // MARK: - Properties

    /// The task view displayed by this view controller.
    public var taskView: UIView & OCKTaskDisplayable { synchronizedView }

    /// The task currently being displayed. If the view controller is initialized with a task identifier, it will be nil until the task is
    /// fetched. If the initializer is called with a task, this value will never be nil.
    public private (set) var task: Store.Task?

    /// The store manager used to provide synchronization.
    public let storeManager: OCKSynchronizedStoreManager<Store>

    /// If set, the delegate will receive callbacks when important events occur.
    public weak var delegate: OCKTaskViewControllerDelegate?

    private let taskIdentifier: String
    private let eventQuery: OCKEventQuery

    // MARK: - Initializers

    /// Create an instance of the view controller that queries for the events for the specified task.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter task: The task that has events to display.
    /// - Parameter eventQuery: The query used to find events for the specified task.
    init(storeManager: OCKSynchronizedStoreManager<Store>, task: Store.Task, eventQuery: OCKEventQuery) {
        self.task = task
        self.storeManager = storeManager
        self.taskIdentifier = task.identifier
        self.eventQuery = eventQuery
        super.init()
    }

    /// Create an instance of the view controller by querying the task and events to display.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter taskIdentifier: The identifier of the task to find.
    /// - Parameter eventQuery: The query used to find events for the task.
    init(storeManager: OCKSynchronizedStoreManager<Store>, taskIdentifier: String, eventQuery: OCKEventQuery) {
        self.storeManager = storeManager
        self.taskIdentifier = taskIdentifier
        self.eventQuery = eventQuery
        super.init()
    }

    // MARK: Life cycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        taskView.delegate = self
        task == nil ? self.fetchTask(withIdentifier: taskIdentifier) : self.fetchEvents(for: task!)
    }

    // MARK: Methods

    /// Create a subscriptions that listens for update and delete notifications for the events associated with the task.
    override open func makeSubscription() -> AnyCancellable? {
        guard let task = task,
            let events = viewModel else { return nil }

        let eventsSubscriptions = events.enumerated().map { index, event -> Cancellable? in
            return storeManager.publisher(forEvent: event, categories: [.update, .delete]).sink { [weak self] updatedEvent in
                guard let self = self else { return }
                var newViewModel = self.viewModel
                newViewModel?[index] = updatedEvent
                self.setViewModel(newViewModel, animated: self.viewModel != nil)
            }
        }

        let taskSubscription = storeManager.publisher(forTask: task, categories: [.update, .delete]).sink { [weak self] newValue in
            guard let self = self else { return }
            self.task = newValue
            self.fetchEvents(for: newValue)
        }

        return AnyCancellable {
            eventsSubscriptions.forEach { $0?.cancel() }
            taskSubscription.cancel()
        }
    }

    /// Fetch a task with the specified identifer. Will fetch events for the task once the task is found.
    private func fetchTask(withIdentifier identifier: String) {
        storeManager.store.fetchTask(withIdentifier: identifier) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let task):
                self.task = task
                self.fetchEvents(for: task)
            case .failure(let error):
                self.delegate?.taskViewController(self, didFailWithError: error)
            }
        }
    }

    func presentDetailViewController() {
        guard let task = task else { return }
        let detailViewController = OCKDetailViewController()
        let convertedTask = task.convert()
        detailViewController.detailView.titleLabel.text = convertedTask.title
        detailViewController.detailView.instructionsLabel.text = convertedTask.instructions
        present(UINavigationController(rootViewController: detailViewController), animated: true, completion: nil)
    }

    /// Fetch events for `task` only if `task` is not nil.
    private func fetchEvents(for task: Store.Task) {
        storeManager.store.fetchEvents(taskIdentifier: task.identifier, query: eventQuery) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                switch error {
                case .fetchFailed:
                    self.setViewModel(nil, animated: self.viewModel != nil)
                default: break
                }
                self.delegate?.taskViewController(self, didFailWithError: error)

            case .success(let events):
                self.setViewModel(events, animated: self.viewModel != nil)
                self.subscribe()
                self.delegate?.taskViewController(self, didFinishQuerying: self.task, andEvents: events)
            }
        }
    }

    func saveNewOutcome(forEvent event: Store.Event) {
        guard let taskID = event.task.localDatabaseID else { fatalError("Task has not been persisted yet!") }
        guard event.outcome == nil else { return }   // only save one outcome

        let outcome = OCKOutcome(taskID: taskID, taskOccurenceIndex: event.convert().scheduleEvent.occurence, values: [OCKOutcomeValue(0)])
        let customOutcome = Store.Outcome(outcome)

        storeManager.store.addOutcome(customOutcome) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.taskViewController(self, didFailWithError: error)
                self.setViewModel(self.viewModel, animated: false)   // reset state
            case .success:
                break
            }
        }
    }

    func deleteOutcome(forEvent event: Store.Event) {
        if let outcome = event.outcome {
            storeManager.store.deleteOutcome(outcome) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    self.setViewModel(self.viewModel, animated: false)   // reset state
                    self.delegate?.taskViewController(self, didFailWithError: error)
                case .success:
                    break
                }
            }
        }
    }

    // MARK: - OCKTaskViewDelegate

    /// Present a details view controller for the view model.
    /// - Parameter eventView: The view displaying the task.
    open func didSelectTaskView(_ taskView: UIView & OCKTaskDisplayable) {
        presentDetailViewController()
    }

    /// Saves or deletes an outcome for an event depending on the `isComplete` flag.
    /// - Parameter eventView: The view displaying the task.
    /// - Parameter isComplete: True if the event was marked complete.
    /// - Parameter index: Index of the event in the list of displayed events for the task.
    /// - Parameter sender: The sender that triggered the completion of the event.
    open func taskView(_ taskView: UIView & OCKTaskDisplayable, didCompleteEvent isComplete: Bool, at index: Int, sender: Any?) {
        guard
            let viewModel = viewModel,
            index < viewModel.count
            else { return }

        let event = viewModel[index]
        isComplete ?
            saveNewOutcome(forEvent: event) :
            deleteOutcome(forEvent: event)
    }
}

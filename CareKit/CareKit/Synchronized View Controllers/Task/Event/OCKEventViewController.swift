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

/// An abstract superclass to all view controllers that are synchronized with an event and its outcomes. Actions in the view sent through the
/// `OCKEventViewDelegate` protocol will be automatically hooked up to controller logic.
///
/// Alternatively, subclass and use your custom view by specializing the `View` generic and overriding the `makeView()` method. Override the
/// `updateView(view:context)` method to hook up the event to the view. This method will be called any time the event is added, updated, or
/// deleted.
///
/// - Note: This view controller is created by specifying a task and an event query. If the event query
/// returns more than one event, only the first event will be displayed.
open class OCKEventViewController<View: UIView & OCKEventDisplayable, Store: OCKStoreProtocol>: OCKSynchronizedViewController<View, Store.Event>,
OCKEventViewControllerDelegate, OCKEventDisplayer, OCKEventViewDelegate {
    // MARK: Properties

    /// The view displayed by this view controller.
    public var eventView: UIView & OCKEventDisplayable { synchronizedView }

    /// The store manager used to provide synchronization.
    public let storeManager: OCKSynchronizedStoreManager<Store>

    /// If set, the delegate will receive callbacks when important events occur.
    public weak var delegate: OCKEventViewControllerDelegate?

    /// The event query used restrict which events are displayed for the task.
    private let eventQuery: OCKEventQuery

    private let taskIdentifier: String

    // MARK: - Life Cycle

    /// Create a view controller that queries for and displays an event for the specified task identifier.
    /// - Parameter storeManager: The store manager used to provide synchronization.
    /// - Parameter taskIdentifier: The identifier of the event's task.
    /// - Parameter eventQuery: The query used to find en event for the task.
    init(storeManager: OCKSynchronizedStoreManager<Store>, taskIdentifier: String, eventQuery: OCKEventQuery) {
        self.storeManager = storeManager
        self.taskIdentifier = taskIdentifier
        self.eventQuery = eventQuery
        super.init()
    }

    /// Create a view controller that displays an event for a specified task.
    /// - Parameter storeManager: The store manager used to provide synchronization.
    /// - Parameter task: The event's task.
    /// - Parameter eventQuery: The query used to find en event for the task.
    init(storeManager: OCKSynchronizedStoreManager<Store>, task: Store.Task, eventQuery: OCKEventQuery) {
        self.storeManager = storeManager
        self.taskIdentifier = task.identifier
        self.eventQuery = eventQuery
        super.init()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        eventView.delegate = self
        viewModel != nil ?
            subscribe() :
            fetchEvent(taskIdentifier: taskIdentifier, query: eventQuery)
    }

    // MARK: - Methods

    func presentDetailViewController() {
        guard let viewModel = viewModel else { return }
        let detailViewController = OCKDetailViewController()
        let convertedTask = viewModel.task.convert()
        detailViewController.detailView.titleLabel.text = convertedTask.title
        detailViewController.detailView.instructionsLabel.text = convertedTask.instructions
        present(UINavigationController(rootViewController: detailViewController), animated: true, completion: nil)
    }

    /// Create a subscription that listend for update events for the displayed event.
    override open func makeSubscription() -> AnyCancellable? {
        guard let event = viewModel else { return nil }
        let subscription = storeManager.publisher(forEvent: event, categories: [.update]).sink { [weak self] newValue in
            guard let self = self else { return }
            self.setViewModel(newValue, animated: self.viewModel != nil)
        }

        return AnyCancellable {
            subscription.cancel()
        }
    }

    private func fetchEvent(taskIdentifier: String, query: OCKEventQuery) {
        storeManager.store.fetchEvents(taskIdentifier: taskIdentifier, query: query) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let events):
                self.setViewModel(events.first, animated: self.viewModel != nil)
                self.subscribe()
                self.delegate?.eventViewController(self, didFinishQuerying: self.viewModel)
            case .failure(let error):
                self.delegate?.eventViewController(self, didFailWithError: error)
            }
        }
    }

    func saveValue(_ value: OCKOutcomeValueUnderlyingType, allowDuplicates: Bool = true) {
        let newOutcomeValue = OCKOutcomeValue(value)

        // save a new outcome if there is none
        guard let outcome = viewModel?.outcome else {
            saveNewOutcome(withOutcomeValues: [newOutcomeValue])
            return
        }

        // Check for duplicates if necessary
        var convertedOutcome = outcome.convert()
        if !allowDuplicates && convertedOutcome.values.filter({ $0.hasSameValueAs(newOutcomeValue) }).isEmpty { return }

        // Update the outcome with the new value
        convertedOutcome.values.append(OCKOutcomeValue(value))
        let updatedOutcome = Store.Outcome(convertedOutcome)
        updateOutcome(updatedOutcome)
    }

    func deleteOutcomeValue(_ outcomeValue: OCKOutcomeValue) {
        guard let outcome = viewModel?.outcome else { return }

        // delete the whole outcome if there is only one outcome value remaining
        var convertedOutcome = outcome.convert()
        guard convertedOutcome.values.count > 1 else {
            deleteOutcome(outcome)
            return
        }

        // Delete the value from the outcome
        convertedOutcome.values.removeAll { $0 == outcomeValue }
        let customOutcome = Store.Outcome(convertedOutcome)
        updateOutcome(customOutcome)
    }

    func updateOutcome(_ outcome: Store.Outcome) {
        storeManager.store.updateOutcomes([outcome], queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success: break
            case .failure(let error): self.delegate?.eventViewController(self, didFailWithError: error)
            }
        }
    }

    func saveNewOutcome(withOutcomeValues outcomeValues: [OCKOutcomeValue]) {
        guard let event = viewModel else { return }
        guard let taskID = event.task.localDatabaseID else { fatalError("Task has not been persisted yet!") }
        let outcome = OCKOutcome(taskID: taskID, taskOccurenceIndex: event.scheduleEvent.occurence, values: outcomeValues)
        let customOutcome = Store.Outcome(outcome)

        storeManager.store.addOutcomes([customOutcome], queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.setViewModel(self.viewModel, animated: false)   // reset state
                self.delegate?.eventViewController(self, didFailWithError: error)
            case .success: break
            }
        }
    }

    func deleteOutcome(_ outcome: Store.Outcome) {
        storeManager.store.deleteOutcomes([outcome], queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.setViewModel(self.viewModel, animated: false)   // reset state
                self.delegate?.eventViewController(self, didFailWithError: error)
            case .success: break
            }
        }
    }

    // MARK: - OCKEventViewDelegate

    /// Present the details view controller for the view model.
    /// - Parameter eventView: The view displaying the event.
    open func didSelectEventView(_ eventView: UIView & OCKEventDisplayable) {
        presentDetailViewController()
    }

    /// Save an outcome value of `true` to the view model.
    /// - Parameter eventView: The view displaying the outcome.
    /// - Parameter index: The index of the sender in the `logButtonsCollectionView`.
    /// - Parameter sender: The sender that created the outcome value.
    open func eventView(_ eventView: UIView & OCKEventDisplayable, didCreateOutcomeValueAt index: Int, sender: Any?) {
        saveValue(true)
    }

    /// Called when an outcome value for an event's outcome was selected.
    /// - Parameter eventView: The view displaying the outcome.
    /// - Parameter index: The index of the outcome value.
    /// - Parameter sender: The sender that triggered the selection.
    open func eventView(_ eventView: UIView & OCKEventDisplayable, didSelectOutcomeValueAt index: Int, sender: Any?) {
        // Make sure there is an outcome value to delete
        guard
            let values = viewModel?.outcome?.convert().values,
            index < values.count
            else { return }

        // Present an action sheet to delete the outcome value
        let actionSheet = UIAlertController(title: OCKStrings.logEntry, message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: OCKStrings.cancel, style: .default, handler: nil)
        let delete = UIAlertAction(title: OCKStrings.delete, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.deleteOutcomeValue(values[index])
        }
        [delete, cancel].forEach { actionSheet.addAction($0) }
        present(actionSheet, animated: true, completion: nil)
    }

    /// Saves or deletes the view model's outcome depending on the `isComplete` flag.
    /// - Parameter eventView: The view displaying the event.
    /// - Parameter isComplete: True if the event is complete.
    /// - Parameter sender: The sender that triggered the completion of the event.
    open func eventView(_ eventView: UIView & OCKEventDisplayable, didCompleteEvent isComplete: Bool, sender: Any?) {
        guard let event = viewModel else { return }

        if isComplete {
            saveNewOutcome(withOutcomeValues: [OCKOutcomeValue(true)])
        } else {
            guard let outcome = event.outcome else { return }
            deleteOutcome(outcome)
        }
    }
}

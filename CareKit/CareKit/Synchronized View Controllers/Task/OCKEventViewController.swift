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

import UIKit
import Combine
import CareKitStore
import CareKitUI

/// Conform to this protocol to receive callbacks when important events happen inside an `OCKEventViewController`.
public protocol OCKEventViewControllerDelegate: class {
    
    /// Called when an event view controller is selected by the user.
    /// - Parameter eventViewController: The event view controller that was tapped.
    func didSelect<Store: OCKStoreProtocol>(eventViewController: OCKEventViewController<Store>)
    
    /// Called each time an event view controller finishes querying an event.
    /// - Parameter eventViewController: The view controller which performed the query.
    /// - Parameter event: The event that was queried.
    func eventViewController<Store: OCKStoreProtocol>(_ eventViewController: OCKEventViewController<Store>,
                                                      didFinishQuerying event: Store.Event?)
    
    /// Called if an unhandled error is encountered in an event view controller.
    /// - Parameter eventViewController: The event view controller in which the error occurred.
    /// - Parameter error: The error that occurred.
    func eventViewController<Store: OCKStoreProtocol>(_ eventViewController: OCKEventViewController<Store>,
                                                      didFailWithError error: Error)
}

public extension OCKEventViewControllerDelegate {
    func didSelect<Store: OCKStoreProtocol>(eventViewController: OCKEventViewController<Store>) {}
    
    func eventViewController<Store: OCKStoreProtocol>(_ eventViewController: OCKEventViewController<Store>,
                                                      didFinishQuerying event: Store.Event?) {}
    
    func eventViewController<Store: OCKStoreProtocol>(_ eventViewController: OCKEventViewController<Store>,
                                                      didFailWithError error: Error) {}
}

public extension OCKEventViewControllerDelegate where Self: UIViewController {
    func didSelect<Store: OCKStoreProtocol>(eventViewController: OCKEventViewController<Store>) {
        let detailViewController = OCKDetailViewController()
        let task = eventViewController.event?.task.convert()
        detailViewController.detailView.titleLabel.text = task?.title
        detailViewController.detailView.instructionsLabel.text = task?.instructions
        present(UINavigationController(rootViewController: detailViewController), animated: true, completion: nil)
    }
}

/// An abstract superclass to all synchronized view controllers that display an event and its outcomes.
/// It has a factory function that can be used to conveniently initialize a concreted subclass.
///
/// - Note: `OCKEventViewController`s are created by specifying a task and an event query. If the event query
/// returns more than one event, only the first event will be displayed.
open class OCKEventViewController<Store: OCKStoreProtocol>: OCKSynchronizedViewController<Store.Event>, OCKEventViewControllerDelegate {
    
    // MARK: Properties
    
    /// Specifies all the ways in which an event can be displayed.
    public enum Style: String, CaseIterable {
        /// A text label with a single large button to mark the event complete.
        case simple
        
        /// A more detailed view including an instructions label.
        case instructions
        
        /// A view that allows the patient to log multiple outcomes.
        case simpleLog
    }
    
    internal var shouldCollapse: Bool { false }
    
    public let storeManager: OCKSynchronizedStoreManager<Store>
    
    private let taskIdentifier: String?
    
    /// The event query used restrict which events are displayed for the task.
    public let eventQuery: OCKEventQuery?
    
    /// The event that is currently being displayed. It will be nil until the query to the store returns.
    public private(set) var event: Store.Event?
    
    /// If set, the delegate will receive callbacks when important events occur.
    public weak var delegate: OCKEventViewControllerDelegate?
    
    internal var detailPresentingView: UIView? { return nil }
    
    // Styled initializers

    /// A factory function that constructs the proper subclass of `OCKEventViewController` given a style parameter and
    /// returns it upcast to `OCKEventViewController`.
    ///
    /// - Parameters:
    ///   - style: A style that determines which subclass will be instantiated.
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - taskIdentifier: The identifier event's task.
    ///   - eventQuery: An event query that specifies which events will be queried and displayed.
    public static func makeViewController(style: Style, storeManager: OCKSynchronizedStoreManager<Store>,
                                          taskIdentifier: String, eventQuery: OCKEventQuery) -> OCKEventViewController<Store> {
        switch style {
        case .simple:
            return OCKSimpleTaskViewController<Store>(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery)
        case .instructions:
            return OCKInstructionsTaskViewController<Store>(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery)
        case .simpleLog:
            return OCKSimpleLogTaskViewController<Store>(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery)
        }
    }
    
    /// A factory function that constructs the proper subclass of `OCKEventViewController` given a style parameter and
    /// returns it upcast to `OCKEventViewController`.
    ///
    /// - Parameters:
    ///   - style: A style that determines which subclass will be instantiated.
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - task: The task to which the event to be displayed belongs.
    ///   - eventQuery: An event query that specifies which events will be queried and displayed.
    public static func makeViewController(style: Style, storeManager: OCKSynchronizedStoreManager<Store>, task: Store.Task,
                                          eventQuery: OCKEventQuery) -> OCKEventViewController {
        return makeViewController(style: style, storeManager: storeManager, taskIdentifier: task.identifier, eventQuery: eventQuery)
    }
    
    // MARK: Initializers
    
    internal init(
        storeManager: OCKSynchronizedStoreManager<Store>,
        taskIdentifier: String,
        eventQuery: OCKEventQuery,
        loadCustomView: @escaping () -> UIView,
        modelDidChange: @escaping CustomModelDidChange) {

        self.storeManager = storeManager
        self.taskIdentifier = taskIdentifier
        self.eventQuery = eventQuery
        super.init(loadCustomView: loadCustomView, modelDidChange: modelDidChange)
    }
        
    internal init<View: UIView & OCKBindable>(
        storeManager: OCKSynchronizedStoreManager<Store>,
        taskIdentifier: String,
        eventQuery: OCKEventQuery,
        loadDefaultView: @escaping () -> View,
        modelDidChange: ModelDidChange? = nil)
    where View.Model == Store.Event {

        self.storeManager = storeManager
        self.taskIdentifier = taskIdentifier
        self.eventQuery = eventQuery
        super.init(loadDefaultView: loadDefaultView, modelDidChange: modelDidChange)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        if let detailPresentingView = detailPresentingView {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(presentDetailViewController))
            detailPresentingView.isUserInteractionEnabled = true
            detailPresentingView.addGestureRecognizer(tapGesture)
        }
        
        event == nil ? fetchEvent() : modelUpdated(viewModel: event, animated: false)
    }
    
    // MARK: Methods
    
    @objc
    private func presentDetailViewController() {
        delegate?.didSelect(eventViewController: self)
    }
    
    override func subscribe() {
        super.subscribe()
        guard let event = event else { return }
        subscription = storeManager.publisher(forEvent: event, categories: [.add, .update, .delete]).sink { [weak self] newValue in
            guard let self = self else { return }
            let shouldAnimate = self.event != nil
            self.event = newValue
            self.modelUpdated(viewModel: self.event, animated: shouldAnimate)
        }
    }
    
    private func fetchEvent() {
        guard let taskIdentifier = taskIdentifier, let eventQuery = eventQuery else { return }
        storeManager.store.fetchEvents(taskIdentifier: taskIdentifier, query: eventQuery) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let events):
                let shouldAnimate = self.event != nil
                self.event = events.first
                self.modelUpdated(viewModel: self.event, animated: shouldAnimate)
                self.subscribe()
                self.delegate?.eventViewController(self, didFinishQuerying: self.event)
            case .failure(let error):
                self.delegate?.eventViewController(self, didFailWithError: error)
            }
        }
    }
    
    /// Save an outcome value with an integer value. If the value is nil, the function will find the missing value in the sorted
    /// sequence of current values
    internal func saveNewOutcomeValue(_ value: Int? = nil, allowDuplicates: Bool = false) {
        // save the outcome if there is none
        guard let outcome = event?.outcome else {
            saveNewOutcome(withValues: [OCKOutcomeValue(value ?? 0)])
            return
        }
        
        // save a new outcome value if there is already an outcome
        var newValue: Int? = value
        var convertedOutcome = outcome.convert()
        guard
            (value == nil) ||
                (!allowDuplicates && convertedOutcome.values.filter({ $0.integerValue == value }).isEmpty) else { return }    // no duplicates
        var newValues = convertedOutcome.values
        
        // Find the missing value in the sequence of integer values
        if newValue == nil {
            let values = newValues.compactMap { $0.integerValue }
            newValue = firstMissingNumberIn(values: values)
        }
        newValues.append(OCKOutcomeValue(newValue!))
        
        convertedOutcome.values = newValues
        let updatedOutcome = Store.Outcome(value: convertedOutcome)
        
        storeManager.store.updateOutcomes([updatedOutcome], queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success: break
            case .failure(let error):
                self.delegate?.eventViewController(self, didFailWithError: error)
            }
        }
    }
    
    /// find the first missing number in a sorted sequence of integers
    private func firstMissingNumberIn(values: [Int]) -> Int {
        let sortedValues = values.sorted()
        var counter = 0
        for val in sortedValues {
            if val != counter { return counter }
            counter += 1
        }
        return counter
    }
    
    internal func deleteOutcomeValue(_ value: Int?) {
        guard let outcome = event?.outcome else { return }
        // delete the whole outcome if there is only one value remaining
        guard outcome.convert().values.count > 1 else {
            storeManager.store.deleteOutcomes([outcome], queue: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success: break
                case .failure(let error):
                    self.delegate?.eventViewController(self, didFailWithError: error)
                }
            }
            return
        }
        
        // Update outcome
        var convertedOutcome = outcome.convert()
        var newValues = convertedOutcome.values
        guard let indexToDelete = newValues.firstIndex(where: { $0.integerValue == value }) else { return }
        newValues.remove(at: indexToDelete)
        convertedOutcome.values = newValues
        let updatedOutcome = Store.Outcome(value: convertedOutcome)
        storeManager.store.updateOutcomes([updatedOutcome], queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success: break
            case .failure(let error):
                self.delegate?.eventViewController(self, didFailWithError: error)
            }
        }
    }
    
    private func saveNewOutcome(withValues values: [OCKOutcomeValue]) {
        guard let event = event else { return }
        guard let taskID = event.task.versionID else { fatalError("Task has not been persisted yet!") }
        
        let outcome = OCKOutcome(taskID: taskID, taskOccurenceIndex: event.scheduleEvent.occurence, values: values)
        let customOutcome = Store.Outcome(value: outcome)
        
        storeManager.store.addOutcomes([customOutcome], queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.modelUpdated(viewModel: self.event, animated: true)
                self.delegate?.eventViewController(self, didFailWithError: error)
            case .success:
                break
            }
        }
    }
    
    private func deleteOutcome() {
        guard let outcome = event?.outcome else { return }
        storeManager.store.deleteOutcomes([outcome], queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.modelUpdated(viewModel: self.event, animated: true)
                self.delegate?.eventViewController(self, didFailWithError: error)
            case .success:
                break
            }
        }
    }
    
    @objc
    internal func eventButtonPressed(_ sender: UIControl) {
        guard let event = event else { return }
        event.outcome == nil ? saveNewOutcome(withValues: [OCKOutcomeValue(0)]) : deleteOutcome()
    }
    
    @objc
    internal func outcomeButtonPressed(_ sender: UIControl) {
        saveNewOutcomeValue()
    }
}

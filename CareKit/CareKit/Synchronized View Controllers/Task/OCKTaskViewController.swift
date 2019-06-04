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

/// Conform to this protocol to receive callbacks when important events happen inside an `OCKTaskViewController`.
public protocol OCKTaskViewControllerDelegate: class {
    
    /// Called when a task view controller is selected by the user.
    /// - Parameter taskViewController: The task view controller that was selected.
    func didSelect<Store: OCKStoreProtocol>(taskViewController: OCKTaskViewController<Store>)
    
    /// Called when a task view controller finishes querying a task and its events.
    /// - Parameter taskViewController: The task view controller which performed the query.
    /// - Parameter task: The task that was queried.
    /// - Parameter events: The events that were queried.
    func taskViewController<Store: OCKStoreProtocol>(_ taskViewController: OCKTaskViewController<Store>,
                                                     didFinishQuerying task: Store.Task?,
                                                     andEvents events: [Store.Event])
    
    /// Called when an unhandled error is encountered in a task view controller.
    /// - Parameter taskViewController: The task view controller in which the error occurred.
    /// - Parameter error: The error that occurred.
    func taskViewController<Store: OCKStoreProtocol>(_ taskViewController: OCKTaskViewController<Store>,
                                                     didFailWithError error: Error)
}

public extension OCKTaskViewControllerDelegate {
    func didSelect<Store: OCKStoreProtocol>(taskViewController: OCKTaskViewController<Store>) {}
    
    func taskViewController<Store: OCKStoreProtocol>(_ taskViewController: OCKTaskViewController<Store>,
                                                     didFinishQuerying task: Store.Task?,
                                                     andEvents events: [Store.Event]) {}
    
    func taskViewController<Store: OCKStoreProtocol>(_ taskViewController: OCKTaskViewController<Store>,
                                                     didFailWithError error: Error) {}
}

public extension OCKTaskViewControllerDelegate where Self: UIViewController {
    func didSelect<Store: OCKStoreProtocol>(taskViewController: OCKTaskViewController<Store>) {
        let detailViewController = OCKDetailViewController()
        let task = taskViewController.task?.convert()
        detailViewController.detailView.titleLabel.text = task?.title
        detailViewController.detailView.instructionsLabel.text = task?.instructions
        present(UINavigationController(rootViewController: detailViewController), animated: true, completion: nil)
    }
}

/// An abstract superclass to all synchronized view controllers that display a task and its events.
/// It has a factory function that can be used to conveniently initialize a concreted subclass.
open class OCKTaskViewController<Store: OCKStoreProtocol>: OCKSynchronizedViewController<[Store.Event]>, OCKTaskViewControllerDelegate {
    
    // MARK: Properties
    
    /// Specifies all the ways in which a task can be displayed.
    public enum Style: String, CaseIterable {
        /// A vertically arranged checklist of events.
        case checklist
        
        /// A grid of events that adapts the number of rows and columns to fit its view.
        case grid
    }
    
    /// The task currently being displayed. If the view controller is initialized with a task identifier, it will be nil until the task is fetched.
    /// If the initializer is called with a task, this value will never be nil.
    public private (set) var task: Store.Task?
    
    /// An array of the events currently being displayed.
    public private (set) var events: [Store.Event] = []
    
    /// The store manager used to provide synchronization.
    public let storeManager: OCKSynchronizedStoreManager<Store>
    private let taskIdentifier: String
    public let eventQuery: OCKEventQuery
    
    /// If set, the delegate will receive callbacks when important events occur.
    public weak var delegate: OCKTaskViewControllerDelegate?
    
    internal var detailPresentingView: UIView? { return nil }

    // MARK: Factory Functions
    
    /// A factory function that constructs the proper subclass of `OCKTaskViewController` given a style parameter and returns
    /// it upcast to `OCKTaskViewController`.
    ///
    /// - Parameters:
    ///   - style: A style that determines which subclass will be instantiated.
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - task: The task to be displayed.
    ///   - eventQuery: An event query that specifies which events will be queried and displayed.
    public static func makeViewController(style: Style, storeManager: OCKSynchronizedStoreManager<Store>,
                                          task: Store.Task, eventQuery: OCKEventQuery) -> OCKTaskViewController<Store> {
        switch style {
        case .checklist: return OCKChecklistTaskViewController(storeManager: storeManager, task: task, eventQuery: eventQuery)
        case .grid: return OCKGridTaskViewController(storeManager: storeManager, task: task, eventQuery: eventQuery)
        }
    }

    /// A factory function that constructs the proper subclass of `OCKTaskViewController` given a style parameter and returns
    /// it upcast to `OCKTaskViewController`.
    ///
    /// - Parameters:
    ///   - style: A style that determines which subclass will be instantiated.
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - taskIdentifier: The identifier of the task to be displayed.
    ///   - eventQuery: An event query that specifies which events will be queried and displayed.
    public static func makeViewController(style: Style, storeManager: OCKSynchronizedStoreManager<Store>,
                                          taskIdentifier: String, eventQuery: OCKEventQuery) -> OCKTaskViewController<Store> {
        switch style {
        case .checklist:
            return OCKChecklistTaskViewController<Store>(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery)
        case .grid:
            return OCKGridTaskViewController<Store>(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery)
        }
    }
    
    // MARK: Initializers
    
    internal init(
        storeManager: OCKSynchronizedStoreManager<Store>,
        task: Store.Task,
        eventQuery: OCKEventQuery,
        loadCustomView: @escaping () -> UIView,
        modelDidChange: @escaping CustomModelDidChange) {
        
        self.task = task
        self.storeManager = storeManager
        self.taskIdentifier = task.identifier
        self.eventQuery = eventQuery
        super.init(loadCustomView: loadCustomView, modelDidChange: modelDidChange)
    }
    
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
        task: Store.Task,
        eventQuery: OCKEventQuery,
        loadDefaultView: @escaping () -> View,
        modelDidChange: ModelDidChange? = nil)
    where View.Model == [Store.Event] {
        self.task = task
        self.storeManager = storeManager
        self.taskIdentifier = task.identifier
        self.eventQuery = eventQuery
        super.init(loadDefaultView: loadDefaultView, modelDidChange: modelDidChange)
    }
    
    internal init<View: UIView & OCKBindable>(
        storeManager: OCKSynchronizedStoreManager<Store>,
        taskIdentifier: String,
        eventQuery: OCKEventQuery,
        loadDefaultView: @escaping () -> View,
        modelDidChange: ModelDidChange? = nil)
    where View.Model == [Store.Event] {
            
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
        
        task == nil ? self.fetchTask() : self.fetchEvents()
    }
    
    // MARK: Methods
    
    override internal func subscribe() {
        super.subscribe()
        let subscriptions = events.enumerated().map { (index, event) -> Cancellable? in
            return storeManager.publisher(forEvent: event, categories: [.add, .update, .delete]).sink { [weak self] updatedEvent in
                guard let self = self else { return }
                let shouldAnimate = !self.events.isEmpty
                self.events[index] = updatedEvent
                self.modelUpdated(viewModel: self.events, animated: shouldAnimate)
            }
        }
 
        subscription = AnyCancellable {
            subscriptions.forEach { $0?.cancel() }
        }
    }
 
    private func fetchTask() {
        guard task == nil else { return }
        storeManager.store.fetchTask(withIdentifier: taskIdentifier) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let task):
                self.task = task
                self.fetchEvents()
            case .failure(let error):
                self.delegate?.taskViewController(self, didFailWithError: error)
            }
        }
    }
    
    @objc
    private func presentDetailViewController() {
        delegate?.didSelect(taskViewController: self)
    }

    private func fetchEvents() {
        guard let task = task else { return }
        storeManager.store.fetchEvents(taskIdentifier: task.identifier, query: eventQuery) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.taskViewController(self, didFailWithError: error)
            case .success(let events):
                let shouldAnimate = !self.events.isEmpty
                self.events = events
                self.modelUpdated(viewModel: events, animated: shouldAnimate)
                self.subscribe()
                self.delegate?.taskViewController(self, didFinishQuerying: self.task, andEvents: events)
            }
        }
    }
    
    internal func saveNewOutcome(forEvent event: Store.Event) {
        guard let taskID = event.task.versionID else { fatalError("Task has not been persisted yet!") }
        guard event.outcome == nil else { return }   // only save one outcome
        
        let outcome = OCKOutcome(taskID: taskID, taskOccurenceIndex: event.convert().scheduleEvent.occurence, values: [OCKOutcomeValue(0)])
        let customOutcome = Store.Outcome(value: outcome)
        
        storeManager.store.addOutcome(customOutcome) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.taskViewController(self, didFailWithError: error)
                self.modelUpdated(viewModel: self.events, animated: true)   // reset state
            case .success:
                break
            }
        }
    }
    
    internal func deleteOutcome(forEvent event: Store.Event) {
        if let outcome = event.outcome {
            storeManager.store.deleteOutcome(outcome) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    self.delegate?.taskViewController(self, didFailWithError: error)
                    self.modelUpdated(viewModel: self.events, animated: true)    // reset state
                case .success:
                    break
                }
            }
        }
    }
}

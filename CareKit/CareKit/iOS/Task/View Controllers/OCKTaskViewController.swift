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
#if !os(watchOS)

import CareKitStore
import CareKitUI
import Combine
import UIKit

/// Types wishing to receive updates from task view controllers can conform to this protocol.
public protocol OCKTaskViewControllerDelegate: AnyObject {

    /// Called when an unhandled error is encountered in a task view controller.
    /// - Parameters:
    ///   - viewController: The view controller in which the error was encountered.
    ///   - error: The error that was unhandled.
    func taskViewController<C: OCKTaskController, VS: OCKTaskViewSynchronizerProtocol>(
        _ viewController: OCKTaskViewController<C, VS>, didEncounterError error: Error)
}

/// A view controller that displays a task view and keep it synchronized with a store.
open class OCKTaskViewController<Controller: OCKTaskController, ViewSynchronizer: OCKTaskViewSynchronizerProtocol>:
UIViewController, OCKTaskViewDelegate {

    // MARK: Properties

    /// If set, the delegate will receive updates when import events happen
    public weak var delegate: OCKTaskViewControllerDelegate?

    /// Handles the responsibility of updating the view when data in the store changes.
    public let viewSynchronizer: ViewSynchronizer

    /// Handles the responsibility of interacting with data from the store.
    public let controller: Controller

    /// The view that is being synchronized against the store.
    public var taskView: ViewSynchronizer.View {
        guard let view = self.view as? ViewSynchronizer.View else { fatalError("View should be of type \(ViewSynchronizer.View.self)") }
        return view
    }

    private var cancellables: Set<AnyCancellable> = []
    private let query: OCKSynchronizedTaskQuery?

    // MARK: - Life Cycle

    /// Initialize with a controller and synchronizer.
    public init(controller: Controller, viewSynchronizer: ViewSynchronizer) {
        self.controller = controller
        self.viewSynchronizer = viewSynchronizer
        self.query = nil
        super.init(nibName: nil, bundle: nil)
    }

    /// Initialize a view controller that displays a task. Fetches and stays synchronized with events for the task.
    /// - Parameter viewSynchronizer: Manages the task view.
    /// - Parameter task: The task to display.
    /// - Parameter eventQuery: Used to fetch events for the task.
    /// - Parameter storeManager: Wraps the store that contains the events to fetch.
    public init(viewSynchronizer: ViewSynchronizer, task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        self.controller = Controller(storeManager: storeManager)
        self.viewSynchronizer = viewSynchronizer
        self.query = .tasks([task], eventQuery)
        super.init(nibName: nil, bundle: nil)
    }

    /// Initialize a view controller that displays tasks. Fetches and stays synchronized with events for the tasks.
    /// - Parameter viewSynchronizer: Manages the task view.
    /// - Parameter taskIDs: User defined ids for the tasks to fetch.
    /// - Parameter eventQuery: Used to fetch events for the tasks.
    /// - Parameter storeManager: Wraps the store that contains the tasks and events to fetch.
    public init(viewSynchronizer: ViewSynchronizer, taskIDs: [String], eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        self.controller = Controller(storeManager: storeManager)
        self.viewSynchronizer = viewSynchronizer
        self.query = .taskIDs(taskIDs, eventQuery)
        super.init(nibName: nil, bundle: nil)
    }

    /// Initialize a view controller that displays task. Fetches and stays synchronized with events for the task.
    /// - Parameter viewSynchronizer: Manages the task view.
    /// - Parameter taskID: User defined id of the task to fetch.
    /// - Parameter eventQuery: Used to fetch events for the task.
    /// - Parameter storeManager: Wraps the store that contains the task and events to fetch.
    public init(viewSynchronizer: ViewSynchronizer, taskID: String, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        self.controller = Controller(storeManager: storeManager)
        self.viewSynchronizer = viewSynchronizer
        self.query = .taskIDs([taskID], eventQuery)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    override open func loadView() {
        view = viewSynchronizer.makeView()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        taskView.delegate = self

        // Begin listening for changes in the view model. Note, when we subscribe to the view model, it sends its current value through the stream
        startObservingViewModel()

        // Listen for any errors encountered by the controller.
        controller.$error
            .compactMap { $0 }
            .sink { [unowned self] error in
                if self.delegate == nil {
                    log(.error, "A task error occurred, but no delegate was set to forward it to!", error: error)
                }
                self.delegate?.taskViewController(self, didEncounterError: error)
            }
            .store(in: &self.cancellables)

        // Fetch and observe data if needed.
        query?.perform(using: controller)
    }

    // MARK: - Methods

    // Create a subscription that updates the view when the view model is updated.
    private func startObservingViewModel() {
        controller.$taskEvents
            .context(currentValue: controller.taskEvents, animateIf: { oldValue, _ in !oldValue.isEmpty })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                guard let self = self else { return }
                self.viewSynchronizer.updateView(self.taskView, context: context)
            }
            .store(in: &cancellables)
    }

    // Reset view state on a failure
    // Note: This is needed because the UI assumes user interactions (lke button taps) will be successful, and displays the corresponding
    // state immediately. When the interaction is actually unsuccessful, we need to reset the UI.
    func resetViewState() {
        controller.taskEvents = controller.taskEvents // triggers an update to the view
    }

    func notifyDelegateAndResetViewOnError<Success, Error>(result: Result<Success, Error>) {
        if case let .failure(error) = result {
            if delegate == nil {
                log(.error, "A task error occurred, but no delegate was set to forward it to!", error: error)
            }
            delegate?.taskViewController(self, didEncounterError: error)
            resetViewState()
        }
    }

    // MARK: - OCKTaskViewDelegate

    open func taskView(_ taskView: UIView & OCKTaskDisplayable, didCompleteEvent isComplete: Bool, at indexPath: IndexPath, sender: Any?) {
        controller.setEvent(atIndexPath: indexPath, isComplete: isComplete, completion: notifyDelegateAndResetViewOnError)
    }

    open func taskView(_ taskView: UIView & OCKTaskDisplayable, didSelectOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?) {
        do {
            let alert = try controller.initiateDeletionForOutcomeValue(atIndex: index, eventIndexPath: eventIndexPath,
                                                                       deletionCompletion: notifyDelegateAndResetViewOnError)
            if let anchor = sender as? UIView {
                alert.popoverPresentationController?.sourceRect = anchor.bounds
                alert.popoverPresentationController?.sourceView = anchor
                alert.popoverPresentationController?.permittedArrowDirections = .any
            }
            present(alert, animated: true, completion: nil)
        } catch {
            if delegate == nil {
                log(.error, "A task error occurred, but no delegate was set to forward it to!", error: error)
            }
            delegate?.taskViewController(self, didEncounterError: error)
        }
    }

    open func taskView(_ taskView: UIView & OCKTaskDisplayable, didCreateOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?) {
        controller.appendOutcomeValue(value: true, at: eventIndexPath, completion: notifyDelegateAndResetViewOnError)
    }

    open func didSelectTaskView(_ taskView: UIView & OCKTaskDisplayable, eventIndexPath: IndexPath) {
        do {
            let detailsViewController = try controller.initiateDetailsViewController(forIndexPath: eventIndexPath)
            present(detailsViewController, animated: true)
        } catch {
            if delegate == nil {
                log(.error, "A task error occurred, but no delegate was set to forward it to!", error: error)
            }
            delegate?.taskViewController(self, didEncounterError: error)
        }
    }
}

#endif

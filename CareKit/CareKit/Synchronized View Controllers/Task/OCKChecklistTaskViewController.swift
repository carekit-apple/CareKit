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
import UIKit

/// A view controller showing an `OCKChecklistTaskView` that is synchronized with a single task and its events. Displays events for the task, and
/// allows the user to mark them as complete.
open class OCKChecklistTaskViewController<Store: OCKStoreProtocol>: OCKTaskViewController<OCKChecklistTaskView, Store> {
    // MARK: Properties

    /// The type of the view being displayed.
    public typealias View = OCKChecklistTaskView

    // MARK: - Life Cycle

    /// Create an instance of the view controller that queries for the events for the specified task.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter task: The task that has events to display.
    /// - Parameter eventQuery: The query used to find events for the specified task.
    override public init(storeManager: OCKSynchronizedStoreManager<Store>, task: Store.Task, eventQuery: OCKEventQuery) {
        super.init(storeManager: storeManager, task: task, eventQuery: eventQuery)
    }

    /// Create an instance of the view controller by querying the task and events to display.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter taskIdentifier: The identifier of the task to find.
    /// - Parameter eventQuery: The query used to find events for the task.
    override public init(storeManager: OCKSynchronizedStoreManager<Store>, taskIdentifier: String, eventQuery: OCKEventQuery) {
        super.init(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery)
    }

    // MARK: - Methods

    /// Create an instance of the view to be displayed.
    override open func makeView() -> OCKChecklistTaskView {
        return .init()
    }

    /// Update the view whenever the view model changes.
    /// - Parameter view: The view to update.
    /// - Parameter context: The data associated with the updated state.
    override open func updateView(_ view: OCKChecklistTaskView, context: OCKSynchronizationContext<[Store.Event]>) {
        let task = context.viewModel?.first?.task.convert()
        let events = context.viewModel
        setupViewWithTask(task, view: view)
        setupViewWithEvents(events, view: view, animated: context.animated)
    }

    private func setupViewWithNilTask(_ view: OCKChecklistTaskView) {
        view.headerView.titleLabel.text = nil
        view.headerView.detailLabel.text = nil
        view.instructionsLabel.text = nil
    }

    private func setupViewWithEmptyEvents(_ view: OCKChecklistTaskView, animated: Bool) {
        view.clearItems(animated: animated)
        view.headerView.detailLabel.text = nil
    }

    private func setupViewWithTask(_ task: OCKTask?, view: OCKChecklistTaskView) {
        guard let task = task else {
            setupViewWithNilTask(view)
            return
        }
        view.headerView.titleLabel.text = task.title
        view.instructionsLabel.text = task.instructions
    }

    private func setupViewWithEvents(_ events: [Store.Event]?, view: OCKChecklistTaskView, animated: Bool) {
        guard let events = events, !events.isEmpty else {
            setupViewWithEmptyEvents(view, animated: animated)
            return
        }

        for (index, event) in events.enumerated() {
            let title = event.scheduleEvent.element.text ?? OCKScheduleUtility.timeLabel(for: event)
            if index < view.items.count {
                let item = view.updateItem(at: index, withTitle: title)
                item?.isSelected = event.outcome != nil
            } else {
                let item = view.appendItem(withTitle: title, animated: animated)
                item.isSelected = event.outcome != nil
            }
        }
        trimItems(in: view, events: events, animated: animated)
        view.headerView.detailLabel.text = OCKScheduleUtility.scheduleLabel(for: events)
    }

    // Remove any items that aren't needed
    private func trimItems(in view: OCKChecklistTaskView, events: [Store.Event], animated: Bool) {
        let countToRemove = view.items.count - events.count
        for _ in 0..<countToRemove {
            view.removeItem(at: view.items.count - 1, animated: animated)
        }
    }
}

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

/// A view controller showing an `OCKButtonLogTaskView` that is synchronized with a single event and its outcomes. Allows the user to log
/// outcomes for the event.
///
/// - Note: This view controller is created by specifying a task and an event query. If the event query returns more than one event, only
/// the first event will be displayed.
open class OCKButtonLogTaskViewController<Store: OCKStoreProtocol>: OCKEventViewController<OCKButtonLogTaskView, Store> {
    // MARK: Properties

    /// The type of view being displayed.
    public typealias View = OCKButtonLogTaskView

    // MARK: - Life Cycle

    /// Create a view controller that queries for and displays an event for the specified task identifier.
    /// - Parameter storeManager: The store manager used to provide synchronization.
    /// - Parameter taskIdentifier: The identifier of the event's task.
    /// - Parameter eventQuery: The query used to find en event for the task.
    override public init(storeManager: OCKSynchronizedStoreManager<Store>, taskIdentifier: String, eventQuery: OCKEventQuery) {
        super.init(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery)
    }

    /// Create a view controller that displays an event for a specified task.
    /// - Parameter storeManager: The store manager used to provide synchronization.
    /// - Parameter task: The event's task.
    /// - Parameter eventQuery: The query used to find en event for the task.
    override public init(storeManager: OCKSynchronizedStoreManager<Store>, task: Store.Task, eventQuery: OCKEventQuery) {
        super.init(storeManager: storeManager, task: task, eventQuery: eventQuery)
    }

    // MARK: - Methods

    private func clearView(_ view: OCKButtonLogTaskView, animated: Bool) {
        [view.headerView.titleLabel, view.headerView.detailLabel, view.instructionsLabel].forEach { $0.text = nil }
        view.clearItems(animated: animated)
    }

    /// Update the view whenever the view model changes.
    /// - Parameter view: The view to update.
    /// - Parameter context: The data associated with the updated state.
    override open func updateView(_ view: OCKButtonLogTaskView, context: OCKSynchronizationContext<Store.Event>) {
        guard let model = context.viewModel else {
            clearView(view, animated: context.animated)
            return
        }

        let event = model.convert()
        view.headerView.titleLabel.text = event.task.title
        view.headerView.detailLabel.text = event.scheduleEvent.element.text ?? OCKScheduleUtility.scheduleLabel(for: model)
        view.instructionsLabel.text = event.task.instructions

        OCKLogUtility.updateItems(withOutcomeValues: event.outcome?.values ?? [], inView: view, animated: context.animated)
    }

    /// Create an instance of the view to be displayed.
    override open func makeView() -> OCKButtonLogTaskView {
        return .init()
    }

    // MARK: - OCKEventViewDelegate

    /// Present an action sheet with an option to delete an outcome value. Uses the outcome value at `index` in the list of outcome values for
    /// the current `viewModel` sorted by their `updateDate` (or `createdDate` if the former does not exist).
    /// - Parameter eventView: The view displaying the event.
    /// - Parameter index: The index of the outcome value.
    /// - Parameter sender: The sender that triggered the selection.
    override open func eventView(_ eventView: UIView & OCKEventDisplayable, didSelectOutcomeValueAt index: Int, sender: Any?) {
        // Adjust the index to match the item in the array of sorted outcome values
        guard let outcomeValues = viewModel?.outcome?.convert().values else { return }
        let adjustedIndex = OCKLogUtility.indexOf(sortedIndex: index, in: outcomeValues)
        super.eventView(eventView, didSelectOutcomeValueAt: adjustedIndex, sender: sender)
    }
}

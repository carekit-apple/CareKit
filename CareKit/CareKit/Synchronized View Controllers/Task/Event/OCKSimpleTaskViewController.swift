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

/// A view controller showing an `OCKSimpleTaskView` that is synchronized with a single event and its outcomes. Allows the user to mark an event
/// complete.
///
/// - Note: This view controller is created by specifying a task and an event query. If the event query returns more than one event, only
/// the first event will be displayed.
open class OCKSimpleTaskViewController<Store: OCKStoreProtocol>: OCKEventViewController<OCKSimpleTaskView, Store> {
    // MARK: Properties

    /// The type of the view being displayed.
    public typealias View = OCKSimpleTaskView

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

    /// Create an instance of the view to be displayed.
    override open func makeView() -> OCKSimpleTaskView {
        return .init()
    }

    private func clearView(_ view: OCKSimpleTaskView, animated: Bool) {
        view.headerView.titleLabel.text = nil
        view.headerView.detailLabel.text = nil
    }

    /// Update the view whenever the view model changes.
    /// - Parameter view: The view to update.
    /// - Parameter context: The data associated with the updated state.
    override open func updateView(_ view: OCKSimpleTaskView, context: OCKSynchronizationContext<Store.Event>) {
        guard let event = context.viewModel else {
            clearView(view, animated: context.animated)
            return
        }

        let convertedTask = event.task.convert()
        view.completionButton.isSelected = context.viewModel?.outcome != nil
        view.headerView.titleLabel.text = convertedTask.title
        view.headerView.detailLabel.text = OCKScheduleUtility.scheduleLabel(for: event)
    }

    /// Empty implementation to avoid presenting the details view controller.
    /// - Parameter outcomeView: The view displaying the outcome
    override open func didSelectEventView(_ outcomeView: UIView & OCKEventDisplayable) { }
}

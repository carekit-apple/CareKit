/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.

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
import UIKit

/// A view controller that displays a task view and keeps it synchronized with a store.
open class OCKTaskViewController<
    ViewSynchronizer: ViewSynchronizing
>: SynchronizedViewController<ViewSynchronizer>, OCKTaskViewDelegate where
    ViewSynchronizer.View: OCKTaskDisplayable,
    ViewSynchronizer.ViewModel == OCKTaskEvents
{

    let store: OCKAnyStoreProtocol

    /// The view that is being synchronized against the store.
    @available(*, deprecated, renamed: "typedView")
    public var taskView: ViewSynchronizer.View {
        return typedView
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:modifyTaskEvents:)")
    public init<Controller>(controller: Controller, viewSynchronizer: ViewSynchronizer) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:modifyTaskEvents:)")
    public convenience init(
        viewSynchronizer: ViewSynchronizer,
        task: OCKAnyTask,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:modifyTaskEvents:)")
    public convenience init(
        viewSynchronizer: ViewSynchronizer,
        taskIDs: [String],
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:modifyTaskEvents:)")
    public convenience init(
        viewSynchronizer: ViewSynchronizer,
        taskID: String,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    /// Creates a view controller that displays a task view and keeps it synchronized with a store.
    /// 
    /// - Parameters:
    ///   - query: The query for fetching the task data to display.
    ///   - store: Contains the task data to display.
    ///   - viewSynchronizer: Capable of creating and updating the view using the task data.
    ///   - modifyTaskEvents: Modify task events before they are applied to the view.
    public init(
        query: OCKEventQuery,
        store: OCKAnyStoreProtocol,
        viewSynchronizer: ViewSynchronizer,
        modifyTaskEvents: @escaping (OCKTaskEvents) -> OCKTaskEvents = { $0 }
    ) {
        self.store = store

        let taskEvents = store
            .anyEvents(matching: query)
            .map { OCKTaskEvents(events: $0) }
            .map { modifyTaskEvents($0) }

        super.init(
            initialViewModel: OCKTaskEvents(),
            viewModels: taskEvents,
            viewSynchronizer: viewSynchronizer
        )
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        typedView.delegate = self
    }

    // MARK: - OCKTaskViewDelegate

    open func taskView(_ taskView: UIView & OCKTaskDisplayable, didCompleteEvent isComplete: Bool, at indexPath: IndexPath, sender: Any?) {
        let event = viewModel[indexPath.section][indexPath.row]
        store.toggleBooleanOutcome(for: event) { [weak self] in
            self?.resetViewOnError(result: $0)
        }
    }

    open func taskView(_ taskView: UIView & OCKTaskDisplayable, didSelectOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?) {

        // Make an action sheet to delete the outcome value
        let actionSheet = UIAlertController(title: loc("LOG_ENTRY"), message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: loc("CANCEL"), style: .default, handler: nil)
        let event = viewModel[eventIndexPath.section][eventIndexPath.row]
        let delete = UIAlertAction(title: loc("DELETE"), style: .destructive) { [weak self] _ in
            self?.store.deleteOutcomeValue(at: index, event: event)
        }
        [delete, cancel].forEach { actionSheet.addAction($0) }

        if let anchor = sender as? UIView {
            actionSheet.popoverPresentationController?.sourceRect = anchor.bounds
            actionSheet.popoverPresentationController?.sourceView = anchor
            actionSheet.popoverPresentationController?.permittedArrowDirections = .any
        }

        /*
         TODO: Remove in the future. Explicitly setting the tint color here to support
         current developers that have a SwiftUI lifecycle app and wrap this view
         controller in a `UIViewControllerRepresentable` implementation...Tint color
         is not propagated...etc.
         */
        actionSheet.view.tintColor = determineTintColor(from: view)
        present(actionSheet, animated: true, completion: nil)
    }

    open func taskView(_ taskView: UIView & OCKTaskDisplayable, didCreateOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?) {
        let event = viewModel[eventIndexPath.section][eventIndexPath.row]
        store.append(outcomeValue: true, event: event) { [weak self] in
            self?.resetViewOnError(result: $0)
        }
    }

    open func didSelectTaskView(_ taskView: UIView & OCKTaskDisplayable, eventIndexPath: IndexPath) {
        let event = viewModel[eventIndexPath.section][eventIndexPath.row]
        let detailViewController = OCKDetailViewController(showsCloseButton: true)
        detailViewController.detailView.titleLabel.text = event.task.title
        detailViewController.detailView.bodyLabel.text = event.task.instructions
        detailViewController.detailView.imageView.image = UIImage.asset(event.task.asset)
        /*
         TODO: Remove in the future. Explicitly setting the tint color here to support
         current developers that have a SwiftUI lifecycle app and wrap this view
         controller in a `UIViewControllerRepresentable` implementation...Tint color
         is not propagated...etc.
         */
        detailViewController.view.tintColor = determineTintColor(from: view)

        present(detailViewController, animated: true)
    }
}

#endif

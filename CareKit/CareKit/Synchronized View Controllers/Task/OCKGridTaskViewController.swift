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

/// A view controller showing an `OCKGridTaskView` that is synchronized with a single task and its events. Displays events for the task, and
/// allows the user to mark them as complete.
open class OCKGridTaskViewController<Store: OCKStoreProtocol>: OCKTaskViewController<OCKGridTaskView, Store>, UICollectionViewDataSource {
    // MARK: Properties

    /// The type of the view being displayed.
    public typealias View = OCKGridTaskView

    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

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

    override open func viewDidLoad() {
        super.viewDidLoad()
        synchronizedView.collectionView.dataSource = self
    }

    // MARK: - Methods

    /// Create an instance of the view to be displayed.
    override open func makeView() -> OCKGridTaskView {
        return .init()
    }

    /// Update the view whenever the view model changes.
    /// - Parameter view: The view to update.
    /// - Parameter context: The data associated with the updated state.
    override open func updateView(_ view: OCKGridTaskView, context: OCKSynchronizationContext<[Store.Event]>) {
        updateViewWithTask(viewModel?.first?.task, view: view)
        updateViewWithEvents(viewModel, view: view)
    }

    private func updateViewWithTask(_ task: Store.Task?, view: OCKGridTaskView) {
        guard let task = task?.convert() else {
            view.headerView.titleLabel.text = nil
            view.instructionsLabel.text = nil
            view.headerView.detailLabel.text = nil
            return
        }

        view.headerView.titleLabel.text = task.title
        view.instructionsLabel.text = task.instructions
    }

    private func updateViewWithEvents(_ events: [OCKEvent<Store.Task, Store.Outcome>]?, view: OCKGridTaskView) {
        view.headerView.detailLabel.text = OCKScheduleUtility.scheduleLabel(for: events ?? [])
        view.collectionView.reloadData()
    }

    // MARK: - UICollectionViewDataSource

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.count ?? 0
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OCKGridTaskView.defaultCellIdentifier,
                                                            for: indexPath) as? OCKGridTaskView.DefaultCellType else {
                                                                fatalError("Unsupported cell type.")
        }

        let event = viewModel?[indexPath.row]

        // set label for completed state
        let completeDate = event?.outcome?.convert().createdDate
        let completeString = completeDate != nil ? timeFormatter.string(from: completeDate!) : nil
        cell.completionButton.setTitle(completeString, for: .selected)

        // set label for normal state to be the time of the event
        let incompleteString = event != nil ? OCKScheduleUtility.timeLabel(for: event!, includesEnd: false) : indexPath.row.description
        cell.completionButton.setTitle(incompleteString, for: .normal)

        cell.completionButton.isSelected = event?.outcome != nil
        return cell
    }
}

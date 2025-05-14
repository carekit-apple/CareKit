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

/// A task view controller that displays multiple events in a grid collection view.
open class OCKGridTaskViewController: OCKTaskViewController<OCKGridTaskViewSynchronizer>, UICollectionViewDataSource {

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public init<Controller>(
        controller: Controller,
        viewSynchronizer: OCKGridTaskViewSynchronizer
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public convenience init(
        viewSynchronizer: OCKGridTaskViewSynchronizer = OCKGridTaskViewSynchronizer(),
        task: OCKAnyTask,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public convenience init(
        viewSynchronizer: OCKGridTaskViewSynchronizer = OCKGridTaskViewSynchronizer(),
        taskID: String,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    /// Creates a view controller that displays a task view and keeps it synchronized with a store.
    /// 
    /// - Parameters:
    ///   - query: Fetches the task data to display.
    ///   - store: Contains the task data to display.
    ///   - viewSynchronizer: Capable of creating and updating the view using the task data.
    public init(
        query: OCKEventQuery,
        store: OCKAnyStoreProtocol,
        viewSynchronizer: OCKGridTaskViewSynchronizer = OCKGridTaskViewSynchronizer()
    ) {
        super.init(query: query, store: store, viewSynchronizer: viewSynchronizer)
    }

    // MARK: - Methods

    override open func viewDidLoad() {
        super.viewDidLoad()
        typedView.collectionView.dataSource = self
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.first?.count ?? 0
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OCKGridTaskView.defaultCellIdentifier, for: indexPath)
        guard let typedCell = cell as? OCKGridTaskView.DefaultCellType else { return cell }
        let event = viewModel[indexPath.section][indexPath.row]
        typedCell.updateWith(event: event, animated: false)
        return cell
    }
}

#endif

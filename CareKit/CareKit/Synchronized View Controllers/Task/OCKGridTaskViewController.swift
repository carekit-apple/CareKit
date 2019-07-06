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
import CareKitUI
import CareKitStore

/// A synchronized view controller that displays a grid of events for a task.
open class OCKGridTaskViewController<Store: OCKStoreProtocol>: OCKTaskViewController<Store>, UICollectionViewDelegate {
    
    override var detailPresentingView: UIView? {
        return taskView.headerView
    }
    
    /// The view that the task and its events are displayed in.
    public var taskView: OCKTaskGridView {
        guard let view = view as? OCKTaskGridView else { fatalError("Unexpected type") }
        return view
    }
    
    // MARK: Initializers
    
    /// Initialize with a task.
    ///
    /// - Parameters:
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - task: The task which to display.
    ///   - eventQuery: An event query that will specify which events will be displayed in the view.
    public init(storeManager: OCKSynchronizedStoreManager<Store>, task: Store.Task, eventQuery: OCKEventQuery) {
        super.init(storeManager: storeManager, task: task, eventQuery: eventQuery, loadDefaultView: {
            OCKBindableGridTaskView<Store.Task, Store.Outcome>()
        })
    }
    
    /// Initialize with a task identifier. The task will be fetched from the store automatically.
    ///
    /// - Parameters:
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - taskIdentifier: The identifier of the task which should be fetched and displayed.
    ///   - eventQuery: An event query that will specify which events will be displayed in the view.
    public init(storeManager: OCKSynchronizedStoreManager<Store>, taskIdentifier: String, eventQuery: OCKEventQuery) {
        super.init(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery,
                   loadDefaultView: { OCKBindableGridTaskView<Store.Task, Store.Outcome>() })
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        taskView.collectionView.delegate = self
    }
    
    // MARK: UICollectionViewDelegate
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < events.count else { return }
        let event = events[indexPath.row]
        event.outcome == nil ? saveNewOutcome(forEvent: event) : deleteOutcome(forEvent: event)
    }
}

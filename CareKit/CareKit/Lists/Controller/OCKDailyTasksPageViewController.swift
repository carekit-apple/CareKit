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
import Combine
import UIKit

/// Displays a calendar page view controller in the header, and a collection of tasks
/// in the body. The tasks are automatically queried based on the selection in the calendar.
open class OCKDailyTasksPageViewController<Store: OCKStoreProtocol>: OCKDailyPageViewController<Store> {
    private let emptyLabelMargin: CGFloat = 4

    /// If set, the delegate will receive callbacks when important events happen at the task view controller level.
    public weak var taskDelegate: OCKTaskViewControllerDelegate?

    override open func dailyPageViewController<S>(
        _ dailyPageViewController: OCKDailyPageViewController<S>,
        prepare listViewController: OCKListViewController,
        for date: Date) where S: OCKStoreProtocol {
        fetchTasks(for: date, andPopulateIn: listViewController)
    }

    private func fetchTasks(for date: Date, andPopulateIn listViewController: OCKListViewController) {
        storeManager.store.fetchTasks(nil, query: OCKTaskQuery(for: date), queue: .main) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.dailyPageViewController(self, didFailWithError: error)
            case .success(let tasks):
                let eventQuery = OCKEventQuery(for: date)
                for task in tasks {
                    let taskViewController = OCKGridTaskViewController(storeManager: self.storeManager, task: task, eventQuery: eventQuery)
                    taskViewController.delegate = self.taskDelegate
                    listViewController.appendViewController(taskViewController, animated: false)
                }

                if tasks.isEmpty {
                    listViewController.listView.stackView.spacing = self.emptyLabelMargin
                    let emptyLabel = OCKEmptyLabel(textStyle: .subheadline, weight: .medium)
                    listViewController.appendView(emptyLabel, animated: false)
                }
            }
        }
    }
}

private class OCKEmptyLabel: OCKLabel {
    override init(textStyle: UIFont.TextStyle, weight: UIFont.Weight) {
        super.init(textStyle: textStyle, weight: weight)
        text = OCKStrings.noTasks
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func styleDidChange() {
        super.styleDidChange()
        textColor = style().color.label
    }
}

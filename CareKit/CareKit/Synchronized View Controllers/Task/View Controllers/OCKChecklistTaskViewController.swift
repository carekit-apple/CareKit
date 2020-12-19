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

import Foundation

public typealias OCKChecklistTaskViewController = OCKTaskViewController<OCKChecklistTaskController, OCKChecklistTaskViewSynchronizer>

public extension OCKTaskViewController where Controller: OCKTaskController, ViewSynchronizer == OCKChecklistTaskViewSynchronizer {

    /// Initialize a view controller that displays a task. Fetches and stays synchronized with events for the task.
    /// - Parameter task: The task to display.
    /// - Parameter eventQuery: Used to fetch events for the task.
    /// - Parameter storeManager: Wraps the store that contains the events to fetch.
    convenience init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        self.init(viewSynchronizer: ViewSynchronizer(), task: task, eventQuery: eventQuery, storeManager: storeManager)
    }

    /// Initialize a view controller that displays tasks. Fetches and stays synchronized with events for the tasks.
    /// - Parameter taskIDs: User defined ids for the tasks to fetch.
    /// - Parameter eventQuery: Used to fetch events for the tasks.
    /// - Parameter storeManager: Wraps the store that contains the tasks and events to fetch.
    convenience init(taskIDs: [String], eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        self.init(viewSynchronizer: ViewSynchronizer(), taskIDs: taskIDs, eventQuery: eventQuery, storeManager: storeManager)
    }

    /// Initialize a view controller that displays task. Fetches and stays synchronized with events for the task.
    /// - Parameter viewSynchronizer: Manages the task view.
    /// - Parameter taskID: User defined id of the task to fetch.
    /// - Parameter eventQuery: Used to fetch events for the task.
    /// - Parameter storeManager: Wraps the store that contains the task and events to fetch.
    convenience init(taskID: String, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        self.init(viewSynchronizer: ViewSynchronizer(), taskID: taskID, eventQuery: eventQuery, storeManager: storeManager)
    }
}

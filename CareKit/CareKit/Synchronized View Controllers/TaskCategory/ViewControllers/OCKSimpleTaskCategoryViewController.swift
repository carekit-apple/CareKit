//
/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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
import Foundation

public typealias OCKSimpleTaskCategoryViewController = OCKTaskCategoryViewController<OCKSimpleTaskCategoryController, OCKSimpleTaskCategoryViewSynchronizer>

public extension OCKTaskCategoryViewController where Controller: OCKSimpleTaskCategoryController, ViewSynchronizer == OCKSimpleTaskCategoryViewSynchronizer {

    /// Initialize a view controller that displays a task category in the store. Stays synchronized with the provided task category.
    /// - Parameter taskCategory: The task category to display.
    /// - Parameter storeManager: Wraps the store that contains the task category to fetch.
    convenience init(taskCategory: OCKAnyTaskCategory, storeManager: OCKSynchronizedStoreManager) {
        self.init(viewSynchronizer: ViewSynchronizer(), taskCategory: taskCategory, storeManager: storeManager)
    }

    /// Initialize a view controller that displays a task category. Fetches and stays synchronized with the task category.
    /// - Parameter query: Used to fetch the task category to display.
    /// - Parameter storeManager: Wraps the store that contains the task category to fetch.
    convenience init(query: OCKAnyTaskCategoryQuery, storeManager: OCKSynchronizedStoreManager) {
        self.init(viewSynchronizer: ViewSynchronizer(), query: query, storeManager: storeManager)
    }

    /// Initialize a view controller that displays a task category. Fetches and stays synchronized with the task category.
    /// - Parameter taskCategoryID: The user-defined unique identifier for the task category to fetch.
    /// - Parameter storeManager: Wraps the store that contains the task category to fetch.
    convenience init(taskCategoryID: String, storeManager: OCKSynchronizedStoreManager) {
        self.init(viewSynchronizer: ViewSynchronizer(), taskCategoryID: taskCategoryID, storeManager: storeManager)
    }
}

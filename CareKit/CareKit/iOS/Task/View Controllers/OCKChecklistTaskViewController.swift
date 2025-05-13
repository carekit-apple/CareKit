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
import Foundation

/// A view controller that shows detailed descriptions for complete or incomplete events, organized in a checklist.
open class OCKChecklistTaskViewController: OCKTaskViewController<OCKChecklistTaskViewSynchronizer> {

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public init<Controller>(
        controller: Controller,
        viewSynchronizer: OCKChecklistTaskViewSynchronizer
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public convenience init(
        viewSynchronizer: OCKChecklistTaskViewSynchronizer = OCKChecklistTaskViewSynchronizer(),
        task: OCKAnyTask,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public convenience init(
        viewSynchronizer: OCKChecklistTaskViewSynchronizer = OCKChecklistTaskViewSynchronizer(),
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
        viewSynchronizer: OCKChecklistTaskViewSynchronizer = OCKChecklistTaskViewSynchronizer()
    ) {
        super.init(query: query, store: store, viewSynchronizer: viewSynchronizer)
    }
}

#endif

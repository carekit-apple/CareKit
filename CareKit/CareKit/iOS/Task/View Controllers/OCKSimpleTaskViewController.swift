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
#if !os(watchOS) && !os(macOS) && !os(visionOS)

import CareKitStore
import Foundation

/// A view controller that display and updates a single event that can be completed or uncompleted by tapping a large button.
open class OCKSimpleTaskViewController: OCKTaskViewController<OCKSimpleTaskViewSynchronizer> {

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public init<Controller>(
        controller: Controller,
        viewSynchronizer: OCKSimpleTaskViewSynchronizer
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public convenience init(
        viewSynchronizer: OCKSimpleTaskViewSynchronizer = OCKSimpleTaskViewSynchronizer(),
        task: OCKAnyTask,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:viewSynchronizer:)")
    public convenience init(
        viewSynchronizer: OCKSimpleTaskViewSynchronizer = OCKSimpleTaskViewSynchronizer(),
        taskID: String,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager
    ) {
        fatalError("Unavailable")
    }

    /// A view controller that displays a task view and keeps it synchronized with a store.
    /// - Parameters:
    ///   - query: Used to fetch the task data that will be displayed.
    ///   - store: Contains the task data that will be displayed.
    ///   - viewSynchronizer: Capable of creating and updating the view using the task data.
    public init(
        query: OCKEventQuery,
        store: OCKAnyStoreProtocol,
        viewSynchronizer: OCKSimpleTaskViewSynchronizer = OCKSimpleTaskViewSynchronizer()
    ) {
        super.init(query: query, store: store, viewSynchronizer: viewSynchronizer)
    }
}

#endif

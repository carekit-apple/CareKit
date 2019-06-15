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

/// An synchronized view controller that displays a single event and it's outcomes and allows the patient to log outcomes.
///
/// - Note: `OCKEventViewController`s are created by specifying a task and an event query. If the event query
/// returns more than one event, only the first event will be displayed.
open class OCKSimpleLogTaskViewController<Store: OCKStoreProtocol>: OCKLogTaskViewController<Store, OCKSimpleLogTaskView> {
    
    /// Initialize using an identifier.
    ///
    /// - Parameters:
    ///   - style: A style that determines which subclass will be instantiated.
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - taskIdentifier: The identifier event's task.
    ///   - eventQuery: An event query that specifies which events will be queried and displayed.
    public init(storeManager: OCKSynchronizedStoreManager<Store>, taskIdentifier: String, eventQuery: OCKEventQuery) {
        super.init(storeManager: storeManager, taskIdentifier: taskIdentifier, eventQuery: eventQuery,
                   loadDefaultView: { OCKBindableSimpleLogTaskView<Store.Task, Store.Outcome>() })
    }
    
    /// Initialize using a task.
    ///
    /// - Parameters:
    ///   - storeManager: A store manager that will be used to provide synchronization.
    ///   - task: The task to which the event to be displayed belongs.
    ///   - eventQuery: An event query that specifies which events will be queried and displayed.
    public convenience init(storeManager: OCKSynchronizedStoreManager<Store>, task: Store.Task, eventQuery: OCKEventQuery) {
        self.init(storeManager: storeManager, taskIdentifier: task.identifier, eventQuery: eventQuery)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        taskView.logButton.addTarget(self, action: #selector(outcomeButtonPressed(_:)), for: .touchUpInside)
    }
    
}

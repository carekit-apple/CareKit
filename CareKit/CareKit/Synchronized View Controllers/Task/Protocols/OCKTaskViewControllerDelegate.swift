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
import UIKit

/// Conform to this protocol to receive callbacks when important events happen inside an `OCKTaskViewControllers`.
public protocol OCKTaskViewControllerDelegate: AnyObject {
    /// Called when a task view controller finishes querying a task and its events.
    /// - Parameter taskViewController: The task view controller which performed the query.
    /// - Parameter task: The task that was queried.
    /// - Parameter events: The events that were queried.
    func taskViewController<V: UIView, S: OCKStoreProtocol>(_ taskViewController: OCKTaskViewController<V, S>,
                                                            didFinishQuerying task: S.Task?,
                                                            andEvents events: [S.Event])

    /// Called when an unhandled error is encountered in a task view controller.
    /// - Parameter taskViewController: The task view controller in which the error occurred.
    /// - Parameter error: The error that occurred.
    func taskViewController<V: UIView, S: OCKStoreProtocol>(_ taskViewController: OCKTaskViewController<V, S>,
                                                            didFailWithError error: Error)
}

public extension OCKTaskViewControllerDelegate {
    func taskViewController<V: UIView, S: OCKStoreProtocol>(_ taskViewController: OCKTaskViewController<V, S>,
                                                            didFinishQuerying task: S.Task?,
                                                            andEvents events: [S.Event]) {}

    func taskViewController<V: UIView, S: OCKStoreProtocol>(_ taskViewController: OCKTaskViewController<V, S>,
                                                            didFailWithError error: Error) {}
}

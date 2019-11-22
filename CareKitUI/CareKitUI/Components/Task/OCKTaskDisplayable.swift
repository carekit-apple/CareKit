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

/// Any object that can display and handle interactions with a task.
public protocol OCKTaskDisplayable: AnyObject {
    /// Handles events related to an `OCKTaskDisplayable` object.
    var delegate: OCKTaskViewDelegate? { get set }
}

/// Handles events related to an `OCKTaskDisplayable` object.
public protocol OCKTaskViewDelegate: AnyObject {

    /// Called when an event is completed.
    /// - Parameters:
    ///   - taskView: View displaying the event.
    ///   - isComplete: True if the event is complete.
    ///   - indexPath: Index path of the event.
    ///   - sender: Sender that initiated the completion.
    func taskView(_ taskView: UIView & OCKTaskDisplayable, didCompleteEvent isComplete: Bool, at indexPath: IndexPath, sender: Any?)

    /// Called when an outcome value was selected for a particular event.
    /// - Parameters:
    ///   - taskView: View displaying the outcome value.
    ///   - index: Indec of the outcome value in the event's oucome.
    ///   - eventIndexPath: index path of the event.
    ///   - sender: Sender that initiated the selection.
    func taskView(_ taskView: UIView & OCKTaskDisplayable, didSelectOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?)

    /// Called when an outcome value has been created at a particular index.
    /// - Parameters:
    ///   - taskView: View displaying the outcome.
    ///   - index: Index of the new outcome value.
    ///   - eventIndexPath: Index of the event.
    ///   - sender: Sender that initiated the outcome value creation.
    func taskView(_ taskView: UIView & OCKTaskDisplayable, didCreateOutcomeValueAt index: Int, eventIndexPath: IndexPath, sender: Any?)

    /// Called when the task view has been selected.
    /// - Parameters:
    ///   - taskView: The task view that has been selected.
    ///   - eventIndexPath: The index path of the event displayed by the task view.
    func didSelectTaskView(_ taskView: UIView & OCKTaskDisplayable, eventIndexPath: IndexPath)
}

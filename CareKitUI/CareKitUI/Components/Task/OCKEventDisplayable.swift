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

/// Any object that can display and handle interactions with an event for a task.
public protocol OCKEventDisplayable: AnyObject {
    /// Handles events related to an `OCKEventDisplayable` object.
    var delegate: OCKEventViewDelegate? { get set }
}

/// Handles events related to an `OCKEventDisplayable` object.
public protocol OCKEventViewDelegate: AnyObject {
    /// Called when an event should be marked complete.
    /// - Parameter eventView: The view displaying the event.
    /// - Parameter isComplete: True if the event is complete.
    /// - Parameter sender: The sender that triggered the completion of the event.
    func eventView(_ eventView: UIView & OCKEventDisplayable, didCompleteEvent isComplete: Bool, sender: Any?)

    /// Called when an outcome value for an event's outcome was selected.
    /// - Parameter eventView: The view displaying the outcome.
    /// - Parameter index: The index of the outcome value.
    /// - Parameter sender: The sender that triggered the selection.
    func eventView(_ eventView: UIView & OCKEventDisplayable, didSelectOutcomeValueAt index: Int, sender: Any?)

    /// Called when the user would like to save a new outcome value for an event's outcome.
    /// - Parameter eventView: The view displaying the outcome.
    /// - Parameter index: The index of the sender in the `logButtonsCollectionView`.
    /// - Parameter sender: The sender that created the outcome value.
    func eventView(_ eventView: UIView & OCKEventDisplayable, didCreateOutcomeValueAt index: Int, sender: Any?)

    /// Called when the view displaying the event was selected.
    /// - Parameter eventView: The view displaying the event.
    func didSelectEventView(_ eventView: UIView & OCKEventDisplayable)
}

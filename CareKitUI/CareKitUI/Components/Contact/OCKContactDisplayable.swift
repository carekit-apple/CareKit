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

/// Any object that can display and handle interactions with a contact.
public protocol OCKContactDisplayable: AnyObject {
    /// Handles events related to an `OCKContactDisplayable` object.
    var delegate: OCKContactViewDelegate? { get set }
}

/// Handles events related to an `OCKContactDisplayable` object.
public protocol OCKContactViewDelegate: AnyObject {
    /// Called when the user would like to call the contact.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the call process.
    func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateCall sender: Any?)

    /// Called when the user would like to message the contact.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the messaging process.
    func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateMessage sender: Any?)

    /// Called when the user would like to email the contact.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the email process.
    func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateEmail sender: Any?)

    /// Called when the user would like to view the address of the contact.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the address lookup process.
    func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateAddressLookup sender: Any?)

    /// Called when the view displaying the contact was selected.
    /// - Parameter contactView: The view displaying the contact.
    func didSelectContactView(_ contactView: UIView & OCKContactDisplayable)
}

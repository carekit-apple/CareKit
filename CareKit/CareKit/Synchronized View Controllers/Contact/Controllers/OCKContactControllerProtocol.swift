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
import Combine
import Contacts
import ContactsUI
import Foundation
import MapKit
import MessageUI

/// Describes an object capable of tracking and updating the state of a contact.
public protocol OCKContactControllerProtocol {

    /// A reference to a writable store.
    var store: OCKAnyContactStore { get }

    /// A publisher that publishers new values when the watched contact changes in the store.
    var objectWillChange: CurrentValueSubject<OCKAnyContact?, Never> { get }

    // MARK: Implementation Provided

    /// Initiate a phone call and return the URL to be dialed.
    func initiateCall() throws -> URL

    /// Initiate a message and return the `MFMessageComposeViewController` that needs to be presented.
    func initiateMessage() throws -> MFMessageComposeViewController

    /// Initiate an email and return the `MFMailComposeViewController` that should be presented.
    func initiateEmail() throws -> MFMailComposeViewController

    /// Lookup the address of the current contact.
    /// - Parameter completion: A closure to be called with the result
    func initiateAddressLookup(completion: @escaping (Result<MKMapItem, Error>) -> Void)

    /// Attempt to find contact in the system contacts and return a `CNContactViewController` to display it.
    func initiateSystemContactLookup() throws -> CNContactViewController
}

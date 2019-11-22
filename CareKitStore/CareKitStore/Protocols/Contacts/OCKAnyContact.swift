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

/// An enumerator specifying which group a contact belongs to.
public enum OCKContactCategory: String, Codable {
    case careProvider
    case friendsAndFamily
}

/// Conforming a type to `OCKAnyContact` allows it to be queried and displayed by CareKit.
public protocol OCKAnyContact {

    /// A user-defined unique identifier, typically human readable.
    var id: String { get }

    /// The contact's name.
    var name: PersonNameComponents { get }

    /// The contact's postal address.
    var address: OCKPostalAddress? { get }

    /// An array of the contact's email addresses.
    var emailAddresses: [OCKLabeledValue]? { get }

    /// An array of numbers that the contact can be messaged at.
    /// The number strings may contains non-numeric characters.
    var messagingNumbers: [OCKLabeledValue]? { get }

    /// An array of the contact's phone numbers.
    /// The number strings may contains non-numeric characters.
    var phoneNumbers: [OCKLabeledValue]? { get }

    /// An array of other information that could be used reach this contact.
    var otherContactInfo: [OCKLabeledValue]? { get }

    /// The organization this contact belongs to.
    var organization: String? { get }

    /// A title for this contact.
    var title: String? { get }

    /// A description of what this contact's role is.
    var role: String? { get }

    /// A string representation of an asset.
    var asset: String? { get }

    /// Indicates if this contact is care provider or if they are a friend or family member.
    var category: OCKContactCategory? { get }

    /// An identifier for this contact in a remote store.
    var remoteID: String? { get }

    /// An identifier that can be uesd to group this contact with others.
    var groupIdentifier: String? { get }

    /// Any array of notes associated with this object.
    var notes: [OCKNote]? { get }

    /// Determines if this contact belongs to the given care plan.
    ///
    /// - Parameter plan: A care plan which may or may not own this contact.
    func belongs(to plan: OCKAnyCarePlan) -> Bool
}

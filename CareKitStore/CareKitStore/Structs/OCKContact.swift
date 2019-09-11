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

import Contacts
import Foundation

/// An `OCKContact` represents a contact that a user may want to get in touch with. A contact may be a care provider, a friend, or a family
/// member. Contacts must have at least a name, and may optionally have numerous other addresses at which to be contacted.
public struct OCKContact: Codable, Equatable, OCKVersionSettable, OCKObjectCompatible, OCKContactConvertible {
    /// The contact's name.
    public var name: PersonNameComponents

    /// The contact's postal address.
    public var address: OCKPostalAddress?

    /// An array of the contact's email addresses.
    public var emailAddresses: [OCKLabeledValue]?

    /// An array of numbers that the contact can be messaged at.
    /// The number strings may contains non-numeric characters.
    public var messagingNumbers: [OCKLabeledValue]?

    /// An array of the contact's phone numbers.
    /// The number strings may contains non-numeric characters.
    public var phoneNumbers: [OCKLabeledValue]?

    /// An array of other information that could be used reach this contact.
    public var otherContactInfo: [OCKLabeledValue]?

    /// The organization this contact belongs to.
    public var organization: String?

    /// A title for this contact.
    public var title: String?

    /// A description of what this contact's role is.
    public var role: String?

    /// Indicates if this contact is care provider or if they are a friend or family member.
    public var category: Category?

    /// The version identifier in the local database for the care plan associated with this contact.
    public var carePlanID: OCKLocalVersionID?

    /// An enumerator specifying which group a contact belongs to.
    public enum Category: String, Codable {
        case careProvider
        case friendsAndFamily
    }

    // MARK: OCKIdentifiable
    public let identifier: String

    // MARK: OCKVersionable
    public var effectiveDate: Date
    public internal(set) var deletedDate: Date?
    public internal(set) var localDatabaseID: OCKLocalVersionID?
    public internal(set) var nextVersionID: OCKLocalVersionID?
    public internal(set) var previousVersionID: OCKLocalVersionID?

    // MARK: OCKObjectCompatible
    public internal(set) var createdDate: Date?
    public internal(set) var updatedDate: Date?
    public internal(set) var schemaVersion: OCKSemanticVersion?
    public var groupIdentifier: String?
    public var tags: [String]?
    public var remoteID: String?
    public var userInfo: [String: String]?
    public var source: String?
    public var asset: String?
    public var notes: [OCKNote]?

    /// Initialize a new `OCKContact` with a user-defined identifier, a name, and an optional care plan version ID.
    ///
    /// - Parameters:
    ///   - identifier: A user-defined identifier
    ///   - name: The contact's name
    ///   - carePlanID: The local database identifier of the careplan with which this contact is associated.
    public init(identifier: String, name: PersonNameComponents, carePlanID: OCKLocalVersionID?) {
        self.identifier = identifier
        self.name = name
        self.carePlanID = carePlanID
        self.effectiveDate = Date()
    }

    /// Initialize a new `OCKContact` with a user-defined identifier, a name, and an optional care plan version ID.
    ///
    /// - Parameters:
    ///   - identifier: A user-defined identifier
    ///   - name: The contact's name
    ///   - carePlanID: The local database identifier of the careplan with which this contact is associated.
    public init(identifier: String, givenName: String, familyName: String, carePlanID: OCKLocalVersionID?) {
        self.name = PersonNameComponents()
        self.name.givenName = givenName
        self.name.familyName = familyName
        self.identifier = identifier
        self.carePlanID = carePlanID
        self.effectiveDate = Date()
    }

    /// Initialize from an `OCKContact`
    ///
    /// - Parameter value: The contact which to copy.
    public init(_ value: OCKContact) {
        self = value
    }

    /// Convert to an `OCKContact`
    /// - Note: Because `OCKContact` is already an `OCKContact`, this method just returns `self`.
    public func convert() -> OCKContact {
        return self
    }
}

/// A `Codable` subclass of `CNMutablePostalAddress`.
@objc // We subclass for sole purpose of adding conformance to Codable.
public class OCKPostalAddress: CNMutablePostalAddress, Codable {}

/// An optional label paired with a value used to represent contact information.
/// The label will typically indicate what kind of information the value carries.
public struct OCKLabeledValue: Codable, Equatable {
    // Note: We cannot simply subclass `CNLabeledValue` the same we do with `CNMutablePostalAddress` because it is a generic class and not visible
    // to @objc. Instead, we use this struct and convert to and from `CNLabeledValue` when required. This is all to get `Codable`.

    /// A description of what the label is, i.e. "Home Email", "Office Phone"
    public var label: String

    /// The actual contact information, i.e. a phone number or email address.
    public var value: String

    /// Initialize with an optional label and a value.
    ///
    /// - Parameters:
    ///   - label: A description of what the label is, i.e. "Home Email", "Office Phone"
    ///   - value: The actual contact information, i.e. a phone number or email address.
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

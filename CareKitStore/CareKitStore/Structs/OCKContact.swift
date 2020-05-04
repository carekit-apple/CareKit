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
public struct OCKContact: Codable, Equatable, Identifiable, OCKAnyContact, OCKVersionedObjectCompatible {

    /// The version id in the local database for the care plan associated with this contact.
    public var carePlanUUID: UUID?

    // MARK: OCKAnyContact
    public let id: String
    public var name: PersonNameComponents
    public var address: OCKPostalAddress?
    public var emailAddresses: [OCKLabeledValue]?
    public var messagingNumbers: [OCKLabeledValue]?
    public var phoneNumbers: [OCKLabeledValue]?
    public var otherContactInfo: [OCKLabeledValue]?
    public var organization: String?
    public var title: String?
    public var role: String?
    public var category: OCKContactCategory?

    // MARK: OCKVersionable
    public var effectiveDate: Date
    public internal(set) var deletedDate: Date?
    public internal(set) var uuid: UUID?
    public internal(set) var nextVersionUUID: UUID?
    public internal(set) var previousVersionUUID: UUID?

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
    public var timezone: TimeZone

    // MARK: Deprecated

    /// Initialize a new `OCKContact` with a user-defined id, a name, and an optional care plan version ID.
    ///
    /// - Parameters:
    ///   - id: A user-defined id
    ///   - name: The contact's name
    ///   - carePlanUUID: The UUID of the care plan with which this contact is associated.
    public init(id: String, name: PersonNameComponents, carePlanUUID: UUID?) {
        self.id = id
        self.name = name
        self.carePlanUUID = carePlanUUID
        self.effectiveDate = Date()
        self.timezone = TimeZone.current
    }

    /// Initialize a new `OCKContact` with a user-defined id, a name, and an optional care plan version ID.
    ///
    /// - Parameters:
    ///   - id: A user-defined id
    ///   - name: The contact's name
    ///   - carePlanID: The local database id of the careplan with which this contact is associated.
    public init(id: String, givenName: String, familyName: String, carePlanUUID: UUID?) {
        self.name = PersonNameComponents()
        self.name.givenName = givenName
        self.name.familyName = familyName
        self.id = id
        self.carePlanUUID = carePlanUUID
        self.effectiveDate = Date()
        self.timezone = TimeZone.current
    }

    public func belongs(to plan: OCKAnyCarePlan) -> Bool {
        guard let plan = plan as? OCKCarePlan, let planUUID = plan.uuid else { return false }
        return carePlanUUID == planUUID
    }
}

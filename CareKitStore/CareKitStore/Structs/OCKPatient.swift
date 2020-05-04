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

/// Represents a patient
public struct OCKPatient: Codable, Equatable, Identifiable, OCKAnyPatient, OCKVersionedObjectCompatible {

    // MARK: OCKAnyPatient
    public let id: String
    public var name: PersonNameComponents
    public var sex: OCKBiologicalSex?
    public var birthday: Date?
    public var allergies: [String]?

    // MARK: OCKVersionedObjectCompatible
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
    public var source: String?
    public var userInfo: [String: String]?
    public var asset: String?
    public var notes: [OCKNote]?
    public var timezone: TimeZone

    /// Initialize a patient with an id, a first name, and a last name.
    ///
    /// - Parameters:
    ///   - id: A user-defined id unique to this patient.
    ///   - givenName: The patient's given name.
    ///   - familyName: The patient's family name.
    public init(id: String, givenName: String, familyName: String) {
        var components = PersonNameComponents()
        components.givenName = givenName
        components.familyName = familyName
        self.name = components
        self.id = id
        self.effectiveDate = Date()
        self.timezone = TimeZone.current
    }

    /// Initialize a new patient with an id and a name.
    ///
    /// - Parameters:
    ///   - id: A user-defined id unique to this patient.
    ///   - name: The name components for the patient's name.
    public init(id: String, name: PersonNameComponents) {
        self.name = name
        self.id = id
        self.effectiveDate = Date()
        self.timezone = TimeZone.current
    }

    /// The patient's age in years, as of the current date.
    public var age: Int? {
        guard let birthday = birthday else { return nil }
        return Calendar.current.dateComponents(Set([.year]), from: birthday, to: Date()).year
    }
}

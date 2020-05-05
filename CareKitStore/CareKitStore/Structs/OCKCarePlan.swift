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

/// An `OCKCarePlan` represents a set of tasks, including both interventions and assesments, that a patient is supposed to complete as part of his
/// or her treatment for a specific condition. For example, a care plan for obesity may include tasks requiring the patient to exercise, record their
/// weight, and log meals. As the care plan evolves with the patient's progress, the care provider may modify the exercises and include notes each
/// time about why the changes were made.
public struct OCKCarePlan: Codable, Equatable, Identifiable, OCKAnyCarePlan, OCKVersionedObjectCompatible {

    /// The UUID of the patient to whom this care plan belongs.
    public var patientUUID: UUID?

    // MARK: OCKAnyCarePlan
    public let id: String
    public var title: String

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

    /// Initialize a care plan with a title, id, and optional patient version.
    ///
    /// - Parameters:
    ///   - id: A user-defined id for the care plane.
    ///   - title: A title for the care plan.
    ///   - patientUUID: The UUID of the patient to whom this care plan belongs.
    public init(id: String, title: String, patientUUID: UUID?) {
        self.title = title
        self.id = id
        self.patientUUID = patientUUID
        self.effectiveDate = Date()
        self.timezone = TimeZone.current
    }

    public func belongs(to patient: OCKAnyPatient) -> Bool {
        guard let other = patient as? OCKPatient, let otherUUID = other.uuid else { return false }
        return patientUUID == otherUUID
    }
}

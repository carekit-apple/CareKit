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

/// An `OCKTask` represents some task or action that a patient is supposed to perform. Tasks are optionally associable with an `OCKCarePlan`
/// and must have a unique identifier and schedule. The schedule determines when and how often the task should be performed, and the
/// `impactsAdherence` flag may be used to specify whether or not the patients adherence to this task will affect their daily completion rings.
public struct OCKTask: Codable, Equatable, OCKVersionSettable, OCKObjectCompatible, OCKTaskConvertible {
    /// The version ID in the local database of the care plan to which this task belongs.
    public var carePlanID: OCKLocalVersionID?

    /// A title that will be used to represent this care plan to the patient.
    public var title: String?

    /// Instructions about how this task should be performed.
    public var instructions: String?

    /// If true, completion of this task will be factored into the patient's overall adherence. True by default.
    public var impactsAdherence = true

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
    public var source: String?
    public var schedule: OCKSchedule
    public var userInfo: [String: String]?
    public var asset: String?
    public var notes: [OCKNote]?

    /// Instantiate a new `OCKCarePlan`
    ///
    /// - Parameters:
    ///   - identifier: A unique identifier for this care plan chosen by the developer.
    ///   - title: A title that will be used to represent this care plan to the patient.
    ///   - carePlanID: The versioned ID in the local database of the care plan that this task belongs to.
    ///   - schedule: A schedule specifying when this task is to be completed.
    public init(identifier: String, title: String?, carePlanID: OCKLocalVersionID?, schedule: OCKSchedule) {
        self.identifier = identifier
        self.title = title
        self.carePlanID = carePlanID
        self.schedule = schedule
        self.effectiveDate = schedule.start
    }

    public init(_ value: OCKTask) {
        self = value
    }

    public func convert() -> OCKTask {
        return self
    }
}

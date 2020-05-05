/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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

/// Holds one of several possible modified entities.
public enum OCKEntity: Equatable, Codable {

    /// A patient entity.
    case patient(OCKPatient)

    /// A care plan entity.
    case carePlan(OCKCarePlan)

    /// A contact entity.
    case contact(OCKContact)

    /// A task entity.
    case task(OCKTask)

    /// An outcome entity.
    case outcome(OCKOutcome)

    /// The type of the contained entity.
    public var entityType: EntityType {
        switch self {
        case .patient: return .patient
        case .carePlan: return .carePlan
        case .contact: return .contact
        case .task: return .task
        case .outcome: return .outcome
        }
    }

    var uuid: UUID? {
        switch self {
        case let .patient(patient): return patient.uuid
        case let .carePlan(plan): return plan.uuid
        case let .contact(contact): return contact.uuid
        case let .task(task): return task.uuid
        case let .outcome(outcome): return outcome.uuid
        }
    }

    var value: OCKObjectCompatible {
        switch self {
        case let .patient(patient): return patient
        case let .carePlan(plan): return plan
        case let .contact(contact): return contact
        case let .task(task): return task
        case let .outcome(outcome): return outcome
        }
    }

    var deletedDate: Date? {
        switch self {
        case .patient, .carePlan, .contact: fatalError("Not implemented.")
        case let .task(task): return task.deletedDate
        case let .outcome(outcome): return outcome.deletedDate
        }
    }

    private enum Keys: CodingKey {
        case type
        case object
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        switch try container.decode(EntityType.self, forKey: .type) {
        case .patient: self = .patient(try container.decode(OCKPatient.self, forKey: .object))
        case .carePlan: self = .carePlan(try container.decode(OCKCarePlan.self, forKey: .object))
        case .contact: self = .contact(try container.decode(OCKContact.self, forKey: .object))
        case .task: self = .task(try container.decode(OCKTask.self, forKey: .object))
        case .outcome: self = .outcome(try container.decode(OCKOutcome.self, forKey: .object))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(entityType, forKey: .type)
        switch self {
        case let .patient(patient): try container.encode(patient, forKey: .object)
        case let .carePlan(plan): try container.encode(plan, forKey: .object)
        case let .contact(contact): try container.encode(contact, forKey: .object)
        case let .task(task): try container.encode(task, forKey: .object)
        case let .outcome(outcome): try container.encode(outcome, forKey: .object)
        }
    }

    /// Describes the types of entities that may be included in a revision record.
    public enum EntityType: String, Equatable, Codable, CodingKey, CaseIterable {

        /// The patient entity type
        case patient

        /// The care plan entity type
        case carePlan

        /// The contact entity type
        case contact

        /// The task entity type.
        case task

        /// The outcome entity type.
        case outcome
    }
}

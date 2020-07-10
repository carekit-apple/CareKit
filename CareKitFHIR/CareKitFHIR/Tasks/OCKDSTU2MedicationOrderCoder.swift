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
import Foundation
import ModelsDSTU2

extension ModelsDSTU2.MedicationOrder: OCKFHIRResource {
    public typealias Release = DSTU2
}

/// Converts a FHIR DSTU2 `MedicationOrder` to an `OCKTask`.
///
/// The mapping is predefined to use reasonable defaults, but it is possible to configure
/// the behavior by setting properties on `OCKDSTU2MedicationOrderCoder`.
public struct OCKDSTU2MedicationOrderCoder: OCKTaskConverterTraits {

    public typealias Resource = ModelsDSTU2.MedicationOrder
    public typealias Entity = OCKTask

    public init() {}

    // MARK: Convert FHIR MedicationOrder to OCKTask

    public var getCareKitID: (Resource) throws -> String = { medicationOrder in
        guard let id = medicationOrder.id?.value?.string else {
            throw OCKFHIRCodingError.missingRequiredField("id")
        }
        return id
    }

    public var getCareKitTitle: (Resource) throws -> String? = { medicationOrder in
        switch medicationOrder.medication {
        case let .codeableConcept(concept):
            return concept.text?.value?.string
        case let .reference(reference):
            return reference.id?.value?.string
        }
    }

    public var getCareKitInstructions: (Resource) throws -> String? = { medicationOrder in
        medicationOrder.dosageInstruction?.first?.text?.value?.string
    }

    public var getCareKitSchedule: (Resource) throws -> OCKSchedule = { medicationOrder in
        guard let timing = medicationOrder.dosageInstruction?.first?.timing else {
            throw OCKFHIRCodingError.missingRequiredField("schedule")
        }
        return try OCKDSTU2ScheduleCoder().convert(resource: timing)
    }

    // MARK: Convert OCKTask to FHIR MedicationOrder

    public var setFHIRID: (String, Resource) throws -> Void = { id, medicationOrder in
        medicationOrder.id = FHIRPrimitive(FHIRString(id))
    }

    public var setFHIRTitle: (String?, Resource) throws -> Void = { title, medicationOrder in
        guard let title = title else { return }

        if case let .codeableConcept(concept) = medicationOrder.medication {
            concept.text = FHIRPrimitive(FHIRString(title))
            medicationOrder.medication = .codeableConcept(concept)
        } else {
            let concept = CodeableConcept()
            concept.text = FHIRPrimitive(FHIRString(title))
            medicationOrder.medication = .codeableConcept(concept)
        }
    }

    public var setFHIRInstructions: (String?, Resource) throws -> Void = { instructions, medicationOrder in
        guard let instructions = instructions else { return }
        // Arrays in FHIR are not allowed to be empty, so if it is non-nil, then it must have at least 1 element.
        medicationOrder.dosageInstruction = medicationOrder.dosageInstruction ?? [MedicationOrderDosageInstruction()]
        medicationOrder.dosageInstruction![0].text = instructions.fhirString()
    }

    public var setFHIRSchedule: (OCKSchedule, Resource) throws -> Void = { schedule, medicationOrder in
        // Arrays in FHIR are not allowed to be empty, so if it is non-nil, then it must have at least 1 element.
        medicationOrder.dosageInstruction = medicationOrder.dosageInstruction ?? [MedicationOrderDosageInstruction()]
        medicationOrder.dosageInstruction![0].timing = try OCKDSTU2ScheduleCoder().convert(entity: schedule)
    }

    func newResource() -> Resource {
        MedicationOrder(medication: .codeableConcept(CodeableConcept())) }
}

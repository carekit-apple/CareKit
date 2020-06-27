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

extension ModelsDSTU2.Patient: OCKFHIRResource {
    public typealias Release = DSTU2
}

/// Converts a FHIR DSTU2 `Patient` to an `OCKPatient`.
///
/// The mapping is predefined to use reasonable defaults, but it is possible to configure
/// the behavior by setting properties on `OCKDSTU2PatientCoder`.
public struct OCKDSTU2PatientCoder: OCKPatientConverterTraits {

    public typealias Resource = ModelsDSTU2.Patient
    public typealias Release = Resource.Release
    public typealias Entity = OCKPatient

    /// Initialize an `OCKDSTU2PatientCoder` that uses default mappings between FHIR and
    /// CareKit patient models.
    public init() {}

    // MARK: Convert FHIR Patient to OCKPatient

    public var getId: (Patient) throws -> String = {
        guard let id = $0.id?.string else {
            throw OCKConversionError.missingRequiredField("id")
        }
        return id
    }

    public var getName: (Patient) throws -> PersonNameComponents = {
        guard let fhirName = $0.name?.first else {
            throw OCKConversionError.missingRequiredField("name")
        }
        var components = PersonNameComponents()
        components.familyName = fhirName.family?.first?.string
        components.givenName = fhirName.given?.first?.string
        components.namePrefix = fhirName.prefix?.first?.string
        components.nameSuffix = fhirName.suffix?.first?.string
        return components
    }

    public var getSex: (Patient) throws -> OCKBiologicalSex? = {
        switch $0.gender {
        case .male: return .male
        case .female: return .female
        case .other: return .other("other")
        case .unknown: return nil
        case .none: return nil
        }
    }

    public var getBirthday: (Patient) throws -> Date? = {
        guard
            let birthday = $0.birthDate,
            let day = birthday.day,
            let month = birthday.month
        else { return nil }

        var components = DateComponents()
        components.year = birthday.year
        components.month = Int(month)
        components.day = Int(day)

        return Calendar.current.date(from: components)
    }

    public var getAllergies: (Patient) throws -> [String]? = { _ in
        nil
    }

    // MARK: Convert OCKPatient to FHIR Patient

    func newResource() -> Resource {
        Patient()
    }

    public var putId: (String, Patient) throws -> Void = { id, patient in
        patient.id = FHIRString(id)
    }

    public var putName: (PersonNameComponents, Patient) throws -> Void = { name, patient in
        let humanName = HumanName()
        humanName.family = name.familyName == nil ? [] : [name.familyName!.fhirString()]
        humanName.given = name.givenName == nil ? [] : [name.givenName!.fhirString()]
        humanName.prefix = name.namePrefix == nil ? [] : [name.namePrefix!.fhirString()]
        humanName.suffix = name.nameSuffix == nil ? [] : [name.nameSuffix!.fhirString()]

        patient.name = [humanName]
    }
}

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

@testable import CareKitFHIR
import CareKitStore
import ModelsR4
import XCTest

class R4PatientConverterTests: XCTestCase {

    // MARK: Convert FHIR Patient to OCKPatient

    func testConvertFHIRPatientFailsWhenMissingID() {
        let patient = Patient()
        let converter = OCKR4PatientCoder()
        let expectedError: OCKFHIRCodingError = .missingRequiredField("id")
        XCTAssertThrowsError(try converter.convert(resource: patient), matching: expectedError)
    }

    func testConvertFHIRPatientSucceedsForDefaultIDGetter() throws {
        let patient = Patient()
        patient.name = [HumanName()]
        patient.id = "abc"

        let converter = OCKR4PatientCoder()
        let converted = try converter.convert(resource: patient)
        XCTAssert(converted.id == "abc")
    }

    func testConvertFHIRPatientSetsPatientSourceToFHIR() throws {
        let patient = Patient()
        patient.name = [HumanName()]
        patient.id = "abc"

        let converter = OCKR4PatientCoder()
        let converted = try converter.convert(resource: patient)
        XCTAssert(converted.source == "FHIR")
    }

    func testConvertFHIRPatientSucceedsForCustomIDGetter() throws {
        let identifier = Identifier()
        identifier.value = "abc"

        let patient = Patient()
        patient.identifier = [identifier]
        patient.name = [HumanName()]

        var converter = OCKR4PatientCoder()
        converter.getCareKitID = { $0.identifier!.first!.value!.value!.string }

        let converted = try converter.convert(resource: patient)
        XCTAssert(converted.id == "abc")
    }

    func testConvertFHIRPatientSucceedsForDefaultNameGetter() throws {
        let patient = Patient()
        patient.id = "abc"
        patient.name = [HumanName(family: "Bill", given: ["Bob"])]

        let converter = OCKR4PatientCoder()
        let converted = try converter.convert(resource: patient)
        XCTAssert(converted.name.familyName == "Bill")
        XCTAssert(converted.name.givenName == "Bob")
    }

    func testConvertFHIRPatientSucceedsForDefaultSexGetter() throws {
        let patient = Patient()
        patient.id = "abc"
        patient.name = [HumanName()]
        patient.gender = FHIRPrimitive(AdministrativeGender.other)

        let converter = OCKR4PatientCoder()
        let converted = try converter.convert(resource: patient)
        XCTAssert(converted.sex == .other("other"))
    }

    func testConvertFHIRPatientSucceedsForDefaultBirthdayGetter() throws {
        let components = Calendar.current.dateComponents(Set([.year, .month, .day]), from: Date())
        let birthday = Calendar.current.date(from: components)!

        let patient = Patient()
        patient.id = "abc"
        patient.name = [HumanName()]
        patient.birthDate = FHIRPrimitive(FHIRDate(
            year: Calendar.current.component(.year, from: birthday),
            month: UInt8(Calendar.current.component(.month, from: birthday)),
            day: UInt8(Calendar.current.component(.day, from: birthday))
        ))

        let converter = OCKR4PatientCoder()
        let converted = try converter.convert(resource: patient)
        XCTAssert(converted.birthday == birthday)
    }

    // MARK: Convert OCKPatient to FHIR Patient

    func testConvertCareKitPatientSucceedsForDefaultIDSetter() throws {
        var name = PersonNameComponents()
        name.familyName = "A"
        name.givenName = "B"
        name.namePrefix = "C"
        name.nameSuffix = "D"

        let careKitPatient = OCKPatient(id: "123", name: name)
        let converter = OCKR4PatientCoder()
        let fhirPatient = try converter.convert(entity: careKitPatient)

        XCTAssert(fhirPatient.name?.first?.family == "A")
        XCTAssert(fhirPatient.name?.first?.given == ["B"])
        XCTAssert(fhirPatient.name?.first?.prefix == ["C"])
        XCTAssert(fhirPatient.name?.first?.suffix == ["D"])
    }
}

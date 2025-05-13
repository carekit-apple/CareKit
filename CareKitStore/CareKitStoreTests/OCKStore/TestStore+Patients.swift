/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
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

@testable import CareKitStore
import Foundation
import XCTest

class TestStorePatients: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }

    // MARK: Relationship Validation

    // MARK: Insertion

    func testAddPatient() throws {
        let patient = try store.addPatientAndWait(OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost"))
        XCTAssertNotNil(patient.uuid)
        XCTAssertNotNil(patient.schemaVersion)
    }

    func testAddPatientForAnyPatientBeyondTheFirstPatient() throws {
        let patient1 = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        let patient2 = OCKPatient(id: "id2", givenName: "Christopher", familyName: "Foss")
        try store.addPatientAndWait(patient1)
        XCTAssertThrowsError(try store.addPatientAndWait(patient2))
    }

    func testAddPatientFailsIfIdentifierAlreadyExists() throws {
        let patient1 = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        let patient2 = OCKPatient(id: "myID", givenName: "Jared", familyName: "Gosler")
        try store.addPatientAndWait(patient1)
        XCTAssertThrowsError(try store.addPatientAndWait(patient2))
    }

    // MARK: Querying

    func testPatientQueryGroupIdentifierFiltersOutPatients() throws {
        let patient = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.groupIdentifiers = ["children"]
        let fetched = try store.fetchPatientsAndWait(query: query)
        XCTAssert(fetched.isEmpty)
    }

    func testPatientQueryGroupIdentifierIncludesPatients() throws {
        var patient = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        patient.groupIdentifier = "children"
        try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.groupIdentifiers = ["children"]
        let fetched = try store.fetchPatientsAndWait(query: query)
        XCTAssert(!fetched.isEmpty)
    }

    func testPatientQueryTagIncludesPatient() throws {
        var patient = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        patient.tags = ["A", "B"]
        try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.tags = ["B", "C"]
        let fetched = try store.fetchPatientsAndWait(query: query)
        XCTAssert(!fetched.isEmpty)
    }

    func testPatientQueryTagExcludesPatient() throws {
        var patient = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        patient.tags = ["A", "B"]
        try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.tags = ["C"]
        let fetched = try store.fetchPatientsAndWait(query: query)
        XCTAssert(fetched.isEmpty)
    }

    func testPatientQueryWithNilIdentifiersReturnsAllPatients() throws {
        let patientA = OCKPatient(id: "A", givenName: "Amy", familyName: "Frost")
        let patientB = OCKPatient(id: "B", givenName: "Christopher", familyName: "Foss")
        let patientC = OCKPatient(id: "C", givenName: "Jared", familyName: "Gosler")
        let patientD = OCKPatient(id: "D", givenName: "Joyce", familyName: "Sohn")
        let patientE = OCKPatient(id: "E", givenName: "Lauren", familyName: "Trottier")
        let patientF = OCKPatient(id: "F", givenName: "Mariana", familyName: "Lin")
        try store.addPatientsAndWait([patientA, patientB, patientC, patientD, patientE, patientF])
        let patients = try store.fetchPatientsAndWait(query: OCKPatientQuery())
        XCTAssertEqual(patients.count, 6)
    }

    func testQueryPatientByRemoteID() throws {
        var patient = OCKPatient(id: "A", givenName: "B", familyName: "C")
        patient.remoteID = "abc"
        patient = try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.remoteIDs = ["abc"]
        let fetched = try store.fetchPatientsAndWait(query: query).first
        XCTAssertEqual(fetched, patient)
    }

    func testBiologicalSexIsPersistedCorrectly() throws {
        var patient = OCKPatient(id: "A", givenName: "Amy", familyName: "Frost")
        patient.sex = .female
        patient = try store.addPatientAndWait(patient)
        patient = try store.fetchPatientAndWait(id: "A")
        XCTAssertEqual(patient.sex, .female)
    }

    func testBirthdayIsPersistedCorrectly() throws {
        let now = Date()
        var patient = OCKPatient(id: "A", givenName: "Amy", familyName: "Frost")
        patient.birthday = now
        patient = try store.addPatientAndWait(patient)
        patient = try store.fetchPatientAndWait(id: "A")
        XCTAssertEqual(patient.birthday, now)
    }

    func testAllergiesArePersistedCorrectly() throws {
        var patient = OCKPatient(id: "A", givenName: "Amy", familyName: "Frost")
        patient.allergies = ["A", "B", "C"]
        patient = try store.addPatientAndWait(patient)
        patient = try store.fetchPatientAndWait(id: "A")
        XCTAssertEqual(patient.allergies, ["A", "B", "C"])
    }

    // MARK: Versioning

    func testUpdatePatientCreatesNewVersion() throws {
        let patient = try store.addPatientAndWait(OCKPatient(id: "myID", givenName: "Chris", familyName: "Saari"))
        let updatedPatient = try store.updatePatientAndWait(OCKPatient(id: "myID", givenName: "Chris", familyName: "Sillers"))
        XCTAssertEqual(updatedPatient.name.familyName, "Sillers")
        XCTAssertEqual(updatedPatient.previousVersionUUIDs.first, patient.uuid)
    }

    func testUpdateFailsForUnsavedPatient() {
        XCTAssertThrowsError(try store.updatePatientAndWait(OCKPatient(id: "myID", givenName: "Christoper", familyName: "Foss")))
    }

    func testPatientQueryWithNoDateOnlyReturnsLatestVersionOfAPatient() throws {
        let versionA = try store.addPatientAndWait(OCKPatient(id: "A", givenName: "Jared", familyName: "Gosler"))
        let versionB = try store.updatePatientAndWait(OCKPatient(id: "A", givenName: "John", familyName: "Appleseed"))
        let fetched = try store.fetchPatientAndWait(id: versionA.id)
        XCTAssertEqual(fetched, versionB)
    }

    func testPatientQueryOnPastDateReturnsPastVersionOfAPatient() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKPatient(id: "A", givenName: "Jared", familyName: "Gosler")
        versionA.effectiveDate = dateA
        versionA = try store.addPatientAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKPatient(id: "A", givenName: "John", familyName: "Appleseed")
        versionB.effectiveDate = dateB
        versionB = try store.updatePatientAndWait(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        var query = OCKPatientQuery(dateInterval: interval)
        query.ids = ["A"]

        let fetched = try store.fetchPatientsAndWait(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, versionA.name)
    }

    func testPatientQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKPatient(id: "A", givenName: "Jared", familyName: "Gosler")
        versionA.effectiveDate = dateA
        versionA = try store.addPatientAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKPatient(id: "A", givenName: "John", familyName: "Appleseed")
        versionB.effectiveDate = dateB
        versionB = try store.updatePatientAndWait(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        var query = OCKPatientQuery(dateInterval: interval)
        query.ids = ["A"]

        let fetched = try store.fetchPatientsAndWait(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, versionB.name)
    }

    func testPatientQueryBeforePatientWasCreatedReturnsNoResults() throws {
        let dateA = Date()
        try store.addPatientAndWait(OCKPatient(id: "A", givenName: "Jared", familyName: "Gosler"))

        let interval = DateInterval(start: dateA.addingTimeInterval(-100), end: dateA)
        var query = OCKPatientQuery(dateInterval: interval)
        query.ids = ["A"]

        let fetched = try store.fetchPatientsAndWait(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: Deletion

    func testDeletePatient() throws {
        let patient = try store.addPatientAndWait(OCKPatient(id: "myID", givenName: "John", familyName: "Appleseed"))
        try store.deletePatientAndWait(patient)
        let fetched = try store.fetchPatientsAndWait(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeletePatientFailsIfPatientDoesntExist() {
        XCTAssertThrowsError(try store.deletePatientAndWait(OCKPatient(id: "myID", givenName: "John", familyName: "Appleseed")))
    }
}

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

    func testAddPatient() async throws {
        let patient = try await store.addPatient(OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost"))
        XCTAssertNotNil(patient.uuid)
        XCTAssertNotNil(patient.schemaVersion)
    }

    func testAddPatientForAnyPatientBeyondTheFirstPatient() async throws {
        let patient1 = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        let patient2 = OCKPatient(id: "id2", givenName: "Christopher", familyName: "Foss")
        try await store.addPatient(patient1)

        do {
            try await store.addPatient(patient2)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testAddPatientFailsIfIdentifierAlreadyExists() async throws {
        let patient1 = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        let patient2 = OCKPatient(id: "myID", givenName: "Jared", familyName: "Gosler")
        try await store.addPatient(patient1)

        do {
            try await store.addPatient(patient2)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    // MARK: Querying

    func testPatientQueryGroupIdentifierFiltersOutPatients() async throws {
        let patient = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        try await store.addPatient(patient)
        var query = OCKPatientQuery(for: Date())
        query.groupIdentifiers = ["children"]
        let fetched = try await store.fetchPatients(query: query)
        XCTAssert(fetched.isEmpty)
    }

    func testPatientQueryGroupIdentifierIncludesPatients() async throws {
        var patient = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        patient.groupIdentifier = "children"
        try await store.addPatient(patient)
        var query = OCKPatientQuery(for: Date())
        query.groupIdentifiers = ["children"]
        let fetched = try await store.fetchPatients(query: query)
        XCTAssert(!fetched.isEmpty)
    }

    func testPatientQueryTagIncludesPatient() async throws {
        var patient = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        patient.tags = ["A", "B"]
        try await store.addPatient(patient)
        var query = OCKPatientQuery(for: Date())
        query.tags = ["B", "C"]
        let fetched = try await store.fetchPatients(query: query)
        XCTAssert(!fetched.isEmpty)
    }

    func testPatientQueryTagExcludesPatient() async throws {
        var patient = OCKPatient(id: "myID", givenName: "Amy", familyName: "Frost")
        patient.tags = ["A", "B"]
        try await store.addPatient(patient)
        var query = OCKPatientQuery(for: Date())
        query.tags = ["C"]
        let fetched = try await store.fetchPatients(query: query)
        XCTAssert(fetched.isEmpty)
    }

    func testPatientQueryWithNilIdentifiersReturnsAllPatients() async throws {
        let patientA = OCKPatient(id: "A", givenName: "Amy", familyName: "Frost")
        let patientB = OCKPatient(id: "B", givenName: "Christopher", familyName: "Foss")
        let patientC = OCKPatient(id: "C", givenName: "Jared", familyName: "Gosler")
        let patientD = OCKPatient(id: "D", givenName: "Joyce", familyName: "Sohn")
        let patientE = OCKPatient(id: "E", givenName: "Lauren", familyName: "Trottier")
        let patientF = OCKPatient(id: "F", givenName: "Mariana", familyName: "Lin")
        try await store.addPatients([patientA, patientB, patientC, patientD, patientE, patientF])
        let patients = try await store.fetchPatients(query: OCKPatientQuery())
        XCTAssertEqual(patients.count, 6)
    }

    func testQueryPatientByRemoteID() async throws {
        var patient = OCKPatient(id: "A", givenName: "B", familyName: "C")
        patient.remoteID = "abc"
        patient = try await store.addPatient(patient)
        var query = OCKPatientQuery(for: Date())
        query.remoteIDs = ["abc"]
        let fetched = try await store.fetchPatients(query: query).first
        XCTAssertEqual(fetched, patient)
    }

    func testBiologicalSexIsPersistedCorrectly() async throws {
        var patient = OCKPatient(id: "A", givenName: "Amy", familyName: "Frost")
        patient.sex = .female
        patient = try await store.addPatient(patient)
        patient = try await store.fetchPatient(withID: "A")
        XCTAssertEqual(patient.sex, .female)
    }

    func testBirthdayIsPersistedCorrectly() async throws {
        let now = Date()
        var patient = OCKPatient(id: "A", givenName: "Amy", familyName: "Frost")
        patient.birthday = now
        patient = try await store.addPatient(patient)
        patient = try await store.fetchPatient(withID: "A")
        XCTAssertEqual(patient.birthday, now)
    }

    func testAllergiesArePersistedCorrectly() async throws {
        var patient = OCKPatient(id: "A", givenName: "Amy", familyName: "Frost")
        patient.allergies = ["A", "B", "C"]
        patient = try await store.addPatient(patient)
        patient = try await store.fetchPatient(withID: "A")
        XCTAssertEqual(patient.allergies, ["A", "B", "C"])
    }

    // MARK: Versioning

    func testUpdatePatientCreatesNewVersion() async throws {
        let patient = try await store.addPatient(OCKPatient(id: "myID", givenName: "Chris", familyName: "Saari"))
        let updatedPatient = try await store.updatePatient(OCKPatient(id: "myID", givenName: "Chris", familyName: "Sillers"))
        XCTAssertEqual(updatedPatient.name.familyName, "Sillers")
        XCTAssertEqual(updatedPatient.previousVersionUUIDs.first, patient.uuid)
    }

    func testUpdateFailsForUnsavedPatient() async {
        do {
            try await store.updatePatient(OCKPatient(id: "myID", givenName: "Christoper", familyName: "Foss"))
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testPatientQueryWithNoDateOnlyReturnsLatestVersionOfAPatient() async throws {
        let versionA = try await store.addPatient(OCKPatient(id: "A", givenName: "Jared", familyName: "Gosler"))
        let versionB = try await store.updatePatient(OCKPatient(id: "A", givenName: "John", familyName: "Appleseed"))
        let fetched = try await store.fetchPatient(withID: versionA.id)
        XCTAssertEqual(fetched, versionB)
    }

    func testPatientQueryOnPastDateReturnsPastVersionOfAPatient() async throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKPatient(id: "A", givenName: "Jared", familyName: "Gosler")
        versionA.effectiveDate = dateA
        versionA = try await store.addPatient(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKPatient(id: "A", givenName: "John", familyName: "Appleseed")
        versionB.effectiveDate = dateB
        versionB = try await store.updatePatient(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        var query = OCKPatientQuery(dateInterval: interval)
        query.ids = ["A"]

        let fetched = try await store.fetchPatients(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, versionA.name)
    }

    func testPatientQuerySpanningVersionsReturnsNewestVersionOnly() async throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKPatient(id: "A", givenName: "Jared", familyName: "Gosler")
        versionA.effectiveDate = dateA
        versionA = try await store.addPatient(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKPatient(id: "A", givenName: "John", familyName: "Appleseed")
        versionB.effectiveDate = dateB
        versionB = try await store.updatePatient(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        var query = OCKPatientQuery(dateInterval: interval)
        query.ids = ["A"]

        let fetched = try await store.fetchPatients(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, versionB.name)
    }

    func testPatientQueryBeforePatientWasCreatedReturnsNoResults() async throws {
        let dateA = Date()
        try await store.addPatient(OCKPatient(id: "A", givenName: "Jared", familyName: "Gosler"))

        let interval = DateInterval(start: dateA.addingTimeInterval(-100), end: dateA)
        var query = OCKPatientQuery(dateInterval: interval)
        query.ids = ["A"]

        let fetched = try await store.fetchPatients(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: Deletion

    func testDeletePatient() async throws {
        let patient = try await store.addPatient(OCKPatient(id: "myID", givenName: "John", familyName: "Appleseed"))
        try await store.deletePatient(patient)
        let fetched = try await store.fetchPatients(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeletePatientFailsIfPatientDoesntExist() async {
        do {
            try await store.deletePatient(OCKPatient(id: "myID", givenName: "John", familyName: "Appleseed"))
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }
}

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

@testable import CareKitStore
import Foundation
import XCTest

class TestStorePatients: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "TestDatabase", type: .inMemory)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    // MARK: Relationship Validation

    // MARK: Insertion

    func testAddPatient() throws {
        let patient = try store.addPatientAndWait(OCKPatient(identifier: "myID", givenName: "Amy", familyName: "Frost"))
        XCTAssertNotNil(patient.localDatabaseID)
        XCTAssertNotNil(patient.schemaVersion)
    }

    func testAddPatientForAnyPatientBeyondTheFirstPatient() throws {
        let patient1 = OCKPatient(identifier: "id1", givenName: "Amy", familyName: "Frost")
        let patient2 = OCKPatient(identifier: "id2", givenName: "Christopher", familyName: "Foss")
        try store.addPatientAndWait(patient1)
        XCTAssertThrowsError(try store.addPatientAndWait(patient2))
    }

    func testAddPatientFailsIfIdentifierAlreadyExists() throws {
        let patient1 = OCKPatient(identifier: "myID", givenName: "Amy", familyName: "Frost")
        let patient2 = OCKPatient(identifier: "myID", givenName: "Jared", familyName: "Gosler")
        try store.addPatientAndWait(patient1)
        XCTAssertThrowsError(try store.addPatientAndWait(patient2))
    }

    // MARK: Querying

    func testPatientQueryGroupIdentifierFiltersOutPatients() throws {
        let patient = OCKPatient(identifier: "myID", givenName: "Amy", familyName: "Frost")
        try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.groupIdentifiers = ["children"]
        let fetched = try store.fetchPatientsAndWait(nil, query: query)
        XCTAssert(fetched.isEmpty)
    }

    func testPatientQueryGroupIdentifierIncludesPatients() throws {
        var patient = OCKPatient(identifier: "myID", givenName: "Amy", familyName: "Frost")
        patient.groupIdentifier = "children"
        try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.groupIdentifiers = ["children"]
        let fetched = try store.fetchPatientsAndWait(nil, query: query)
        XCTAssert(!fetched.isEmpty)
    }

    func testPatientQueryTagIncludesPatient() throws {
        var patient = OCKPatient(identifier: "myID", givenName: "Amy", familyName: "Frost")
        patient.tags = ["A", "B"]
        try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.tags = ["B", "C"]
        let fetched = try store.fetchPatientsAndWait(nil, query: query)
        XCTAssert(!fetched.isEmpty)
    }

    func testPatientQueryTagExcludesPatient() throws {
        var patient = OCKPatient(identifier: "myID", givenName: "Amy", familyName: "Frost")
        patient.tags = ["A", "B"]
        try store.addPatientAndWait(patient)
        var query = OCKPatientQuery(for: Date())
        query.tags = ["C"]
        let fetched = try store.fetchPatientsAndWait(nil, query: query)
        XCTAssert(fetched.isEmpty)
    }

    func testPatientQueryWithNilIdentifiersReturnsAllPatients() throws {
        let patientA = OCKPatient(identifier: "A", givenName: "Amy", familyName: "Frost")
        let patientB = OCKPatient(identifier: "B", givenName: "Christopher", familyName: "Foss")
        let patientC = OCKPatient(identifier: "C", givenName: "Jared", familyName: "Gosler")
        let patientD = OCKPatient(identifier: "D", givenName: "Joyce", familyName: "Sohn")
        let patientE = OCKPatient(identifier: "E", givenName: "Lauren", familyName: "Trottier")
        let patientF = OCKPatient(identifier: "F", givenName: "Mariana", familyName: "Lin")
        try store.addPatientsAndWait([patientA, patientB, patientC, patientD, patientE, patientF])
        let patients = try store.fetchPatientsAndWait()
        XCTAssert(patients.count == 6)
    }

    func testQueryPatientByRemoteID() throws {
        var patient = OCKPatient(identifier: "A", givenName: "B", familyName: "C")
        patient.remoteID = "abc"
        patient = try store.addPatientAndWait(patient)
        let fetched = try store.fetchPatientsAndWait(.patientRemoteIDs(["abc"]), query: .today).first
        XCTAssert(fetched == patient)
    }

    func testBiologicalSexIsPersistedCorrectly() throws {
        var patient = OCKPatient(identifier: "A", givenName: "Amy", familyName: "Frost")
        patient.sex = .female
        patient = try store.addPatientAndWait(patient)
        patient = try store.fetchPatientAndWait(identifier: "A")
        XCTAssert(patient.sex == .female)
    }

    func testBirthdayIsPersistedCorrectly() throws {
        let now = Date()
        var patient = OCKPatient(identifier: "A", givenName: "Amy", familyName: "Frost")
        patient.birthday = now
        patient = try store.addPatientAndWait(patient)
        patient = try store.fetchPatientAndWait(identifier: "A")
        XCTAssert(patient.birthday == now)
    }

    func testAllergiesArePersistedCorrectly() throws {
        var patient = OCKPatient(identifier: "A", givenName: "Amy", familyName: "Frost")
        patient.allergies = ["A", "B", "C"]
        patient = try store.addPatientAndWait(patient)
        patient = try store.fetchPatientAndWait(identifier: "A")
        XCTAssert(patient.allergies == ["A", "B", "C"])
    }

    // MARK: Versioning

    func testUpdatePatientCreatesNewVersion() throws {
        let patient = try store.addPatientAndWait(OCKPatient(identifier: "myID", givenName: "Chris", familyName: "Saari"))
        let updatedPatient = try store.updatePatientAndWait(OCKPatient(identifier: "myID", givenName: "Chris", familyName: "Sillers"))
        XCTAssert(updatedPatient.name.familyName == "Sillers")
        XCTAssert(updatedPatient.previousVersionID == patient.versionID)
    }

    func testUpdatePatientWithoutVersioning() throws {
        store.configuration.updatesCreateNewVersions = false
        let patient = try store.addPatientAndWait(OCKPatient(identifier: "myID", givenName: "Chris", familyName: "Saari"))
        var updatedPatient = OCKPatient(identifier: "myID", givenName: "Chris", familyName: "Sillers")
        updatedPatient = try store.updatePatientAndWait(updatedPatient)
        XCTAssert(updatedPatient.name.familyName == "Sillers")
        XCTAssert(updatedPatient.previousVersionID == nil)
        XCTAssert(updatedPatient.versionID == patient.versionID)
    }

    func testUpdateFailsForUnsavedPatient() {
        XCTAssertThrowsError(try store.updatePatientAndWait(OCKPatient(identifier: "myID", givenName: "Christoper", familyName: "Foss")))
    }

    func testPatientQueryWithNoDateOnlyReturnsLatestVersionOfAPatient() throws {
        let versionA = try store.addPatientAndWait(OCKPatient(identifier: "A", givenName: "Jared", familyName: "Gosler"))
        let versionB = try store.updatePatientAndWait(OCKPatient(identifier: "A", givenName: "John", familyName: "Appleseed"))
        let fetched = try store.fetchPatientAndWait(identifier: versionA.identifier)
        XCTAssert(fetched == versionB)
    }

    func testPatientQueryOnPastDateReturnsPastVersionOfAPatient() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKPatient(identifier: "A", givenName: "Jared", familyName: "Gosler")
        versionA.effectiveDate = dateA
        versionA = try store.addPatientAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKPatient(identifier: "A", givenName: "John", familyName: "Appleseed")
        versionB.effectiveDate = dateB
        versionB = try store.updatePatientAndWait(versionB)

        let query = OCKPatientQuery(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let fetched = try store.fetchPatientsAndWait(.patientIdentifiers(["A"]), query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.name == versionA.name)
    }

    func testPatientQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKPatient(identifier: "A", givenName: "Jared", familyName: "Gosler")
        versionA.effectiveDate = dateA
        versionA = try store.addPatientAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKPatient(identifier: "A", givenName: "John", familyName: "Appleseed")
        versionB.effectiveDate = dateB
        versionB = try store.updatePatientAndWait(versionB)

        let query = OCKPatientQuery(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let fetched = try store.fetchPatientsAndWait(.patientIdentifiers(["A"]), query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.name == versionB.name)
    }

    func testPatientQueryBeforePatientWasCreatedReturnsNoResults() throws {
        let dateA = Date()
        try store.addPatientAndWait(OCKPatient(identifier: "A", givenName: "Jared", familyName: "Gosler"))
        let query = OCKPatientQuery(start: dateA.addingTimeInterval(-100), end: dateA)
        let fetched = try store.fetchPatientsAndWait(.patientIdentifiers(["A"]), query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: Deletion

    func testDeletePatient() throws {
        let patient = try store.addPatientAndWait(OCKPatient(identifier: "myID", givenName: "John", familyName: "Appleseed"))
        try store.deletePatientAndWait(patient)
        let fetched = try store.fetchPatientsAndWait()
        XCTAssert(fetched.isEmpty)
    }

    func testDeletePatientFailsIfPatientDoesntExist() {
        XCTAssertThrowsError(try store.deletePatientAndWait(OCKPatient(identifier: "myID", givenName: "John", familyName: "Appleseed")))
    }
}

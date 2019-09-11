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
import XCTest

class TestStoreCarePlans: XCTestCase {
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

    func testStorePreventsMissingPatientRelationshipOnCarePlans() {
        let plan = OCKCarePlan(identifier: "diabetes_type_1", title: "Diabetes Care Plan", patientID: nil)
        store.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addCarePlanAndWait(plan))
    }

    func testStoreAllowsMissingPatientRelationshipOnCarePlans() {
        let plan = OCKCarePlan(identifier: "diabetes_type_1", title: "Diabetes Care Plan", patientID: nil)
        XCTAssertNoThrow(try store.addCarePlanAndWait(plan))
    }

    // MARK: Insertion

    func testAddAndFetchCarePlans() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "6789", title: "Diabetes Care Plan", patientID: nil))
        XCTAssertNotNil(plan.localDatabaseID)
        XCTAssertNotNil(plan.schemaVersion)
    }

    func testAddCarePlanFailsIfIdentifierAlreadyExists() throws {
        let plan1 = OCKCarePlan(identifier: "id", title: "Diabetes Care Plan", patientID: nil)
        let plan2 = OCKCarePlan(identifier: "id", title: "Obesity Care Plan", patientID: nil)
        try store.addCarePlanAndWait(plan1)
        XCTAssertThrowsError(try store.addCarePlanAndWait(plan2))
    }

    // MARK: Querying

    func testCarePlanQueryGroupIdentifier() throws {
        var plan1 = OCKCarePlan(identifier: "id_1", title: "Diabetes Care Plan", patientID: nil)
        plan1.groupIdentifier = "1"
        var plan2 = OCKCarePlan(identifier: "id_2", title: "Obesity Care Plan", patientID: nil)
        plan2.groupIdentifier = "2"
        try store.addCarePlansAndWait([plan1, plan2])
        var query = OCKCarePlanQuery(for: Date())
        query.groupIdentifiers = ["1"]
        let fetched = try store.fetchCarePlansAndWait(nil, query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.identifier == "id_1")
    }

    func testCarePlanQueryLimit() throws {
        let plan1 = OCKCarePlan(identifier: "A", title: "A", patientID: nil)
        let plan2 = OCKCarePlan(identifier: "B", title: "B", patientID: nil)
        try store.addCarePlansAndWait([plan1, plan2])
        var query = OCKCarePlanQuery(for: Date())
        query.limit = 1
        let fetched = try store.fetchCarePlansAndWait(nil, query: query)
        XCTAssert(fetched.count == 1)
    }

    func testCarePlanQuerySortedOffset() throws {
        let plan1 = OCKCarePlan(identifier: "A", title: "A", patientID: nil)
        let plan2 = OCKCarePlan(identifier: "B", title: "B", patientID: nil)
        let plan3 = OCKCarePlan(identifier: "C", title: "C", patientID: nil)
        try store.addCarePlansAndWait([plan1, plan2, plan3])
        var query = OCKCarePlanQuery(for: Date())
        query.sortDescriptors = [.title(ascending: true)]
        query.offset = 2
        let fetched = try store.fetchCarePlansAndWait(nil, query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.identifier == "C")
    }

    func testCarePlanQueryWithNilQueryReturnsAllCarePlans() throws {
        let plan1 = OCKCarePlan(identifier: "1", title: "1", patientID: nil)
        let plan2 = OCKCarePlan(identifier: "2", title: "2", patientID: nil)
        let plan3 = OCKCarePlan(identifier: "3", title: "3", patientID: nil)
        try store.addCarePlansAndWait([plan1, plan2, plan3])
        let plans = try store.fetchCarePlansAndWait()
        XCTAssert(plans.count == 3)
    }

    func testCarePlanQueryTags() throws {
        var plan1 = OCKCarePlan(identifier: "A", title: "A", patientID: nil)
        plan1.tags = ["1", "2"]
        var plan2 = OCKCarePlan(identifier: "B", title: "B", patientID: nil)
        plan2.tags = ["1", "2", "3"]
        var plan3 = OCKCarePlan(identifier: "C", title: "C", patientID: nil)
        plan3.tags = ["1"]
        try store.addCarePlansAndWait([plan1, plan2, plan3])
        var query = OCKCarePlanQuery(for: Date())
        query.tags = ["2"]
        query.sortDescriptors = [.title(ascending: true)]
        let fetched = try store.fetchCarePlansAndWait(nil, query: query)
        XCTAssert(fetched.map { $0.title } == ["A", "B"])
    }

    // MARK: Versioning

    func testUpdateCarePlanCreatesNewVersion() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "bronchitis", title: "Bronchitis", patientID: nil))
        let updatedPlan = try store.updateCarePlanAndWait(OCKCarePlan(identifier: "bronchitis", title: "Bronchitis Treatment", patientID: nil))
        XCTAssert(updatedPlan.title == "Bronchitis Treatment")
        XCTAssert(updatedPlan.previousVersionID == plan.localDatabaseID)
    }

    func testUpdateCarePlanWithoutVersioning() throws {
        store.configuration.updatesCreateNewVersions = false
        var plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "bronchitis", title: "Bronchitis", patientID: nil))
        plan.title = "Bronchitis Treatment"
        let updatedPlan = try store.updateCarePlanAndWait(plan)
        XCTAssert(updatedPlan.title == "Bronchitis Treatment")
        XCTAssert(updatedPlan.localDatabaseID == plan.localDatabaseID)
    }

    func testUpdateFailsForUnsavedCarePlans() {
        XCTAssertThrowsError(try store.updateCarePlanAndWait(
            OCKCarePlan(identifier: "bronchitis", title: "Bronchitis", patientID: nil)))
    }

    func testCarePlanQueryWithNoDateOnlyReturnsLatestVersionOfACarePlan() throws {
        let versionA = try store.addCarePlanAndWait(OCKCarePlan(identifier: "A", title: "Amy", patientID: nil))
        let versionB = try store.updateCarePlanAndWait(OCKCarePlan(identifier: "A", title: "Jared", patientID: nil))
        let fetched = try store.fetchCarePlanAndWait(identifier: versionA.identifier)
        XCTAssert(fetched?.identifier == versionB.identifier)
        XCTAssert(fetched?.previousVersionID == versionA.localDatabaseID)
    }

    func testCarePlanQueryOnPastDateReturnsPastVersionOfACarePlan() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKCarePlan(identifier: "A", title: "a", patientID: nil)
        versionA.effectiveDate = dateA
        versionA = try store.addCarePlanAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKCarePlan(identifier: "A", title: "b", patientID: nil)
        versionB.effectiveDate = dateB
        versionB = try store.updateCarePlanAndWait(versionB)

        let query = OCKCarePlanQuery(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.title == versionA.title)
    }

    func testCarePlanQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKCarePlan(identifier: "A", title: "a", patientID: nil)
        versionA.effectiveDate = dateA
        versionA = try store.addCarePlanAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKCarePlan(identifier: "A", title: "b", patientID: nil)
        versionB.effectiveDate = dateB
        versionB = try store.updateCarePlanAndWait(versionB)

        let query = OCKCarePlanQuery(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.title == versionB.title)
    }

    func testCarePlanQueryBeforeCarePlansWasCreatedReturnsNoResults() throws {
        let dateA = Date()
        try store.addCarePlanAndWait(OCKCarePlan(identifier: "A", title: "a", patientID: nil))
        let query = OCKCarePlanQuery(start: dateA.addingTimeInterval(-100), end: dateA)
        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    func testQueryCarePlanByRemoteID() throws {
        var plan = OCKCarePlan(identifier: "A", title: "Plan", patientID: nil)
        plan.remoteID = "abc"
        plan = try store.addCarePlanAndWait(plan)
        let fetched = try store.fetchCarePlansAndWait(.carePlanRemoteIDs(["abc"]), query: .today).first
        XCTAssert(plan == fetched)
    }

    func testQueryCarePlanByPatientRemoteID() throws {
        var patient = OCKPatient(identifier: "A", givenName: "B", familyName: "C")
        patient.remoteID = "abc"
        patient = try store.addPatientAndWait(patient)

        var plan = OCKCarePlan(identifier: "D", title: "E", patientID: patient.versionID)
        plan = try store.addCarePlanAndWait(plan)

        let fetched = try store.fetchCarePlansAndWait(.patientRemoteIDs(["abc"]), query: .today).first
        XCTAssert(fetched == plan)
    }
    // MARK: Deletion

    func testDeleteCarePlan() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "stinky_breath", title: "Gingivitus", patientID: nil))
        try store.deleteCarePlanAndWait(plan)
        let fetched = try store.fetchCarePlansAndWait()
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteCarePlanFailsIfCarePlanDoesntExist() {
        let plan = OCKCarePlan(identifier: "stinky_breath", title: "Gingivitus", patientID: nil)
        XCTAssertThrowsError(try store.deleteCarePlanAndWait(plan))
    }
}

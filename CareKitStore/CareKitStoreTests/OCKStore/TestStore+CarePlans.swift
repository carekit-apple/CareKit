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
        let plan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        store.configuration.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addCarePlanAndWait(plan))
    }

    func testStoreAllowsMissingPatientRelationshipOnCarePlans() {
        let plan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        XCTAssertNoThrow(try store.addCarePlanAndWait(plan))
    }

    // MARK: Insertion

    func testAddAndFetchCarePlans() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(id: "6789", title: "Diabetes Care Plan", patientUUID: nil))
        XCTAssertNotNil(plan.uuid)
        XCTAssertNotNil(plan.schemaVersion)
    }

    func testAddCarePlanFailsIfIdentifierAlreadyExists() throws {
        let plan1 = OCKCarePlan(id: "id", title: "Diabetes Care Plan", patientUUID: nil)
        let plan2 = OCKCarePlan(id: "id", title: "Obesity Care Plan", patientUUID: nil)
        try store.addCarePlanAndWait(plan1)
        XCTAssertThrowsError(try store.addCarePlanAndWait(plan2))
    }

    // MARK: Querying

    func testCarePlaneQueryByPatientID() throws {
        let patient = try store.addPatientAndWait(.init(id: "A", givenName: "B", familyName: "C"))
        let plan = try store.addCarePlanAndWait(.init(id: "F", title: "G", patientUUID: try patient.getUUID()))

        var query = OCKCarePlanQuery()
        query.patientIDs = [patient.id]

        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched == [plan])
    }

    func testCarePlanQueryGroupIdentifier() throws {
        var plan1 = OCKCarePlan(id: "id_1", title: "Diabetes Care Plan", patientUUID: nil)
        plan1.groupIdentifier = "1"

        var plan2 = OCKCarePlan(id: "id_2", title: "Obesity Care Plan", patientUUID: nil)
        plan2.groupIdentifier = "2"

        try store.addCarePlansAndWait([plan1, plan2])

        var query = OCKCarePlanQuery(for: Date())
        query.groupIdentifiers = ["1"]

        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.id == "id_1")
    }

    func testCarePlanQueryNilGroupIdentifier() throws {
        var plan1 = OCKCarePlan(id: "id_1", title: "Diabetes Care Plan", patientUUID: nil)
        plan1.groupIdentifier = nil

        var plan2 = OCKCarePlan(id: "id_2", title: "Obesity Care Plan", patientUUID: nil)
        plan2.groupIdentifier = "2"

        try store.addCarePlansAndWait([plan1, plan2])

        var query = OCKCarePlanQuery(for: Date())
        query.groupIdentifiers = [nil]

        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.id == "id_1")
    }

    func testCarePlanQueryLimit() throws {
        let plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        let plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        try store.addCarePlansAndWait([plan1, plan2])
        var query = OCKCarePlanQuery(for: Date())
        query.limit = 1
        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
    }

    func testCarePlanQuerySortedOffset() throws {
        let plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        let plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        let plan3 = OCKCarePlan(id: "C", title: "C", patientUUID: nil)
        try store.addCarePlansAndWait([plan1, plan2, plan3])
        var query = OCKCarePlanQuery(for: Date())
        query.extendedSortDescriptors = [.title(ascending: true)]
        query.offset = 2
        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.id == "C")
    }

    func testCarePlanQueryWithNilQueryReturnsAllCarePlans() throws {
        let plan1 = OCKCarePlan(id: "1", title: "1", patientUUID: nil)
        let plan2 = OCKCarePlan(id: "2", title: "2", patientUUID: nil)
        let plan3 = OCKCarePlan(id: "3", title: "3", patientUUID: nil)
        try store.addCarePlansAndWait([plan1, plan2, plan3])
        let plans = try store.fetchCarePlansAndWait()
        XCTAssert(plans.count == 3)
    }

    func testCarePlanQueryTags() throws {
        var plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        plan1.tags = ["1", "2"]

        var plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        plan2.tags = ["1", "2", "3"]

        var plan3 = OCKCarePlan(id: "C", title: "C", patientUUID: nil)
        plan3.tags = ["1"]

        try store.addCarePlansAndWait([plan1, plan2, plan3])

        var query = OCKCarePlanQuery(for: Date())
        query.tags = ["2"]
        query.extendedSortDescriptors = [.title(ascending: true)]

        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.map { $0.title } == ["A", "B"])
    }

    func testCarePlanQueryByRemoteID() throws {
        var plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        plan1.remoteID = "abc"
        plan1 = try store.addCarePlanAndWait(plan1)

        var plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        plan2.remoteID = "def"
        plan2 = try store.addCarePlanAndWait(plan2)

        var query = OCKCarePlanQuery()
        query.remoteIDs = ["abc"]

        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first == plan1)
    }

    func testCarePlanQueryByNilRemoteID() throws {
        var plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        plan1.remoteID = nil
        plan1 = try store.addCarePlanAndWait(plan1)

        var plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        plan2.remoteID = "abc"
        plan2 = try store.addCarePlanAndWait(plan2)

        var query = OCKCarePlanQuery()
        query.remoteIDs = [nil]

        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first == plan1)
    }

    func testCarePlaneQueryByPatientUUID() throws {
        let patient = try store.addPatientAndWait(.init(id: "A", givenName: "B", familyName: "C"))
        let plan = try store.addCarePlanAndWait(.init(id: "F", title: "G", patientUUID: try patient.getUUID()))

        var query = OCKCarePlanQuery()
        query.patientUUIDs = [try patient.getUUID()]

        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched == [plan])
    }

    // MARK: Versioning

    func testUpdateCarePlanCreatesNewVersion() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(id: "bronchitis", title: "Bronchitis", patientUUID: nil))
        let updatedPlan = try store.updateCarePlanAndWait(OCKCarePlan(id: "bronchitis", title: "Bronchitis Treatment", patientUUID: nil))
        XCTAssert(updatedPlan.title == "Bronchitis Treatment")
        XCTAssert(updatedPlan.previousVersionUUID == plan.uuid)
    }

    func testUpdateFailsForUnsavedCarePlans() {
        XCTAssertThrowsError(try store.updateCarePlanAndWait(
            OCKCarePlan(id: "bronchitis", title: "Bronchitis", patientUUID: nil)))
    }

    func testCarePlanQueryWithNoDateOnlyReturnsLatestVersionOfACarePlan() throws {
        let versionA = try store.addCarePlanAndWait(OCKCarePlan(id: "A", title: "Amy", patientUUID: nil))
        let versionB = try store.updateCarePlanAndWait(OCKCarePlan(id: "A", title: "Jared", patientUUID: nil))
        let fetched = try store.fetchCarePlanAndWait(id: versionA.id)
        XCTAssert(fetched?.id == versionB.id)
        XCTAssert(fetched?.previousVersionUUID == versionA.uuid)
    }

    func testCarePlanQueryOnPastDateReturnsPastVersionOfACarePlan() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKCarePlan(id: "A", title: "a", patientUUID: nil)
        versionA.effectiveDate = dateA
        versionA = try store.addCarePlanAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKCarePlan(id: "A", title: "b", patientUUID: nil)
        versionB.effectiveDate = dateB
        versionB = try store.updateCarePlanAndWait(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let query = OCKCarePlanQuery(dateInterval: interval)
        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.title == versionA.title)
    }

    func testCarePlanQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKCarePlan(id: "A", title: "a", patientUUID: nil)
        versionA.effectiveDate = dateA
        versionA = try store.addCarePlanAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKCarePlan(id: "A", title: "b", patientUUID: nil)
        versionB.effectiveDate = dateB
        versionB = try store.updateCarePlanAndWait(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let query = OCKCarePlanQuery(dateInterval: interval)
        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.title == versionB.title)
    }

    func testCarePlanQueryBeforeCarePlansWasCreatedReturnsNoResults() throws {
        let dateA = Date()
        try store.addCarePlanAndWait(OCKCarePlan(id: "A", title: "a", patientUUID: nil))
        let interval = DateInterval(start: dateA.addingTimeInterval(-100), end: dateA)
        let query = OCKCarePlanQuery(dateInterval: interval)
        let fetched = try store.fetchCarePlansAndWait(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    func testQueryCarePlanByRemoteID() throws {
        var plan = OCKCarePlan(id: "A", title: "Plan", patientUUID: nil)
        plan.remoteID = "abc"
        plan = try store.addCarePlanAndWait(plan)
        var query = OCKCarePlanQuery(for: Date())
        query.remoteIDs = ["abc"]
        let fetched = try store.fetchCarePlansAndWait(query: query).first
        XCTAssert(plan == fetched)
    }

    func testQueryCarePlanByPatientRemoteID() throws {
        var patient = OCKPatient(id: "A", givenName: "B", familyName: "C")
        patient.remoteID = "abc"
        patient = try store.addPatientAndWait(patient)

        var plan = OCKCarePlan(id: "D", title: "E", patientUUID: patient.uuid)
        plan = try store.addCarePlanAndWait(plan)

        var query = OCKCarePlanQuery(for: Date())
        query.patientRemoteIDs = ["abc"]

        let fetched = try store.fetchCarePlansAndWait(query: query).first
        XCTAssert(fetched == plan)
    }
    // MARK: Deletion

    func testDeleteCarePlan() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(id: "stinky_breath", title: "Gingivitus", patientUUID: nil))
        try store.deleteCarePlanAndWait(plan)
        let fetched = try store.fetchCarePlansAndWait(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteCarePlanFailsIfCarePlanDoesntExist() {
        let plan = OCKCarePlan(id: "stinky_breath", title: "Gingivitus", patientUUID: nil)
        XCTAssertThrowsError(try store.deleteCarePlanAndWait(plan))
    }
}

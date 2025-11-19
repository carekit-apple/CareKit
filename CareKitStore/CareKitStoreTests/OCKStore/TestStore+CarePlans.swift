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
import XCTest

class TestStoreCarePlans: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }

    // MARK: Insertion

    func testAddAndFetchCarePlans() async throws {
        let plan = try await store.addCarePlan(OCKCarePlan(id: "6789", title: "Diabetes Care Plan", patientUUID: nil))
        XCTAssertNotNil(plan.uuid)
        XCTAssertNotNil(plan.schemaVersion)
    }

    func testAddCarePlanFailsIfIdentifierAlreadyExists() async throws {

        let plan1 = OCKCarePlan(id: "id", title: "Diabetes Care Plan", patientUUID: nil)
        let plan2 = OCKCarePlan(id: "id", title: "Obesity Care Plan", patientUUID: nil)
        try await store.addCarePlan(plan1)

        do {
            try await store.addCarePlan(plan2)
            XCTFail("Expected an error")
        } catch {
            // no-op
        }
    }

    // MARK: Querying

    func testCarePlaneQueryByPatientID() async throws {
        let patient = try await store.addPatient(.init(id: "A", givenName: "B", familyName: "C"))
        let plan = try await store.addCarePlan(.init(id: "F", title: "G", patientUUID: patient.uuid))

        var query = OCKCarePlanQuery()
        query.patientIDs = [patient.id]

        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched, [plan])
    }

    func testCarePlanQueryGroupIdentifier() async throws {
        var plan1 = OCKCarePlan(id: "id_1", title: "Diabetes Care Plan", patientUUID: nil)
        plan1.groupIdentifier = "1"

        var plan2 = OCKCarePlan(id: "id_2", title: "Obesity Care Plan", patientUUID: nil)
        plan2.groupIdentifier = "2"

        try await store.addCarePlans([plan1, plan2])

        var query = OCKCarePlanQuery(for: Date())
        query.groupIdentifiers = ["1"]

        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, "id_1")
    }

    func testCarePlanQueryNilGroupIdentifier() async throws {
        var plan1 = OCKCarePlan(id: "id_1", title: "Diabetes Care Plan", patientUUID: nil)
        plan1.groupIdentifier = nil

        var plan2 = OCKCarePlan(id: "id_2", title: "Obesity Care Plan", patientUUID: nil)
        plan2.groupIdentifier = "2"

        try await store.addCarePlans([plan1, plan2])

        var query = OCKCarePlanQuery(for: Date())
        query.groupIdentifiers = [nil]

        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, "id_1")
    }

    func testCarePlanQueryLimit() async throws {
        let plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        let plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        try await store.addCarePlans([plan1, plan2])
        var query = OCKCarePlanQuery(for: Date())
        query.limit = 1
        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.count, 1)
    }

    func testCarePlanQuerySortedOffset() async throws {
        let plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        let plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        let plan3 = OCKCarePlan(id: "C", title: "C", patientUUID: nil)
        try await store.addCarePlans([plan1, plan2, plan3])
        var query = OCKCarePlanQuery(for: Date())
        query.sortDescriptors = [.title(ascending: true)]
        query.offset = 2
        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, "C")
    }

    func testCarePlanQueryWithNilQueryReturnsAllCarePlans() async throws {
        let plan1 = OCKCarePlan(id: "1", title: "1", patientUUID: nil)
        let plan2 = OCKCarePlan(id: "2", title: "2", patientUUID: nil)
        let plan3 = OCKCarePlan(id: "3", title: "3", patientUUID: nil)
        try await store.addCarePlans([plan1, plan2, plan3])
        let plans = try await store.fetchCarePlans(query: OCKCarePlanQuery())
        XCTAssertEqual(plans.count, 3)
    }

    func testCarePlanQueryTags() async throws {
        var plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        plan1.tags = ["1", "2"]

        var plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        plan2.tags = ["1", "2", "3"]

        var plan3 = OCKCarePlan(id: "C", title: "C", patientUUID: nil)
        plan3.tags = ["1"]

        try await store.addCarePlans([plan1, plan2, plan3])

        var query = OCKCarePlanQuery(for: Date())
        query.tags = ["2"]
        query.sortDescriptors = [.title(ascending: true)]

        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.map { $0.title }, ["A", "B"])
    }

    func testCarePlanQueryByRemoteID() async throws {
        var plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        plan1.remoteID = "abc"
        plan1 = try await store.addCarePlan(plan1)

        var plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        plan2.remoteID = "def"
        plan2 = try await store.addCarePlan(plan2)

        var query = OCKCarePlanQuery()
        query.remoteIDs = ["abc"]

        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first, plan1)
    }

    func testCarePlanQueryByNilRemoteID() async throws {
        var plan1 = OCKCarePlan(id: "A", title: "A", patientUUID: nil)
        plan1.remoteID = nil
        plan1 = try await store.addCarePlan(plan1)

        var plan2 = OCKCarePlan(id: "B", title: "B", patientUUID: nil)
        plan2.remoteID = "abc"
        plan2 = try await store.addCarePlan(plan2)

        var query = OCKCarePlanQuery()
        query.remoteIDs = [nil]

        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first, plan1)
    }

    func testCarePlaneQueryByPatientUUID() async throws {
        let patient = try await store.addPatient(.init(id: "A", givenName: "B", familyName: "C"))
        let plan = try await store.addCarePlan(.init(id: "F", title: "G", patientUUID: patient.uuid))

        var query = OCKCarePlanQuery()
        query.patientUUIDs = [patient.uuid]

        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched, [plan])
    }

    // MARK: Versioning

    func testUpdateCarePlanCreatesNewVersion() async throws {
        let plan = try await store.addCarePlan(OCKCarePlan(id: "bronchitis", title: "Bronchitis", patientUUID: nil))
        let updatedPlan = try await store.updateCarePlan(OCKCarePlan(id: "bronchitis", title: "Bronchitis Treatment", patientUUID: nil))
        XCTAssertEqual(updatedPlan.title, "Bronchitis Treatment")
        XCTAssertEqual(updatedPlan.previousVersionUUIDs.first, plan.uuid)
    }

    func testUpdateFailsForUnsavedCarePlans() async {
        do {
            try await store.updateCarePlan(OCKCarePlan(id: "bronchitis", title: "Bronchitis", patientUUID: nil))
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testCarePlanQueryWithNoDateOnlyReturnsLatestVersionOfACarePlan() async throws {
        let versionA = try await store.addCarePlan(OCKCarePlan(id: "A", title: "Amy", patientUUID: nil))
        let versionB = try await store.updateCarePlan(OCKCarePlan(id: "A", title: "Jared", patientUUID: nil))
        let fetched = try await store.fetchCarePlan(withID: versionA.id)
        XCTAssertEqual(fetched.id, versionB.id)
        XCTAssertEqual(fetched.previousVersionUUIDs.first, versionA.uuid)
    }

    func testCarePlanQueryOnPastDateReturnsPastVersionOfACarePlan() async throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKCarePlan(id: "A", title: "a", patientUUID: nil)
        versionA.effectiveDate = dateA
        versionA = try await store.addCarePlan(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKCarePlan(id: "A", title: "b", patientUUID: nil)
        versionB.effectiveDate = dateB
        versionB = try await store.updateCarePlan(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let query = OCKCarePlanQuery(dateInterval: interval)
        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, versionA.title)
    }

    func testCarePlanQuerySpanningVersionsReturnsNewestVersionOnly() async throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKCarePlan(id: "A", title: "a", patientUUID: nil)
        versionA.effectiveDate = dateA
        versionA = try await store.addCarePlan(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKCarePlan(id: "A", title: "b", patientUUID: nil)
        versionB.effectiveDate = dateB
        versionB = try await store.updateCarePlan(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let query = OCKCarePlanQuery(dateInterval: interval)
        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, versionB.title)
    }

    func testCarePlanQueryBeforeCarePlansWasCreatedReturnsNoResults() async throws {
        let dateA = Date()
        try await store.addCarePlan(OCKCarePlan(id: "A", title: "a", patientUUID: nil))
        let interval = DateInterval(start: dateA.addingTimeInterval(-100), end: dateA)
        let query = OCKCarePlanQuery(dateInterval: interval)
        let fetched = try await store.fetchCarePlans(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    func testQueryCarePlanByRemoteID() async throws {
        var plan = OCKCarePlan(id: "A", title: "Plan", patientUUID: nil)
        plan.remoteID = "abc"
        plan = try await store.addCarePlan(plan)
        var query = OCKCarePlanQuery(for: Date())
        query.remoteIDs = ["abc"]
        let fetched = try await store.fetchCarePlans(query: query).first
        XCTAssertEqual(plan, fetched)
    }

    func testQueryCarePlanByPatientRemoteID() async throws {
        var patient = OCKPatient(id: "A", givenName: "B", familyName: "C")
        patient.remoteID = "abc"
        patient = try await store.addPatient(patient)

        var plan = OCKCarePlan(id: "D", title: "E", patientUUID: patient.uuid)
        plan = try await store.addCarePlan(plan)

        var query = OCKCarePlanQuery(for: Date())
        query.patientRemoteIDs = ["abc"]

        let fetched = try await store.fetchCarePlans(query: query).first
        XCTAssertEqual(fetched, plan)
    }
    // MARK: Deletion

    func testDeleteCarePlan() async throws {
        let plan = try await store.addCarePlan(OCKCarePlan(id: "stinky_breath", title: "Gingivitus", patientUUID: nil))
        try await store.deleteCarePlan(plan)
        let fetched = try await store.fetchCarePlans(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteCarePlanFailsIfCarePlanDoesntExist() async {

        let plan = OCKCarePlan(id: "stinky_breath", title: "Gingivitus", patientUUID: nil)

        do {
            try await store.deleteCarePlan(plan)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }
}

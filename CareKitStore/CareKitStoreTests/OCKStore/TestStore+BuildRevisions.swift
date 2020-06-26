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

@testable import CareKitStore
import XCTest

class TestStoreBuildRevisions: XCTestCase {

    private var store: OCKStore!

    override func setUp() {
        super.setUp()

        let remote = DummyEndpoint()
        remote.automaticallySynchronizes = false

        store = OCKStore(
            name: "TestDatabase",
            type: .inMemory,
            remote: remote)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    func testEmptyStoreProducesEmptyRevision() {
        let revision = store.computeRevision(since: store.context.clockTime)
        XCTAssert(revision.entities.isEmpty)
    }

    // MARK: Tasks

    func testAddingTaskCreatesRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        try store.addTaskAndWait(task)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 1)
        XCTAssert(revision.entities.first?.entityType == .task)
    }

    func testUpdatingTaskCreatesRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        var task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        try store.addTaskAndWait(task)

        task.title = "Updated"
        try store.updateTaskAndWait(task)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.first?.entityType == .task)
    }

    func testRevisionForDeletingTask() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        let taskA1 = OCKTask(id: "A", title: "A1", carePlanUUID: nil, schedule: schedule)
        try store.addTaskAndWait(taskA1)

        let taskA2 = OCKTask(id: "A", title: "A2", carePlanUUID: nil, schedule: schedule)
        try store.updateTaskAndWait(taskA2)
        store.context.knowledgeVector.increment(clockFor: store.context.clockID)
        try store.deleteTasksAndWait([taskA2])
        let revision = store.computeRevision(since: store.context.clockTime)

        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.first?.deletedDate != nil)
    }

    // MARK: Outcomes

    func testAddingOutcomeCreatesRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)

        let outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        try store.addOutcomeAndWait(outcome)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.last?.entityType == .outcome)
    }

    func testDeletingOutcomeCreatesRevisionRecords() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)

        let outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        try store.addOutcomeAndWait(outcome)
        try store.deleteOutcomeAndWait(outcome)
        let revision = store.computeRevision(since: 0)

        // Tombstones are sorted first in the revision record, which is
        // why we expect the first entity to be the deleted outcome.
        XCTAssert(revision.entities.first?.entityType == .outcome)
        XCTAssert(revision.entities.count == 3)
    }

    // MARK: Patients

    func testAddingPatientCreatesRevisionRecord() throws {
        let patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        try store.addPatientAndWait(patient)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 1)
        XCTAssert(revision.entities.first?.entityType == .patient)
    }

    func testUpdatingPatientCreatesRevisionRecord() throws {
        var patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        try store.addPatientAndWait(patient)

        patient.asset = "Updated"
        try store.updatePatientAndWait(patient)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.first?.entityType == .patient)
    }

    func testRevisionForDeletingPatient() throws {
        let patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        try store.addPatientAndWait(patient)

        try store.deletePatientsAndWait([patient])
        let revision = store.computeRevision(since: 0)

        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.first?.deletedDate != nil)
    }

    // MARK: CarePlans

    func testAddingCarePlanCreatesRevisionRecord() throws {
        let plan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        try store.addCarePlanAndWait(plan)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 1)
        XCTAssert(revision.entities.first?.entityType == .carePlan)
    }

    func testUpdatingCarePlanCreatesRevisionRecord() throws {
        var plan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        try store.addCarePlanAndWait(plan)

        plan.title = "Updated"
        try store.updateCarePlanAndWait(plan)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.first?.entityType == .carePlan)
    }

    func testRevisionForDeletingCarePlan() throws {
        let plan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        try store.addCarePlanAndWait(plan)

        try store.deleteCarePlansAndWait([plan])
        let revision = store.computeRevision(since: 0)

        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.first?.deletedDate != nil)
    }

    // MARK: Contact

    func testAddingContactCreatesRevisionRecord() throws {
        let contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        try store.addContactAndWait(contact)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 1)
        XCTAssert(revision.entities.first?.entityType == .contact)
    }

    func testUpdatingContactCreatesRevisionRecord() throws {
        var contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        try store.addContactAndWait(contact)

        contact.organization = "Updated"
        try store.updateContactAndWait(contact)

        let revision = store.computeRevision(since: 0)
        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.first?.entityType == .contact)
    }

    func testRevisionForDeletingContact() throws {
        let contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        try store.addContactAndWait(contact)

        try store.deleteContactsAndWait([contact])
        let revision = store.computeRevision(since: 0)

        XCTAssert(revision.entities.count == 2)
        XCTAssert(revision.entities.first?.deletedDate != nil)
    }
}

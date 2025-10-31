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

class TestStoreBuildRevisions: XCTestCase {

    private var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }

    func testEmptyStoreProducesEmptyRevision() throws {
        let revisions = try store.computeRevisions(since: store.context.knowledgeVector)
        XCTAssert(revisions.isEmpty)
    }

    func testAllEntitiesReturnedForEmptyKnowledgeVector() throws {
        let uuid1 = UUID()
        let uuid2 = UUID()

        let patientA = OCKPatient(id: "A", givenName: "a", familyName: "a")
        let revisionA = OCKRevisionRecord(
            entities: [.patient(patientA)],
            knowledgeVector: OCKRevisionRecord.KnowledgeVector([uuid1: 5])
        )

        let patientB = OCKPatient(id: "B", givenName: "b", familyName: "b")
        let revisionB = OCKRevisionRecord(
            entities: [.patient(patientB)],
            knowledgeVector: OCKRevisionRecord.KnowledgeVector([uuid2: 3])
        )

        store.mergeRevision(revisionA)
        store.mergeRevision(revisionB)

        let revisions = try store.computeRevisions(since: .init())
        let entities = revisions.flatMap { $0.entities }
        XCTAssertEqual(entities.count, 2)
    }

    func testKnownEntitiesAreNotReturned() throws {
        let uuid1 = UUID()
        let uuid2 = UUID()

        let patient = OCKPatient(id: "A", givenName: "a", familyName: "a")
        let revisionA = OCKRevisionRecord(
            entities: [.patient(patient)],
            knowledgeVector: OCKRevisionRecord.KnowledgeVector([uuid1: 5])
        )

        let carePlan = OCKCarePlan(id: "B", title: "b", patientUUID: nil)
        let revisionB = OCKRevisionRecord(
            entities: [.carePlan(carePlan)],
            knowledgeVector: OCKRevisionRecord.KnowledgeVector([uuid2: 3])
        )

        let contactC = OCKContact(id: "C", givenName: "c", familyName: "c", carePlanUUID: nil)
        let revisionC = OCKRevisionRecord(
            entities: [.contact(contactC)],
            knowledgeVector: OCKRevisionRecord.KnowledgeVector([uuid2: 3])
        )

        store.mergeRevision(revisionA)
        store.mergeRevision(revisionB)
        store.mergeRevision(revisionC)

        let knowledge = OCKRevisionRecord.KnowledgeVector([uuid1: 1, uuid2: 3])
        let revisions = try store.computeRevisions(since: knowledge)
        XCTAssertEqual(revisions.count, 1)
        XCTAssertEqual(revisions.first?.entities.count, 1)
        XCTAssertEqual(revisions.first?.entities.first?.entityType, .patient)
    }

    func testEntitiesAreGroupedByKnowledgeVector() throws {
        let uuid1 = UUID()
        let uuid2 = UUID()

        let patientA = OCKPatient(id: "A", givenName: "a", familyName: "a")
        let revisionA = OCKRevisionRecord(
            entities: [.patient(patientA)],
            knowledgeVector: OCKRevisionRecord.KnowledgeVector([uuid1: 5])
        )

        let patientB = OCKPatient(id: "B", givenName: "b", familyName: "b")
        let revisionB = OCKRevisionRecord(
            entities: [.patient(patientB)],
            knowledgeVector: OCKRevisionRecord.KnowledgeVector([uuid2: 3])
        )

        let patientC = OCKPatient(id: "C", givenName: "c", familyName: "c")
        let revisionC = OCKRevisionRecord(
            entities: [.patient(patientC)],
            knowledgeVector: OCKRevisionRecord.KnowledgeVector([uuid2: 3])
        )

        store.mergeRevision(revisionA)
        store.mergeRevision(revisionB)
        store.mergeRevision(revisionC)
        
        let knowledge = OCKRevisionRecord.KnowledgeVector([uuid1: 4])
        let revisions = try store.computeRevisions(since: knowledge)

        XCTAssertEqual(revisions.count, 2)
    }

    // MARK: Tasks

    func testAddingTaskCreatesRevisionRecord() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        let revision = try store.computeRevisions(since: .init()).first
        XCTAssertEqual(revision?.entities.count, 1)
        XCTAssertEqual(revision?.entities.first?.entityType, .task)
    }

    func testUpdatingTaskCreatesRevisionRecord() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        var task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        task.title = "Updated"
        try await store.updateTask(task)

        let revision = try store.computeRevisions(since: .init()).first
        XCTAssertEqual(revision?.entities.count, 2)
        XCTAssertEqual(revision?.entities.first?.entityType, .task)
    }

    func testRevisionForDeletingTask() async throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        let taskA1 = OCKTask(id: "A", title: "A1", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(taskA1)

        let taskA2 = OCKTask(id: "A", title: "A2", carePlanUUID: nil, schedule: schedule)
        try await store.updateTask(taskA2)
        store.context.knowledgeVector.increment(clockFor: store.context.clockID)
        try await store.deleteTasks([taskA2])
        let vector = OCKRevisionRecord.KnowledgeVector([store.context.clockID: 1])
        let revision = try store.computeRevisions(since: vector).first

        XCTAssertEqual(revision?.entities.count, 1)
        XCTAssertNotNil(revision?.entities.first?.value.deletedDate)
    }

    // MARK: Outcomes

    func testAddingOutcomeCreatesRevisionRecord() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        task = try await store.addTask(task)

        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        try await store.addOutcome(outcome)

        let revision = try store.computeRevisions(since: .init()).first!
        XCTAssertEqual(revision.entities.count, 2)
        XCTAssertEqual(revision.entities.last?.entityType, .outcome)
    }

    func testDeletingOutcomeCreatesRevisionRecords() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        task = try await store.addTask(task)

        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        try await store.addOutcome(outcome)
        try await store.deleteOutcome(outcome)
        let revision = try store.computeRevisions(since: .init()).first

        XCTAssertEqual(revision?.entities.last?.entityType, .outcome)
        XCTAssertEqual(revision?.entities.count, 3)
    }

    // MARK: Patients

    func testAddingPatientCreatesRevisionRecord() async throws {
        let patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        try await store.addPatient(patient)

        let revision = try store.computeRevisions(since: .init()).first
        XCTAssertEqual(revision?.entities.count, 1)
        XCTAssertEqual(revision?.entities.first?.entityType, .patient)
    }

    func testUpdatingPatientCreatesRevisionRecord() async throws {
        var patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        try await store.addPatient(patient)

        patient.asset = "Updated"
        try await store.updatePatient(patient)

        let revision = try store.computeRevisions(since: .init()).first
        XCTAssertEqual(revision?.entities.count, 2)
        XCTAssertEqual(revision?.entities.first?.entityType, .patient)
    }

    func testRevisionForDeletingPatient() async throws {
        let patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        try await store.addPatient(patient)

        try await store.deletePatients([patient])
        let revision = try store.computeRevisions(since: .init()).first

        XCTAssertEqual(revision?.entities.count, 2)
        XCTAssertNotNil(revision?.entities.first?.value.deletedDate)
    }

    // MARK: CarePlans

    func testAddingCarePlanCreatesRevisionRecord() async throws {
        let plan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        try await store.addCarePlan(plan)

        let revision = try store.computeRevisions(since: .init()).first
        XCTAssertEqual(revision?.entities.count, 1)
        XCTAssertEqual(revision?.entities.first?.entityType, .carePlan)
    }

    func testUpdatingCarePlanCreatesRevisionRecord() async throws {
        var plan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        try await store.addCarePlan(plan)

        plan.title = "Updated"
        try await store.updateCarePlan(plan)

        let revision = try store.computeRevisions(since: .init()).first
        XCTAssertEqual(revision?.entities.count, 2)
        XCTAssertEqual(revision?.entities.first?.entityType, .carePlan)
    }

    func testRevisionForDeletingCarePlan() async throws {
        let plan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        try await store.addCarePlan(plan)

        try await store.deleteCarePlans([plan])
        let revision = try store.computeRevisions(since: .init()).first

        XCTAssertEqual(revision?.entities.count, 2)
        XCTAssertNotNil(revision?.entities.first?.value.deletedDate)
    }

    // MARK: Contact

    func testAddingContactCreatesRevisionRecord() async throws {
        let contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        try await store.addContact(contact)

        let revision = try store.computeRevisions(since: .init()).first
        XCTAssertEqual(revision?.entities.count, 1)
        XCTAssertEqual(revision?.entities.first?.entityType, .contact)
    }

    func testUpdatingContactCreatesRevisionRecord() async throws {
        var contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        try await store.addContact(contact)

        contact.organization = "Updated"
        try await store.updateContact(contact)

        let revision = try store.computeRevisions(since: .init()).first
        XCTAssertEqual(revision?.entities.count, 2)
        XCTAssertEqual(revision?.entities.first?.entityType, .contact)
    }

    func testRevisionForDeletingContact() async throws {
        let contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        try await store.addContact(contact)

        try await store.deleteContacts([contact])
        let revision = try store.computeRevisions(since: .init()).first

        XCTAssertEqual(revision?.entities.count, 2)
        XCTAssertNotNil(revision?.entities.first?.value.deletedDate)
    }
}

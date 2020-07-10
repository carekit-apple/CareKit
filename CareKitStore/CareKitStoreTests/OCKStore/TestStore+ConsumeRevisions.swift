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
import CoreData
import XCTest

class TestStoreConsumeRevisions: XCTestCase {

    private var store: OCKStore!
    private var remote: DummyEndpoint!

    override func setUp() {
        super.setUp()
        remote = DummyEndpoint()
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

    // MARK: Tasks

    func testAddingNewTaskViaRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "a", title: nil, carePlanUUID: nil, schedule: schedule)
        task.uuid = UUID()
        task.createdDate = Date()
        task.updatedDate = task.createdDate

        let revision = OCKRevisionRecord(
            entities: [.task(task)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let tasks = try store.fetchTasksAndWait()

        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == "a")
    }

    func testUpdatingLatestVersionOfTaskViaRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let taskA = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))

        var taskB = OCKTask(id: "abc123", title: "B", carePlanUUID: nil, schedule: schedule)
        taskB.uuid = UUID()
        taskB.createdDate = taskA.createdDate!.addingTimeInterval(10.0)
        taskB.updatedDate = taskB.createdDate
        taskB.effectiveDate = taskB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.task(taskB)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let tasks = try store.fetchTasksAndWait(query: OCKTaskQuery(for: taskB.effectiveDate))

        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == "abc123")
        XCTAssert(tasks.first?.title == "B")
    }

    func testKeepingRemoteVersionOfTaskConflict() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let taskA = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))

        var taskB = OCKTask(id: "abc123", title: "B", carePlanUUID: nil, schedule: schedule)
        taskB.uuid = UUID()
        taskB.createdDate = taskA.createdDate!.addingTimeInterval(-10.0)
        taskB.updatedDate = taskB.createdDate
        taskB.effectiveDate = taskB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.task(taskB)],
            knowledgeVector: .init())

        let remote = store.remote as? DummyEndpoint
        remote?.conflictPolicy = .keepRemote

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let tasks = try store.fetchTasksAndWait()

        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == "abc123")
        XCTAssert(tasks.first?.title == "B")
        XCTAssert(tasks.first?.previousVersionUUID == nil)
    }

    func testKeepingLocalVersionOfTaskConflict() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let taskA = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))

        var taskB = OCKTask(id: "abc123", title: "B", carePlanUUID: nil, schedule: schedule)
        taskB.uuid = UUID()
        taskB.createdDate = taskA.createdDate!.addingTimeInterval(-10.0)
        taskB.updatedDate = taskB.createdDate
        taskB.effectiveDate = taskB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.task(taskB)],
            knowledgeVector: .init())

        let remote = store.remote as? DummyEndpoint
        remote?.conflictPolicy = .keepDevice

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let tasks = try store.fetchTasksAndWait()

        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == "abc123")
        XCTAssert(tasks.first?.title == "A")
        XCTAssert(tasks.first?.previousVersionUUID == nil)
    }

    func testUpdatingTaskViaRevisionRecordWhenItWouldOverwriteOutcomes() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let taskA = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))
        let outcome = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 1, values: [])
        try store.addOutcomeAndWait(outcome)

        var taskB = OCKTask(id: "abc123", title: "B", carePlanUUID: nil, schedule: schedule)
        taskB.uuid = UUID()
        taskB.createdDate = taskA.createdDate!.addingTimeInterval(10.0)
        taskB.updatedDate = taskB.createdDate
        taskB.effectiveDate = taskB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.task(taskB)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.isEmpty)
    }

    func testTasksAddedViaRevisionRecordHaveSameCreatedDateAsRevisionRecord() throws {
        let date = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule)
        task.createdDate = date
        task = try store.addTaskAndWait(task)
        task.uuid = UUID()

        let revision = OCKRevisionRecord(
            entities: [.task(task)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))

        let tasks = try store.fetchTasksAndWait()
        XCTAssert(tasks.first?.createdDate == date)
    }

    func testTaskRevisionsAreIdempotent() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))

        let revision = OCKRevisionRecord(
            entities: [.task(task)],
            knowledgeVector: .init())

        for _ in 0..<3 {
            XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
            XCTAssert(try store.fetchTasksAndWait() == [task])
        }
    }

    // MARK: Outcomes

    func testAddingNewOutcomeViaRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))

        var outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        outcome.uuid = UUID()
        outcome.createdDate = Date()
        outcome.updatedDate = outcome.createdDate

        let revision = OCKRevisionRecord(
            entities: [.outcome(outcome)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.count == 1)
        XCTAssert(outcomes.first?.id == outcome.id)
    }

    func testDeleteExistingOutcomeViaRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))
        try store.addOutcomeAndWait(OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: []))

        var outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        outcome.uuid = UUID()
        outcome.createdDate = Date().advanced(by: 10)
        outcome.updatedDate = outcome.createdDate
        outcome.deletedDate = outcome.createdDate

        let revision = OCKRevisionRecord(
            entities: [.outcome(outcome)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.isEmpty)
    }

    func testDeletingNonExistentOutcomeViaRevisionRecordDoesNotThrowError() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))

        var outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        outcome.uuid = UUID()
        outcome.createdDate = Date()
        outcome.updatedDate = outcome.createdDate
        outcome.deletedDate = outcome.createdDate

        let revision = OCKRevisionRecord(
            entities: [.outcome(outcome)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
    }

    func testAddingLaterDuplicateOutcomeViaRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))
        let localOutcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        try store.addOutcomeAndWait(localOutcome)

        var remoteOutcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        remoteOutcome.uuid = UUID()
        remoteOutcome.createdDate = Date().addingTimeInterval(100)
        remoteOutcome.updatedDate = remoteOutcome.createdDate

        let revision = OCKRevisionRecord(
            entities: [.outcome(remoteOutcome)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
        XCTAssertNoThrow(try store.context.save())

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.count == 1)
        XCTAssert(outcomes.first?.createdDate == remoteOutcome.createdDate)
    }

    func testOutcomeDeletedAtEarlierDateOnRemoteDoesntDeleteLocalOutcomeCreatedAtLaterDate() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))
        var localOutcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [OCKOutcomeValue(6)])
        localOutcome = try store.addOutcomeAndWait(localOutcome)

        var remoteOutcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        remoteOutcome.uuid = UUID()
        remoteOutcome.createdDate = localOutcome.createdDate?.addingTimeInterval(-100)
        remoteOutcome.updatedDate = localOutcome.updatedDate?.addingTimeInterval(-100)
        remoteOutcome.deletedDate = remoteOutcome.createdDate

        let revision = OCKRevisionRecord(
            entities: [.outcome(remoteOutcome)],
            knowledgeVector: .init())

        remote.conflictPolicy = .keepDevice
        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
        XCTAssertNoThrow(try store.context.save())

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.count == 1)
        XCTAssert(outcomes.first?.values.first?.integerValue == 6)
    }

    func testOutcomeDeletedAtLaterDateOnRemoteDoesDeleteLocalOutcomeCreatedAtEarlierDate() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))
        var localOutcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        localOutcome = try store.addOutcomeAndWait(localOutcome)

        var remoteOutcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        remoteOutcome.uuid = UUID()
        remoteOutcome.createdDate = Date().addingTimeInterval(100)
        remoteOutcome.updatedDate = remoteOutcome.createdDate
        remoteOutcome.deletedDate = remoteOutcome.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.outcome(remoteOutcome)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
        XCTAssertNoThrow(try store.context.save())

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.isEmpty)
    }

    func testOutcomesAddedViaRevisionRecordedHaveSameCreatedDateAsRevisionRecord() throws {
        let date = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))

        var outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        outcome.uuid = UUID()
        outcome.createdDate = date
        outcome.updatedDate = date

        let revision = OCKRevisionRecord(
            entities: [.outcome(outcome)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.first?.createdDate == date)
    }

    func testTombstonesAddedViaRevisionRecordedHaveSameUUIDAsRevisionRecord() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))

        var tombstone = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        tombstone.uuid = UUID()
        tombstone.createdDate = Date().addingTimeInterval(100)
        tombstone.updatedDate = tombstone.createdDate
        tombstone.deletedDate = tombstone.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.outcome(tombstone)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.isEmpty)

        store.context.performAndWait {
            let request = NSFetchRequest<OCKCDOutcome>(entityName: "OCKCDOutcome")
            let outcome = try! self.store.context.fetch(request).first
            XCTAssert(outcome?.createdDate == tombstone.createdDate)
            XCTAssert(outcome?.deletedDate == tombstone.createdDate)
            XCTAssert(outcome?.uuid == tombstone.uuid)
        }
    }

    func testOutcomeRevisionsAreIdempotent() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "abc123", title: "A", carePlanUUID: nil, schedule: schedule))
        let outcome = try store.addOutcomeAndWait(OCKOutcome(
            taskUUID: try task.getUUID(),
            taskOccurrenceIndex: 0,
            values: []))

        let revision = OCKRevisionRecord(
            entities: [.outcome(outcome)],
            knowledgeVector: .init())

        for _ in 0..<3 {
            XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
            XCTAssert(try store.fetchOutcomesAndWait() == [outcome])
        }
    }

    // MARK: Patients

    func testAddingNewPatientViaRevisionRecord() throws {
        var patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        patient.uuid = UUID()
        patient.createdDate = Date()
        patient.updatedDate = patient.createdDate

        let revision = OCKRevisionRecord(
            entities: [.patient(patient)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let patients = try store.fetchPatientsAndWait()

        XCTAssert(patients.count == 1)
        XCTAssert(patients.first?.id == "id1")
    }

    func testUpdatingLatestVersionOfPatientViaRevisionRecord() throws {
        let patientA = try store.addPatientAndWait(OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost"))

        var patientB = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frosty")
        patientB.uuid = UUID()
        patientB.createdDate = patientA.createdDate!.addingTimeInterval(10.0)
        patientB.updatedDate = patientB.createdDate
        patientB.effectiveDate = patientB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.patient(patientB)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let patients = try store.fetchPatientsAndWait(query: OCKPatientQuery(for: patientB.effectiveDate))

        XCTAssert(patients.count == 1)
        XCTAssert(patients.first?.id == "id1")
        XCTAssert(patients.first?.name.familyName == "Frosty")
    }

    func testKeepingRemoteVersionOfPatientConflict() throws {
        let patientA = try store.addPatientAndWait(OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost"))

        var patientB = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frosty")
        patientB.uuid = UUID()
        patientB.createdDate = patientA.createdDate!.addingTimeInterval(-10.0)
        patientB.updatedDate = patientB.createdDate
        patientB.effectiveDate = patientB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.patient(patientB)],
            knowledgeVector: .init())

        let remote = store.remote as? DummyEndpoint
        remote?.conflictPolicy = .keepRemote

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let patients = try store.fetchPatientsAndWait()

        XCTAssert(patients.count == 1)
        XCTAssert(patients.first?.id == "id1")
        XCTAssert(patients.first?.name.familyName == "Frosty")
        XCTAssert(patients.first?.previousVersionUUID == nil)
    }

    func testKeepingLocalVersionOfPatientConflict() throws {
        let patientA = try store.addPatientAndWait(OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost"))

        var patientB = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frosty")
        patientB.uuid = UUID()
        patientB.createdDate = patientA.createdDate!.addingTimeInterval(-10.0)
        patientB.updatedDate = patientB.createdDate
        patientB.effectiveDate = patientB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.patient(patientB)],
            knowledgeVector: .init())

        let remote = store.remote as? DummyEndpoint
        remote?.conflictPolicy = .keepDevice

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let patients = try store.fetchPatientsAndWait()

        XCTAssert(patients.count == 1)
        XCTAssert(patients.first?.id == "id1")
        XCTAssert(patients.first?.name.familyName == "Frost")
        XCTAssert(patients.first?.previousVersionUUID == nil)
    }

    func testPatientsAddedViaRevisionRecordHaveSameCreatedDateAsRevisionRecord() throws {
        var patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        let date = Calendar.current.startOfDay(for: Date())
        patient.createdDate = date
        patient = try store.addPatientAndWait(patient)
        patient.uuid = UUID()

        let revision = OCKRevisionRecord(
            entities: [.patient(patient)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))

        let patients = try store.fetchPatientsAndWait()
        XCTAssert(patients.first?.createdDate == date)
    }

    func testPatientRevisionsAreIdempotent() throws {
        let patient = try store.addPatientAndWait(OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost"))

        let revision = OCKRevisionRecord(
            entities: [.patient(patient)],
            knowledgeVector: .init())

        for _ in 0..<3 {
            XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
            XCTAssert(try store.fetchPatientsAndWait() == [patient])
        }
    }

    // MARK: CarePlans

    func testAddingNewCarePlanViaRevisionRecord() throws {
        var carePlan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        carePlan.uuid = UUID()
        carePlan.createdDate = Date()
        carePlan.updatedDate = carePlan.createdDate

        let revision = OCKRevisionRecord(
            entities: [.carePlan(carePlan)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let carePlans = try store.fetchCarePlansAndWait()

        XCTAssert(carePlans.count == 1)
        XCTAssert(carePlans.first?.id == "diabetes_type_1")
    }

    func testUpdatingLatestVersionOfCarePlanViaRevisionRecord() throws {
        let carePlanA = try store.addCarePlanAndWait(OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil))

        var carePlanB = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Type II Care Plan", patientUUID: nil)
        carePlanB.uuid = UUID()
        carePlanB.createdDate = carePlanA.createdDate!.addingTimeInterval(10.0)
        carePlanB.updatedDate = carePlanB.createdDate
        carePlanB.effectiveDate = carePlanB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.carePlan(carePlanB)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let carePlans = try store.fetchCarePlansAndWait(query: OCKCarePlanQuery(for: carePlanB.effectiveDate))

        XCTAssert(carePlans.count == 1)
        XCTAssert(carePlans.first?.id == "diabetes_type_1")
        XCTAssert(carePlans.first?.title == "Diabetes Type II Care Plan")
    }

    func testKeepingRemoteVersionOfCarePlanConflict() throws {
        let carePlanA = try store.addCarePlanAndWait(OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil))

        var carePlanB = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Type II Care Plan", patientUUID: nil)
        carePlanB.uuid = UUID()
        carePlanB.createdDate = carePlanA.createdDate!.addingTimeInterval(-10.0)
        carePlanB.updatedDate = carePlanB.createdDate
        carePlanB.effectiveDate = carePlanB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.carePlan(carePlanB)],
            knowledgeVector: .init())

        let remote = store.remote as? DummyEndpoint
        remote?.conflictPolicy = .keepRemote

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let carePlans = try store.fetchCarePlansAndWait()

        XCTAssert(carePlans.count == 1)
        XCTAssert(carePlans.first?.id == "diabetes_type_1")
        XCTAssert(carePlans.first?.title == "Diabetes Type II Care Plan")
        XCTAssert(carePlans.first?.previousVersionUUID == nil)
    }

    func testKeepingLocalVersionOfCarePlanConflict() throws {
        let carePlanA = try store.addCarePlanAndWait(OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil))

        var carePlanB = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Type II Care Plan", patientUUID: nil)
        carePlanB.uuid = UUID()
        carePlanB.createdDate = carePlanA.createdDate!.addingTimeInterval(-10.0)
        carePlanB.updatedDate = carePlanB.createdDate
        carePlanB.effectiveDate = carePlanB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.carePlan(carePlanB)],
            knowledgeVector: .init())

        let remote = store.remote as? DummyEndpoint
        remote?.conflictPolicy = .keepDevice

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let carePlans = try store.fetchCarePlansAndWait()

        XCTAssert(carePlans.count == 1)
        XCTAssert(carePlans.first?.id == "diabetes_type_1")
        XCTAssert(carePlans.first?.title == "Diabetes Care Plan")
        XCTAssert(carePlans.first?.previousVersionUUID == nil)
    }

    func testCarePlansAddedViaRevisionRecordHaveSameCreatedDateAsRevisionRecord() throws {
        var carePlan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        let date = Calendar.current.startOfDay(for: Date())
        carePlan.createdDate = date
        carePlan = try store.addCarePlanAndWait(carePlan)
        carePlan.uuid = UUID()

        let revision = OCKRevisionRecord(
            entities: [.carePlan(carePlan)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))

        let carePlans = try store.fetchCarePlansAndWait()
        XCTAssert(carePlans.first?.createdDate == date)
    }

    func testCarePlanRevisionsAreIdempotent() throws {
        let carePlan = try store.addCarePlanAndWait(OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil))

        let revision = OCKRevisionRecord(
            entities: [.carePlan(carePlan)],
            knowledgeVector: .init())

        for _ in 0..<3 {
            XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
            XCTAssert(try store.fetchCarePlansAndWait() == [carePlan])
        }
    }

    // MARK: Contacts

    func testAddingNewContactViaRevisionRecord() throws {
        var contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        contact.uuid = UUID()
        contact.createdDate = Date()
        contact.updatedDate = contact.createdDate

        let revision = OCKRevisionRecord(
            entities: [.contact(contact)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let contacts = try store.fetchContactsAndWait()

        XCTAssert(contacts.count == 1)
        XCTAssert(contacts.first?.id == "contact")
    }

    func testUpdatingLatestVersionOfContactViaRevisionRecord() throws {
        let contactA = try store.addContactAndWait(OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil))

        var contactB = OCKContact(id: "contact", givenName: "Amy", familyName: "Frosty", carePlanUUID: nil)
        contactB.uuid = UUID()
        contactB.createdDate = contactA.createdDate!.addingTimeInterval(10.0)
        contactB.updatedDate = contactB.createdDate
        contactB.effectiveDate = contactB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.contact(contactB)],
            knowledgeVector: .init())

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let contacts = try store.fetchContactsAndWait(query: OCKContactQuery(for: contactB.effectiveDate))

        XCTAssert(contacts.count == 1)
        XCTAssert(contacts.first?.id == "contact")
        XCTAssert(contacts.first?.name.familyName == "Frosty")
    }

    func testKeepingRemoteVersionOfContactConflict() throws {
        let contactA = try store.addContactAndWait(OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil))

        var contactB = OCKContact(id: "contact", givenName: "Amy", familyName: "Frosty", carePlanUUID: nil)
        contactB.uuid = UUID()
        contactB.createdDate = contactA.createdDate!.addingTimeInterval(-10.0)
        contactB.updatedDate = contactB.createdDate
        contactB.effectiveDate = contactB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.contact(contactB)],
            knowledgeVector: .init())

        let remote = store.remote as? DummyEndpoint
        remote?.conflictPolicy = .keepRemote

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let contacts = try store.fetchContactsAndWait()

        XCTAssert(contacts.count == 1)
        XCTAssert(contacts.first?.id == "contact")
        XCTAssert(contacts.first?.name.familyName == "Frosty")
        XCTAssert(contacts.first?.previousVersionUUID == nil)
    }

    func testKeepingLocalVersionOfContactConflict() throws {
        let contactA = try store.addContactAndWait(OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil))

        var contactB = OCKContact(id: "contact", givenName: "Amy", familyName: "Frosty", carePlanUUID: nil)
        contactB.uuid = UUID()
        contactB.createdDate = contactA.createdDate!.addingTimeInterval(-10.0)
        contactB.updatedDate = contactB.createdDate
        contactB.effectiveDate = contactB.createdDate!

        let revision = OCKRevisionRecord(
            entities: [.contact(contactB)],
            knowledgeVector: .init())

        let remote = store.remote as? DummyEndpoint
        remote?.conflictPolicy = .keepDevice

        try store.mergeRevisionAndWait(revision)
        try store.context.save()

        let contacts = try store.fetchContactsAndWait()

        XCTAssert(contacts.count == 1)
        XCTAssert(contacts.first?.id == "contact")
        XCTAssert(contacts.first?.name.familyName == "Frost")
        XCTAssert(contacts.first?.previousVersionUUID == nil)
    }

    func testContactsAddedViaRevisionRecordHaveSameCreatedDateAsRevisionRecord() throws {
        var contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        let date = Calendar.current.startOfDay(for: Date())
        contact.createdDate = date
        contact = try store.addContactAndWait(contact)
        contact.uuid = UUID()

        let revision = OCKRevisionRecord(
            entities: [.contact(contact)],
            knowledgeVector: .init())

        XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))

        let contacts = try store.fetchContactsAndWait()
        XCTAssert(contacts.first?.createdDate == date)
    }

    func testContactRevisionsAreIdempotent() throws {
        let contact = try store.addContactAndWait(OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil))

        let revision = OCKRevisionRecord(
            entities: [.contact(contact)],
            knowledgeVector: .init())

        for _ in 0..<3 {
            XCTAssertNoThrow(try store.mergeRevisionAndWait(revision))
            XCTAssert(try store.fetchContactsAndWait() == [contact])
        }
    }

}

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

import AsyncAlgorithms
import XCTest

class MockPatientStore: OCKPatientStore {

    var patients = [OCKPatient]()

    func reset() throws {
        patients = []
    }

    func patients(matching query: OCKPatientQuery) -> AsyncSyncSequence<[[OCKPatient]]> {
        return [patients].async
    }

    func fetchPatients(
        query: OCKPatientQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKPatient]>
    ) {
        callbackQueue.async { completion(.success(self.patients)) }
    }

    func addPatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        self.patients.append(contentsOf: patients)
        callbackQueue.async { completion?(.success(patients)) }
    }

    func updatePatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
    }

    func deletePatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        self.patients = []
        callbackQueue.async { completion?(.success(patients)) }
    }
}

class MockCoordinator: OCKStoreCoordinator {
    private let handler: (OCKAnyPatientStore, OCKAnyPatient) -> Bool

    init(patientStoreHandlesWrite: @escaping (OCKAnyPatientStore, OCKAnyPatient) -> Bool) {
        handler = patientStoreHandlesWrite
    }

    override func patientStore(_ store: OCKAnyPatientStore, shouldHandleWritingPatient patient: OCKAnyPatient) -> Bool {
        handler(store, patient)
    }
}

class TestPersistentStoreCoordinator: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    func testFetchPatientsFromMultipleStores() throws {
        let store1 = MockPatientStore()
        store1.patients = [OCKPatient(id: "A", givenName: "A", familyName: "A")]

        let store2 = MockPatientStore()
        store2.patients = [OCKPatient(id: "B", givenName: "B", familyName: "B")]

        let sut = OCKStoreCoordinator()
        sut.attach(patientStore: store1)
        sut.attach(patientStore: store2)

        let patients = try sut.fetchAnyPatientsAndWait(query: OCKPatientQuery())
        XCTAssert(patients.count == 2)
    }

    func testAddPatientActsOnFirstRespondingStore() throws {
        let store1 = MockPatientStore()
        let store2 = MockPatientStore()
        let sut = OCKStoreCoordinator()
        sut.attach(patientStore: store1)
        sut.attach(patientStore: store2)

        let patient = OCKPatient(id: "A", givenName: "A", familyName: "A")
        try sut.addAnyPatientAndWait(patient)

        XCTAssert(!store1.patients.isEmpty)
        XCTAssert(store2.patients.isEmpty)
    }

    func testAddPatientFailsIfNoStoresRespond() throws {
        let sut = OCKStoreCoordinator()
        let patient = OCKPatient(id: "A", givenName: "A", familyName: "A")
        XCTAssertThrowsError(try sut.addAnyPatientAndWait(patient))
    }

    func testAddPatientsFailsIfPatientsDontAllBelongToTheSameStore() throws {
        let patientA = OCKPatient(id: "A", givenName: "A", familyName: "A")
        let storeA = MockPatientStore()

        let patientB = OCKPatient(id: "B", givenName: "B", familyName: "B")
        let storeB = MockPatientStore()

        let sut = MockCoordinator { store, patient in
            if store === storeA && patient as? OCKPatient == patientA { return true }
            if store === storeB && patient as? OCKPatient == patientB { return true }
            return false
        }

        sut.attach(patientStore: storeA)
        sut.attach(patientStore: storeB)

        XCTAssertThrowsError(try sut.addAnyPatientsAndWait([patientA, patientB]))
    }

    func testAddPatientActsOnFirstRespondingStoreOnly() throws {
        let patient = OCKPatient(id: "A", givenName: "A", familyName: "A")
        let store1 = MockPatientStore()
        let store2 = MockPatientStore()

        let sut = OCKStoreCoordinator()
        sut.attach(patientStore: store1)
        sut.attach(patientStore: store2)

        try sut.addAnyPatientAndWait(patient)

        XCTAssert(!store1.patients.isEmpty)
        XCTAssert(store2.patients.isEmpty)
    }

    @available(iOS 15, watchOS 8, *)
    func testFetchCanResultInAnArrayPopulatedWithDifferentTypes() throws {
        let coordinator = OCKStoreCoordinator()
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        let link = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        let hkStore = OCKHealthKitPassthroughStore(store: store)
        try hkStore.addTaskAndWait(OCKHealthKitTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link))

        let ckStore = OCKStore(name: UUID().uuidString, type: .inMemory)
        try ckStore.addTaskAndWait(OCKTask(id: "B", title: "B", carePlanUUID: nil, schedule: schedule))

        coordinator.attachReadOnly(eventStore: ckStore)
        coordinator.attachReadOnly(eventStore: hkStore)
        coordinator.fetchAnyTasks(query: OCKTaskQuery()) { result in
            let tasks = try? result.get()
            XCTAssert(tasks?.count == 2)
            XCTAssert(tasks?.compactMap { $0 as? OCKTask }.count == 1)
            XCTAssert(tasks?.compactMap { $0 as? OCKHealthKitTask }.count == 1)
        }
    }

    func testPersistentStoreCoordinatorDoesNotSendHealthKitTasksToOCKStore() {
        let coordinator = OCKStoreCoordinator()
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        coordinator.attach(store: store)

        let schedule = OCKSchedule.dailyAtTime(hour: 9, minutes: 0, start: Date(), end: nil, text: nil)
        let link = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        let task = OCKHealthKitTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)

        XCTAssertThrowsError(try coordinator.addAnyTaskAndWait(task))
    }

#if !os(watchOS)
    @available(iOS 15, watchOS 8, *)
    func testStoreCoordinatorDoesNotSendNormalOutcomesToHealthKit() {
        let coordinator = OCKStoreCoordinator()
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        let passthrough = OCKHealthKitPassthroughStore(store: store)
        let outcome = OCKOutcome(taskUUID: UUID(), taskOccurrenceIndex: 0, values: [])
        let willHandle = coordinator.outcomeStore(passthrough, shouldHandleWritingOutcome: outcome)
        XCTAssertFalse(willHandle)
    }

    func testStoreCoordinatorDoesNotSendHealthKitOutcomesToOCKStore() {
        let coordinator = OCKStoreCoordinator()
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        let outcome = OCKHealthKitOutcome(taskUUID: UUID(), taskOccurrenceIndex: 0, values: [])
        let willHandle = coordinator.outcomeStore(store, shouldHandleWritingOutcome: outcome)
        XCTAssertFalse(willHandle)
    }
#endif
    
    @available(iOS 15, watchOS 8, *)
    func testCanAssociateHealthKitTaskWithCarePlan() throws {
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        let passthrough = OCKHealthKitPassthroughStore(store: store)

        let coordinator = OCKStoreCoordinator()
        coordinator.attach(store: store)
        coordinator.attach(eventStore: passthrough)

        let plan = OCKCarePlan(id: "plan", title: "My Plan", patientUUID: nil)
        try coordinator.addAnyCarePlanAndWait(plan)

        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil)
        let task = OCKTask(id: "task", title: "My Task", carePlanUUID: plan.uuid, schedule: schedule)
        try coordinator.addAnyTaskAndWait(task)

        let query = OCKTaskQuery(id: "task")
        let fetched = try coordinator.fetchAnyTasksAndWait(query: query)
        XCTAssert(fetched.first?.belongs(to: plan) == true)
    }
}

@available(iOS 15, watchOS 8, *)
private struct SeededTaskStore {

    let store: OCKStoreCoordinator
    let task: OCKTask

    init() throws {
        let cdStore = OCKStore(name: UUID().uuidString, type: .inMemory)
        let passthrough = OCKHealthKitPassthroughStore(store: cdStore)

        store = OCKStoreCoordinator()
        store.attach(store: cdStore)
        store.attach(eventStore: passthrough)

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: 7, minutes: 0, start: startOfDay, end: nil, text: nil)

        // Add a task to the store

        task = OCKTask(
            id: "cd-Task",
            title: nil,
            carePlanUUID: nil,
            schedule: schedule
        )
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        try cdStore.addAnyTaskAndWait(task)
        try cdStore.addOutcomeAndWait(outcome)
    }
}

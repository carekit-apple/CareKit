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

import AsyncAlgorithms
import Synchronization
import XCTest

final class MockPatientStore: OCKPatientStore {

    private struct State {

        var patients: [OCKPatient] = [] {
            didSet {
                patientsContinuation.yield(patients)
            }
        }

        let patientsStream: AsyncThrowingStream<[OCKPatient], Error>
        let patientsContinuation: AsyncThrowingStream<[OCKPatient], Error>.Continuation

        init() {

            var patientsContinuation: AsyncThrowingStream<[OCKPatient], Error>.Continuation!

            patientsStream = AsyncThrowingStream { cont in
                patientsContinuation = cont
            }

            self.patientsContinuation = patientsContinuation
        }
    }

    private let state = Mutex(State())

    init() {

    }

    func reset() throws {
        state.withLock { state in
            state.patients = []
        }
    }

    func patients(matching query: OCKPatientQuery) -> AsyncThrowingStream<[OCKPatient], Error> {
        return state.withLock { $0.patientsStream }
    }

    func fetchPatients(
        query: OCKPatientQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKPatient]>
    ) {
        callbackQueue.async {
            let patients = self.state.withLock { $0.patients }
            completion(.success(patients))
        }
    }

    func addPatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        let patients = state.withLock { state in
            state.patients.append(contentsOf: patients)
            return state.patients
        }

        callbackQueue.async {
            completion?(.success(patients))
        }
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
        let patients = state.withLock { state in
            state.patients = []
            return state.patients
        }

        callbackQueue.async {
            completion?(.success(patients))
        }
    }
}

final class MockStoreCoordinatorDelegate: OCKStoreCoordinatorDelegate {

    private let shouldHandleWritingPatient: @Sendable (OCKAnyPatientStore, OCKAnyPatient) -> Bool

    init(shouldHandleWritingPatient: @escaping @Sendable (OCKAnyPatientStore, OCKAnyPatient) -> Bool) {
        self.shouldHandleWritingPatient = shouldHandleWritingPatient
    }

    func patientStore(_ store: OCKAnyPatientStore, shouldHandleWritingPatient patient: OCKAnyPatient) -> Bool {
        shouldHandleWritingPatient(store, patient)
    }
}

class TestPersistentStoreCoordinator: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    func testFetchPatientsFromMultipleStores() async throws {
        let store1 = MockPatientStore()
        try await store1.addPatients([OCKPatient(id: "A", givenName: "A", familyName: "A")])

        let store2 = MockPatientStore()
        try await store2.addPatients([OCKPatient(id: "B", givenName: "B", familyName: "B")])

        let sut = OCKStoreCoordinator()
        sut.attach(patientStore: store1)
        sut.attach(patientStore: store2)

        let patients = try await sut.fetchAnyPatients(query: OCKPatientQuery())
        XCTAssertEqual(patients.count, 2)
    }

    func testAddPatientActsOnFirstRespondingStore() async throws {
        let store1 = MockPatientStore()
        let store2 = MockPatientStore()
        let sut = OCKStoreCoordinator()
        sut.attach(patientStore: store1)
        sut.attach(patientStore: store2)

        let patient = OCKPatient(id: "A", givenName: "A", familyName: "A")
        try await sut.addAnyPatient(patient)

        let patients1 = try await store1.fetchPatients(query: OCKPatientQuery())
        let patients2 = try await store2.fetchPatients(query: OCKPatientQuery())

        XCTAssert(!patients1.isEmpty)
        XCTAssert(patients2.isEmpty)
    }

    func testAddPatientFailsIfNoStoresRespond() async throws {
        let sut = OCKStoreCoordinator()
        let patient = OCKPatient(id: "A", givenName: "A", familyName: "A")

        do {
            try await sut.addAnyPatient(patient)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testAddPatientsFailsIfPatientsDontAllBelongToTheSameStore() async throws {
        let patientA = OCKPatient(id: "A", givenName: "A", familyName: "A")
        let storeA = MockPatientStore()

        let patientB = OCKPatient(id: "B", givenName: "B", familyName: "B")
        let storeB = MockPatientStore()

        let coordinator = OCKStoreCoordinator()

        let delegate = MockStoreCoordinatorDelegate(shouldHandleWritingPatient: { store, patient in
            if store === storeA && patient as? OCKPatient == patientA { return true }
            if store === storeB && patient as? OCKPatient == patientB { return true }
            return false
        })

        coordinator.delegate = delegate

        coordinator.attach(patientStore: storeA)
        coordinator.attach(patientStore: storeB)

        do {
            try await coordinator.addAnyPatients([patientA, patientB])
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testAddPatientActsOnFirstRespondingStoreOnly() async throws {
        let patient = OCKPatient(id: "A", givenName: "A", familyName: "A")
        let store1 = MockPatientStore()
        let store2 = MockPatientStore()

        let sut = OCKStoreCoordinator()
        sut.attach(patientStore: store1)
        sut.attach(patientStore: store2)

        try await sut.addAnyPatient(patient)

        let patients1 = try await store1.fetchPatients(query: OCKPatientQuery())
        let patients2 = try await store2.fetchPatients(query: OCKPatientQuery())

        XCTAssert(!patients1.isEmpty)
        XCTAssert(patients2.isEmpty)
    }

    func testFetchCanResultInAnArrayPopulatedWithDifferentTypes() async throws {
        let coordinator = OCKStoreCoordinator()
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        let link = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        let hkStore = OCKHealthKitPassthroughStore(store: store)
        try await hkStore.addTask(OCKHealthKitTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link))

        let ckStore = OCKStore(name: UUID().uuidString, type: .inMemory)
        try await ckStore.addTask(OCKTask(id: "B", title: "B", carePlanUUID: nil, schedule: schedule))

        coordinator.attachReadOnly(eventStore: ckStore)
        coordinator.attachReadOnly(eventStore: hkStore)

        let tasks = try await coordinator.fetchAnyTasks(query: OCKTaskQuery())
        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks.compactMap { $0 as? OCKTask }.count, 1)
        XCTAssertEqual(tasks.compactMap { $0 as? OCKHealthKitTask }.count, 1)
    }

    func testPersistentStoreCoordinatorDoesNotSendHealthKitTasksToOCKStore() async {
        let coordinator = OCKStoreCoordinator()
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        coordinator.attach(store: store)

        let schedule = OCKSchedule.dailyAtTime(hour: 9, minutes: 0, start: Date(), end: nil, text: nil)
        let link = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        let task = OCKHealthKitTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)

        do {
            try await coordinator.addAnyTask(task)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    #if !os(watchOS)
    func testStoreCoordinatorDoesNotSendNormalOutcomesToHealthKit() throws {
        let coordinator = OCKStoreCoordinator()
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        let passthrough = OCKHealthKitPassthroughStore(store: store)
        let outcome = OCKOutcome(taskUUID: UUID(), taskOccurrenceIndex: 0, values: [])
        let willHandle = try XCTUnwrap(coordinator.delegate?.outcomeStore(passthrough, shouldHandleWritingOutcome: outcome))
        XCTAssertFalse(willHandle)
    }

    func testStoreCoordinatorDoesNotSendHealthKitOutcomesToOCKStore() throws {
        let coordinator = OCKStoreCoordinator()
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        let outcome = OCKHealthKitOutcome(taskUUID: UUID(), taskOccurrenceIndex: 0, values: [])
        let willHandle = try XCTUnwrap(coordinator.delegate?.outcomeStore(store, shouldHandleWritingOutcome: outcome))
        XCTAssertFalse(willHandle)
    }
    #endif
    
    func testCanAssociateHealthKitTaskWithCarePlan() async throws {
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        let passthrough = OCKHealthKitPassthroughStore(store: store)

        let coordinator = OCKStoreCoordinator()
        coordinator.attach(store: store)
        coordinator.attach(eventStore: passthrough)

        let plan = OCKCarePlan(id: "plan", title: "My Plan", patientUUID: nil)
        try await coordinator.addAnyCarePlan(plan)

        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil)
        let task = OCKTask(id: "task", title: "My Task", carePlanUUID: plan.uuid, schedule: schedule)
        try await coordinator.addAnyTask(task)

        let query = OCKTaskQuery(id: "task")
        let fetched = try await coordinator.fetchAnyTasks(query: query)
        XCTAssertEqual(fetched.first?.belongs(to: plan), true)
    }
}

private struct SeededTaskStore {

    let store: OCKStoreCoordinator
    let task: OCKTask

    init() async throws {
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
        try await cdStore.addAnyTask(task)
        try await cdStore.addOutcome(outcome)
    }
}

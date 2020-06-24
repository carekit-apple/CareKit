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

class MockPatientStore: OCKAnyPatientStore {
    var patients = [OCKAnyPatient]()

    weak var patientDelegate: OCKPatientStoreDelegate?

    func fetchAnyPatients(query: OCKAnyPatientQuery, callbackQueue: DispatchQueue,
                          completion: @escaping OCKResultClosure<[OCKAnyPatient]>) {
        callbackQueue.async { completion(.success(self.patients)) }
    }

    func addAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?) {
        self.patients.append(contentsOf: patients)
        callbackQueue.async { completion?(.success(patients)) }
    }

    func updateAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?) {
    }

    func deleteAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?) {
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

    func testFetchCanResultInAnArrayPopulatedWithDifferentTypes() throws {
        let coordinator = OCKStoreCoordinator()
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let link = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        let hkStore = OCKHealthKitPassthroughStore(name: "HK", type: .inMemory)
        try hkStore.addTaskAndWait(OCKHealthKitTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link))

        let ckStore = OCKStore(name: "CK", type: .inMemory)
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
        let store = OCKStore(name: "store", type: .inMemory)
        coordinator.attach(store: store)

        let schedule = OCKSchedule.dailyAtTime(hour: 9, minutes: 0, start: Date(), end: nil, text: nil)
        let link = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        let task = OCKHealthKitTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)

        XCTAssertThrowsError(try coordinator.addAnyTaskAndWait(task))
    }
}

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
import UIKit.UIDevice
import XCTest

class TestStoreSyncOverwrite: XCTestCase {

    // MARK: Overwrite Device with Remote

    func testOverwriteDevice() throws {
        let remote = DummyEndpoint()
        remote.automaticallySynchronizes = false
        remote.revision = remote.dummyRevision()

        let store = OCKStore(name: "test", type: .inMemory, remote: remote)

        let patient = OCKPatient(id: "abc", givenName: "A", familyName: "B")
        try store.addPatientAndWait(patient)

        let carePlan = OCKCarePlan(id: "diabetes_type_2", title: "Diabetes 2 Care Plan", patientUUID: nil)
        try store.addCarePlanAndWait(carePlan)

        let contact = OCKContact(id: "contact2", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        try store.addContactAndWait(contact)

        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "a", title: "New Title", carePlanUUID: nil, schedule: schedule)
        try task = store.addTaskAndWait(task)

        let outcome = OCKOutcome(taskUUID: task.uuid!, taskOccurrenceIndex: 0, values: [OCKOutcomeValue(5)])
        try store.addOutcomeAndWait(outcome)

        XCTAssertNoThrow(try store.syncAndWait(mode: .overwriteDeviceRecordsWithRemote))
        XCTAssert(try store.fetchPatientsAndWait().count == 1)
        XCTAssert(try store.fetchCarePlansAndWait().count == 1)
        XCTAssert(try store.fetchContactsAndWait().count == 1)
        XCTAssert(try store.fetchTasksAndWait().count == 1)
        XCTAssert(try store.fetchOutcomesAndWait().count == 1)
    }

    func testOverwriteDeviceUpdatesKnowledgeVector() {
        let remote = DummyEndpoint()
        let store = OCKStore(name: "test", type: .inMemory, remote: remote)
        XCTAssert(store.context.clockTime == 0)
        XCTAssertNoThrow(try store.syncAndWait(mode: .overwriteDeviceRecordsWithRemote))
        XCTAssert(store.context.clockTime == 1)
    }

    func testOverwriteDeviceCannotBeRunIfAlreadySyncing() {
        let remote = DummyEndpoint()
        remote.delay = 30
        let store = OCKStore(name: "test", type: .inMemory, remote: remote)
        store.synchronize(policy: .overwriteDeviceRecordsWithRemote, completion: { _ in })
        XCTAssertThrowsError(try store.syncAndWait(mode: .overwriteDeviceRecordsWithRemote))
    }

    func testOverwriteDeviceSyncUpdatesKnowledgeVector() throws {
        let remote = DummyEndpoint()
        let store = OCKStore(name: "test", type: .inMemory, remote: remote)
        XCTAssert(store.context.clockTime == 0)

        XCTAssertNoThrow(try store.syncAndWait(mode: .overwriteDeviceRecordsWithRemote))
        XCTAssert(store.context.clockTime == 1)
    }

    // MARK: Overwrite Remote with Device

    func testOverwriteRemote() throws {
        let remote = DummyEndpoint()
        let store = OCKStore(name: "test", type: .inMemory, remote: remote)
        try store.syncAndWait(mode: .overwriteRemoteWithDeviceRecords)
        XCTAssert(remote.timesPushWasCalled == 1)
    }
}

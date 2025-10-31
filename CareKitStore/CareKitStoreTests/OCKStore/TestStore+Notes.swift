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

class TestStoreNotes: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }

    func testCanAttachNotesToPatient() async throws {
        var patient = OCKPatient(id: "Mr. John", givenName: "John", familyName: "Appleseed")
        patient.notes = [OCKNote(author: "Johnny", title: "My Diary", content: "Today I studied biochemistry!")]
        let savedPatient = try await store.addPatient(patient)
        XCTAssertEqual(savedPatient.notes?.count, 1)
    }

    func testCanAttachNotesToCarePlan() async throws {
        var plan = OCKCarePlan(id: "obesity", title: "Obesity", patientUUID: nil)
        plan.notes = [OCKNote(author: "Mariana", title: "Refrigerator Notes", content: "Butter, milk, eggs")]
        let savedPlan = try await store.addCarePlan(plan)
        XCTAssertEqual(savedPlan.notes?.count, 1)
    }

    func testCanAttachNotesToTask() async throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 06, minutes: 0, start: Date(), end: nil, text: nil)
        var task = OCKTask(id: "id123", title: "prayer", carePlanUUID: nil, schedule: schedule)
        task.notes = [OCKNote(author: "Jared", title: "Note", content: "Made some remarks")]
        let savedTask = try await store.addTask(task)
        XCTAssertEqual(savedTask.notes?.count, 1)
    }

    func testCanAttachNotesToOutcome() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        var outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        outcome.notes = [OCKNote(author: "Jared", title: "My Recipe", content: "Bacon, eggs, and cheese")]
        let savedOutcome = try await store.addOutcome(outcome)
        XCTAssertEqual(savedOutcome.notes?.count, 1)
    }
}

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

class TestStoreNotes: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "TestDatabase", type: .inMemory)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    func testCanAttachNotesToPatient() throws {
        var patient = OCKPatient(id: "Mr. John", givenName: "John", familyName: "Appleseed")
        patient.notes = [OCKNote(author: "Johnny", title: "My Diary", content: "Today I studied biochemistry!")]
        let savedPatient = try store.addPatientAndWait(patient)
        XCTAssert(savedPatient.notes?.count == 1)
    }

    func testCanAttachNotesToCarePlan() throws {
        var plan = OCKCarePlan(id: "obesity", title: "Obesity", patientID: nil)
        plan.notes = [OCKNote(author: "Mariana", title: "Refrigerator Notes", content: "Butter, milk, eggs")]
        let savedPlan = try store.addCarePlanAndWait(plan)
        XCTAssert(savedPlan.notes?.count == 1)
    }

    func testCanAttachNotesToTask() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 06, minutes: 0, start: Date(), end: nil, text: nil)
        var task = OCKTask(id: "id123", title: "prayer", carePlanID: nil, schedule: schedule)
        task.notes = [OCKNote(author: "Jared", title: "Note", content: "Made some remarks")]
        let savedTask = try store.addTaskAndWait(task)
        XCTAssert(savedTask.notes?.count == 1)
    }

    func testCanAttachNotesToOutcome() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanID: nil, schedule: schedule))
        var outcome = OCKOutcome(taskID: try task.getLocalID(), taskOccurrenceIndex: 0, values: [])
        outcome.notes = [OCKNote(author: "Jared", title: "My Recipe", content: "Bacon, eggs, and cheese")]
        let savedOutcome = try store.addOutcomeAndWait(outcome)
        XCTAssert(savedOutcome.notes?.count == 1)
    }

    func testCanAttachNotesToOutcomeValues() throws {
        var task = OCKTask(id: "A", title: "A", carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)

        var value = OCKOutcomeValue(10.0)
        value.notes = [OCKNote(author: "Amy", title: "High Temperature",
                               content: "Stopped taking medication because it gave me a fever")]
        let outcome = OCKOutcome(taskID: try task.getLocalID(), taskOccurrenceIndex: 0, values: [value])
        let savedOutcome = try store.addOutcomeAndWait(outcome)
        XCTAssertNotNil(savedOutcome.values.first?.notes?.first)
    }

    func testCanSaveNotesOnNotes() throws {
        var note = OCKNote(author: "Mr. A", title: "Title A", content: "Content A")
        note.notes = [OCKNote(author: "Mr. B", title: "Title B", content: "Content B")]
        var patient = OCKPatient(id: "johnny", givenName: "John", familyName: "Appleseed")
        patient.notes = [note]
        let savedPatient = try store.addPatientAndWait(patient)
        XCTAssertNotNil(savedPatient.notes?.first?.notes?.first)
    }

    func testPersistedNotesHaveTimeZones() throws {
        let note = OCKNote(author: "Mr. A", title: "Title A", content: "Content A")
        var patient = OCKPatient(id: "johnny", givenName: "John", familyName: "Appleseed")
        patient.notes = [note]

        let savedPatient = try store.addPatientAndWait(patient)
        XCTAssert(savedPatient.timezone == TimeZone.current)
        XCTAssert(savedPatient.notes?.first?.timezone == TimeZone.current)
    }
}

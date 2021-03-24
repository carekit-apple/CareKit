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

class TestStoreOutcomes: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }

    // MARK: Insertion

    func testAddAndFetchOutcomes() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        var value = OCKOutcomeValue(42)
        value.kind = "number"

        var outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [value])
        outcome = try store.addOutcomeAndWait(outcome)

        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes == [outcome])
        XCTAssert(outcomes.first?.values.first?.kind == "number")
        XCTAssertNotNil(outcomes.first?.taskUUID)
        XCTAssertNotNil(outcomes.first?.schemaVersion)
    }

    func testAddOutcomeToTask() throws {
        var task = OCKTask(id: "task", title: "My Task", carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)
        let taskUUID = task.uuid

        var outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 2, values: [])
        outcome = try store.addOutcomeAndWait(outcome)
        XCTAssert(outcome.taskUUID == taskUUID)
    }

    func testTwoOutcomesWithoutSameTaskUUIDAndOccurrenceIndexCannotBeAdded() throws {
        var task = OCKTask(id: "task", title: "My Task", carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)
        let taskUUID = task.uuid

        let outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 2, values: [])
        XCTAssertThrowsError(try store.addOutcomesAndWait([outcome, outcome]))
    }

    func testCannotAddOutcomeToCoveredRegionOfPreviousTaskVersion() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.mealTimesEachDay(start: thisMorning, end: nil)
        let task = OCKTask(id: "meds", title: "Medications", carePlanUUID: nil, schedule: schedule)
        let taskV1 = try store.addTaskAndWait(task)
        let taskV2 = try store.updateTaskAndWait(task)
        let value = OCKOutcomeValue(123)
        let outcome = OCKOutcome(taskUUID: taskV1.uuid, taskOccurrenceIndex: 1, values: [value])
        XCTAssert(taskV2.previousVersionUUIDs.first == taskV1.uuid)
        XCTAssertThrowsError(try store.addOutcomeAndWait(outcome))
    }

    func testCannotUpdateOutcomeToCoveredRegionOfPreviousTaskVersion() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tomorrowMorning = Calendar.current.date(byAdding: .day, value: 1, to: thisMorning)!
        let schedule = OCKSchedule.mealTimesEachDay(start: thisMorning, end: nil)

        var task = OCKTask(id: "meds", title: "Medications", carePlanUUID: nil, schedule: schedule)
        let taskV1 = try store.addTaskAndWait(task)

        task.effectiveDate = tomorrowMorning
        try store.updateTaskAndWait(task)

        let value = OCKOutcomeValue(123)
        var outcome = OCKOutcome(taskUUID: taskV1.uuid, taskOccurrenceIndex: 0, values: [value])
        outcome = try store.addOutcomeAndWait(outcome)
        outcome.taskOccurrenceIndex = 8
        XCTAssertThrowsError(try store.updateOutcomeAndWait(outcome))
    }

    // MARK: Querying

    func testOutcomeQueryGroupIdentifier() throws {
        var task = OCKTask(id: "abc", title: "ABC", carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)
        let value = OCKOutcomeValue(42)
        var outcomeA = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [value])
        outcomeA.groupIdentifier = "A"
        var outcomeB = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 1, values: [value])
        outcomeB.groupIdentifier = "B"
        try store.addOutcomesAndWait([outcomeA, outcomeB])
        var query = OCKOutcomeQuery(for: Date())
        query.groupIdentifiers = ["A"]
        let fetched = try store.fetchOutcomesAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.taskOccurrenceIndex == 0)
    }

    func testQueryReturnsOnlyOutcomesInTheQueryDateRange() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "exercise", title: "Push Ups", carePlanUUID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        let taskUUID = task.uuid

        let date1 = task.schedule[0].start.addingTimeInterval(-10)
        let date2 = task.schedule[1].start.addingTimeInterval(-10)
        let interval = DateInterval(start: date1, end: date2)
        let outcome1 = try store.addOutcomeAndWait(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        let outcome2 = try store.addOutcomeAndWait(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 1, values: []))
        var query = OCKOutcomeQuery(dateInterval: interval)
        query.taskIDs = [task.id]
        let outcomes = try store.fetchOutcomesAndWait(query: query)
        XCTAssert(outcomes.count == 1)
        XCTAssertTrue(outcomes.contains(outcome1))
        XCTAssertFalse(outcomes.contains(outcome2))
    }

    func testQueryIncludesEventsThatStartBeforeAndEndDuringOrAfterDateRange() throws {
        let eventStart = Calendar.current.startOfDay(for: Date())
        let queryStart = Calendar.current.date(byAdding: .day, value: 2, to: eventStart)!

        let element = OCKScheduleElement(
            start: eventStart, end: nil,
            interval: DateComponents(month: 3), text: nil,
            targetValues: [], duration: .hours(100))
        let schedule = OCKSchedule(composing: [element])
        var task = OCKTask(id: "a", title: "A", carePlanUUID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)

        let outcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: 0,
            values: [])
        try store.addOutcomeAndWait(outcome)

        let query = OCKOutcomeQuery(for: queryStart)
        let fetched = try store.fetchOutcomesAndWait(query: query)
        XCTAssert(fetched.count == 1)
    }

    func testOutcomeQueryLimit() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcomeA = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [OCKOutcomeValue(10)])
        let outcomeB = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 1, values: [OCKOutcomeValue(20)])
        try store.addOutcomesAndWait([outcomeA, outcomeB])
        var query = OCKOutcomeQuery(for: Date())
        query.limit = 1
        let fetched = try store.fetchOutcomesAndWait(query: query)
        XCTAssert(fetched.count == 1)
    }

    func testQueryOutcomesByRemoteID() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        var outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [])
        outcome.remoteID = "abc"
        outcome = try store.addOutcomeAndWait(outcome)

        var query = OCKOutcomeQuery()
        query.remoteIDs = ["abc"]

        let fetched = try store.fetchOutcomesAndWait(query: query).first
        XCTAssert(fetched == outcome)
    }

    func testQueryOutcomeByTaskRemoteID() throws {
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task.remoteID = "abc"
        task = try store.addTaskAndWait(task)

        var outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        outcome = try store.addOutcomeAndWait(outcome)

        var query = OCKOutcomeQuery(for: Date())
        query.taskRemoteIDs = ["abc"]
        let fetched = try store.fetchOutcomesAndWait(query: query).first
        XCTAssert(fetched == outcome)
    }

    func testQueryOutcomeByTag() throws {
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)

        var outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        outcome.tags = ["123"]
        outcome = try store.addOutcomeAndWait(outcome)

        var query = OCKOutcomeQuery(for: Date())
        query.tags = ["123"]

        let fetched = try store.fetchOutcomesAndWait(query: query).first
        XCTAssert(fetched == outcome)
    }

    func testQueryOutcomeByUUID() throws {
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)

        var outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        outcome = try store.addOutcomeAndWait(outcome)

        var query = OCKOutcomeQuery(for: Date())
        query.uuids = [outcome.uuid]

        let fetched = try store.fetchOutcomesAndWait(query: query).first
        XCTAssert(fetched == outcome)
    }

    // MARK: Updating

    func testUpdateOutcomes() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcomeA = try store.addOutcomeAndWait(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        let outcomeB = try store.updateOutcomeAndWait(outcomeA)
        XCTAssert(outcomeB.id == outcomeA.id)
    }

    func testUpdateFailsForUnsavedOutcomes() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [])
        XCTAssertThrowsError(try store.updateOutcomeAndWait(outcome))
    }

    // MARK: Deletion

    func testDeleteOutcome() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcome = try store.addOutcomeAndWait(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        try store.deleteOutcomeAndWait(outcome)
        let fetched = try store.fetchOutcomesAndWait()
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteOutcomeFailsIfOutcomeDoesntExist() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        XCTAssertThrowsError(try store.deleteOutcomeAndWait(outcome))
    }

    // MARK: - Versioning

    func testDeleteThenAddOutcomeFetchesLatestVersion() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcomeA = try store.addOutcomeAndWait(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        try store.deleteOutcomeAndWait(outcomeA)
        let outcomeB = try store.addOutcomeAndWait(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        let fetched = try store.fetchOutcomesAndWait()

        // Make sure the latest version is fetched
        XCTAssertEqual(fetched.count, 1)

        // IDs should all match
        XCTAssertEqual(outcomeA.id, outcomeB.id)
        XCTAssertEqual(outcomeB.id, fetched.first?.id)
    }
}

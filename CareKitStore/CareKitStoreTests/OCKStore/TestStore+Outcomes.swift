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


class TestStoreOutcomes: XCTestCase {

    private let calendar = Calendar.current

    private lazy var beginningOfYear: Date = {
        let components = DateComponents(year: 2_023, month: 1, day: 1)
        let date = calendar.date(from: components)!
        return date
    }()

    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }

    // MARK: Insertion

    func testAddAndFetchOutcomes() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        var value = OCKOutcomeValue(42)
        value.kind = "number"

        var outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [value])
        outcome = try await store.addOutcome(outcome)

        let outcomes = try await store.fetchOutcomes(query: OCKOutcomeQuery())
        XCTAssertEqual(outcomes, [outcome])
        XCTAssertEqual(outcomes.first?.values.first?.kind, "number")
        XCTAssertNotNil(outcomes.first?.taskUUID)
        XCTAssertNotNil(outcomes.first?.schemaVersion)
    }

    func testAddOutcomeToTask() async throws {
        var task = OCKTask(id: "task", title: "My Task", carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try await store.addTask(task)
        let taskUUID = task.uuid

        var outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 2, values: [])
        outcome = try await store.addOutcome(outcome)
        XCTAssertEqual(outcome.taskUUID, taskUUID)
    }

	func testAddMultipleOutcomesRelatedToMultipleTasks() async throws {
		let task1 = OCKTask(
			id: "task1",
			title: "My Task",
			carePlanUUID: nil,
			schedule: .mealTimesEachDay(
				start: Date(),
				end: nil
			)
		)
		let task2 = OCKTask(
			id: "task2",
			title: "My Task2",
			carePlanUUID: nil,
			schedule: .mealTimesEachDay(
				start: Date(),
				end: nil
			)
		)
		let savedTasks = try await store.addTasks(
			[
				task1,
				task2
			]
		)

		let savedTask1 = try XCTUnwrap(savedTasks.first)
		let savedTask2 = try XCTUnwrap(savedTasks.last)
		XCTAssertEqual(savedTasks.count, 2)
		XCTAssertNotEqual(savedTask1.uuid, savedTask2.uuid)
		XCTAssertNotEqual(savedTask1.id, savedTask2.id)

		let outcome1 = OCKOutcome(
			taskUUID: savedTask1.uuid,
			taskOccurrenceIndex: 1,
			values: []
		)
		let outcome2 = OCKOutcome(
			taskUUID: savedTask2.uuid,
			taskOccurrenceIndex: 1,
			values: []
		)
		let savedOutcomes = try await store.addOutcomes(
			[
				outcome1,
				outcome2
			]
		)
		let savedOutcome1 = try XCTUnwrap(savedOutcomes.first)
		let savedOutcome2 = try XCTUnwrap(savedOutcomes.last)
		XCTAssertEqual(savedOutcomes.count, 2)
		XCTAssertNotEqual(savedOutcome1.uuid, savedOutcome2.uuid)
		XCTAssertNotNil(
			savedTasks.first(
				where: { $0.uuid == savedOutcome1.taskUUID }
			) != nil
		)
		XCTAssertNotNil(
			savedTasks.first(
				where: { $0.uuid == savedOutcome2.taskUUID }
			) != nil
		)
	}

    func testCannotAddTwoOutcomesWithSameTaskAndOccurrenceIndexAtOnce() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 2, values: [])

        do {
            try await store.addOutcomes([outcome, outcome])
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testCannotAddTwoOutcomesWithSameTaskAndOccurenceIndexSequentially() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        let outcomeA = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 2, values: [])
        try await store.addOutcome(outcomeA)

        let outcomeB = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 2, values: [])

        do {
            try await store.addOutcome(outcomeB)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testCanAddTwoOutcomesWithSameTaskAndOccurrenceIfFirstIsDeleted() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        let outcomeA = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        try await store.addOutcome(outcomeA)
        try await store.deleteOutcome(outcomeA)

        let outcomeB = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        try await store.addOutcome(outcomeB)
    }

    func testCannotAddOutcomeToCoveredRegionOfPreviousTaskVersion() async throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.mealTimesEachDay(start: thisMorning, end: nil)
        let task = OCKTask(id: "meds", title: "Medications", carePlanUUID: nil, schedule: schedule)
        let taskV1 = try await store.addTask(task)
        let taskV2 = try await store.updateTask(task)
        let value = OCKOutcomeValue(123)
        let outcome = OCKOutcome(taskUUID: taskV1.uuid, taskOccurrenceIndex: 1, values: [value])
        XCTAssertEqual(taskV2.previousVersionUUIDs.first, taskV1.uuid)

        do {
            try await store.addOutcome(outcome)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testCannotUpdateOutcomeToCoveredRegionOfPreviousTaskVersion() async throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let tomorrowMorning = Calendar.current.date(byAdding: .day, value: 1, to: thisMorning)!
        let schedule = OCKSchedule.dailyAtTime(hour: 1, minutes: 0, start: thisMorning, end: nil, text: nil)

        var task = OCKTask(id: "meds", title: "Medications", carePlanUUID: nil, schedule: schedule)
        let taskV1 = try await store.addTask(task)

        task.effectiveDate = tomorrowMorning
        try await store.updateTask(task)

        let value = OCKOutcomeValue(123)
        var outcome = OCKOutcome(taskUUID: taskV1.uuid, taskOccurrenceIndex: 0, values: [value])
        outcome = try await store.addOutcome(outcome)
        outcome.taskOccurrenceIndex = 8

        do {
            try await store.updateOutcome(outcome)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testAddOutcomeWithInvalidOccurrenceIndex() async throws {

        // Create a daily tasks with one occurrence

        let scheduleEnd = calendar.date(byAdding: .second, value: 1, to: beginningOfYear)!
        let daily = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: beginningOfYear, end: scheduleEnd, text: nil)
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: daily)

        let storedTask = try await store.addTask(task)

        // Try to store an invalid outcome

        let outcome = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 5, values: [])

        do {
            _ = try await store.addOutcome(outcome)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testCanSaveOutcomesForDifferentTasks() async throws {

        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let taskA = OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule)
        let taskB = OCKTask(id: "B", title: "B", carePlanUUID: nil, schedule: schedule)
        _ = try await store.addTasks([taskA, taskB])

        let outcomeA = OCKOutcome(taskUUID: taskA.uuid, taskOccurrenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskUUID: taskB.uuid, taskOccurrenceIndex: 0, values: [])

        _ = try await store.addOutcomes([outcomeA, outcomeB])

        let persistedOutcomes = try await store.fetchOutcomes(query: OCKOutcomeQuery())
        XCTAssertEqual(persistedOutcomes.count, 2)
    }

    // MARK: Querying

    func testOutcomeQueryGroupIdentifier() async throws {
        var task = OCKTask(id: "abc", title: "ABC", carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try await store.addTask(task)
        let value = OCKOutcomeValue(42)
        var outcomeA = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [value])
        outcomeA.groupIdentifier = "A"
        var outcomeB = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 1, values: [value])
        outcomeB.groupIdentifier = "B"
        try await store.addOutcomes([outcomeA, outcomeB])
        var query = OCKOutcomeQuery(for: Date())
        query.groupIdentifiers = ["A"]
        let fetched = try await store.fetchOutcomes(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.taskOccurrenceIndex, 0)
    }

    func testQueryReturnsOnlyOutcomesInTheQueryDateRange() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "exercise", title: "Push Ups", carePlanUUID: nil, schedule: schedule)
        task = try await store.addTask(task)
        let taskUUID = task.uuid

        let date1 = task.schedule[0].start.addingTimeInterval(-10)
        let date2 = task.schedule[1].start.addingTimeInterval(-10)
        let interval = DateInterval(start: date1, end: date2)
        let outcome1 = try await store.addOutcome(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        let outcome2 = try await store.addOutcome(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 1, values: []))
        var query = OCKOutcomeQuery(dateInterval: interval)
        query.taskIDs = [task.id]
        let outcomes = try await store.fetchOutcomes(query: query)
        XCTAssertEqual(outcomes.count, 1)
        XCTAssertTrue(outcomes.contains(outcome1))
        XCTAssertFalse(outcomes.contains(outcome2))
    }

    func testQueryIncludesEventsThatStartBeforeAndEndDuringOrAfterDateRange() async throws {
        let eventStart = Calendar.current.startOfDay(for: Date())
        let queryStart = Calendar.current.date(byAdding: .day, value: 2, to: eventStart)!

        let element = OCKScheduleElement(
            start: eventStart, end: nil,
            interval: DateComponents(month: 3), text: nil,
            targetValues: [], duration: .hours(100))
        let schedule = OCKSchedule(composing: [element])
        var task = OCKTask(id: "a", title: "A", carePlanUUID: nil, schedule: schedule)
        task = try await store.addTask(task)

        let outcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: 0,
            values: [])
        try await store.addOutcome(outcome)

        let query = OCKOutcomeQuery(for: queryStart)
        let fetched = try await store.fetchOutcomes(query: query)
        XCTAssertEqual(fetched.count, 1)
    }

    func testOutcomeQueryLimit() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcomeA = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [OCKOutcomeValue(10)])
        let outcomeB = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 1, values: [OCKOutcomeValue(20)])
        try await store.addOutcomes([outcomeA, outcomeB])
        var query = OCKOutcomeQuery(for: Date())
        query.limit = 1
        let fetched = try await store.fetchOutcomes(query: query)
        XCTAssertEqual(fetched.count, 1)
    }

    func testQueryOutcomesByRemoteID() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        var outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [])
        outcome.remoteID = "abc"
        outcome = try await store.addOutcome(outcome)

        var query = OCKOutcomeQuery()
        query.remoteIDs = ["abc"]

        let fetched = try await store.fetchOutcomes(query: query).first
        XCTAssertEqual(fetched, outcome)
    }

    func testQueryOutcomeByTaskRemoteID() async throws {
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task.remoteID = "abc"
        task = try await store.addTask(task)

        var outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        outcome = try await store.addOutcome(outcome)

        var query = OCKOutcomeQuery(for: Date())
        query.taskRemoteIDs = ["abc"]
        let fetched = try await store.fetchOutcomes(query: query).first
        XCTAssertEqual(fetched, outcome)
    }

    func testQueryOutcomeByTag() async throws {
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try await store.addTask(task)

        var outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        outcome.tags = ["123"]
        outcome = try await store.addOutcome(outcome)

        var query = OCKOutcomeQuery(for: Date())
        query.tags = ["123"]

        let fetched = try await store.fetchOutcomes(query: query).first
        XCTAssertEqual(fetched, outcome)
    }

    func testQueryOutcomeByUUID() async throws {
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try await store.addTask(task)

        var outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])
        outcome = try await store.addOutcome(outcome)

        var query = OCKOutcomeQuery(for: Date())
        query.uuids = [outcome.uuid]

        let fetched = try await store.fetchOutcomes(query: query).first
        XCTAssertEqual(fetched, outcome)
    }

    func testFetchOutcomeReturnsLatestVersionEffectiveAfterPreviousVersion() async throws {

        // Effective A:        |--------------
        // Effective B:          |------------

        // Generate a task

        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: beginningOfYear, end: nil, text: nil)
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: schedule)
        let storedTask = try await store.addTask(task)

        // Generate an outcome

        let outcomeA = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeA = try await store.addOutcome(outcomeA)

        // Update the outcome, effective after the previous version

        var outcomeB = storedOutcomeA
        outcomeB.effectiveDate = outcomeA.effectiveDate + 1
        let storedOutcomeB = try await store.updateOutcome(outcomeB)

        // Fetch outcome. Expecting to receive outcome B

        let query = OCKOutcomeQuery(for: schedule[0].start)
        let outcomes = try await store.fetchOutcomes(query: query)

        XCTAssertEqual(outcomes, [storedOutcomeB])
    }

    func testFetchOutcomeReturnsLatestVersionEffectiveBeforePreviousVersion() async throws {

        // Effective A:        |--------------
        // Effective B:     |-----------------

        // Generate a task

        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: beginningOfYear, end: nil, text: nil)
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: schedule)
        let storedTask = try await store.addTask(task)

        // Generate an outcome

        let outcomeA = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        var storedOutcomeA = try await store.addOutcome(outcomeA)

        // Update the outcome, effective after the previous version

        var outcomeB = storedOutcomeA
        outcomeB.effectiveDate = outcomeA.effectiveDate - 1
        _ = try await store.updateOutcome(outcomeB)

        // Fetch latest updates to outcome A

        var outcomeAQuery = OCKOutcomeQuery()
        outcomeAQuery.uuids = [storedOutcomeA.uuid]
        storedOutcomeA = try await store.fetchOutcome(query: outcomeAQuery)

        // Fetch outcome. Expecting to receive outcome A

        let query = OCKOutcomeQuery(for: schedule[0].start)
        let outcomes = try await store.fetchOutcomes(query: query)

        XCTAssertEqual(outcomes, [storedOutcomeA])
    }

    func testFetchOutcomeReturnsLatestVersionEffectiveAtSameTimeAsPreviousVersion() async throws {

        // Effective A:     |--------------
        // Effective B:     |--------------

        // Generate a task

        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: beginningOfYear, end: nil, text: nil)
        let task = OCKTask(id: "steps", title: nil, carePlanUUID: nil, schedule: schedule)
        let storedTask = try await store.addTask(task)

        // Generate an outcome

        let outcomeA = OCKOutcome(taskUUID: storedTask.uuid, taskOccurrenceIndex: 0, values: [])
        let storedOutcomeA = try await store.addOutcome(outcomeA)

        // Update the outcome, effective after the previous version

        var outcomeB = storedOutcomeA
        outcomeB.effectiveDate = outcomeA.effectiveDate
        let storedOutcomeB = try await store.updateOutcome(outcomeB)

        // Fetch outcome. Expecting to receive outcomeA

        let query = OCKOutcomeQuery(for: schedule[0].start)
        let outcomes = try await store.fetchOutcomes(query: query)

        XCTAssertEqual(outcomes, [storedOutcomeB])
    }

    func testQueryOutcomeForEventWithNoDuration() async throws {

        let now = Date()

        let scheduleElement = OCKScheduleElement(
            start: now,
            end: nil,
            interval: DateComponents(year: 1),
            duration: .seconds(0)  // No duration!
        )

        let task = OCKTask(
            id: "task",
            title: nil,
            carePlanUUID: nil,
            schedule: OCKSchedule(composing: [scheduleElement])
        )

        let storedTask = try await store.addTask(task)

        // Store an outcome for the first event
        let outcome = OCKOutcome(
            taskUUID: storedTask.uuid,
            taskOccurrenceIndex: 0,
            values: []
        )

        let storedOutcome = try await store.addOutcome(outcome)

        // Make sure we can fetch the outcome for the first event, even though it has no duration
        let firstEvent = scheduleElement[0]
        let queryInterval = DateInterval(start: firstEvent.start, end: firstEvent.end + 1)
        let query = OCKOutcomeQuery(dateInterval: queryInterval)

        let outcomes = try await store.fetchOutcomes(query: query)

        XCTAssertEqual(outcomes, [storedOutcome])
    }

    // MARK: Updating

    func testUpdateOutcomes() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcomeA = try await store.addOutcome(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        let outcomeB = try await store.updateOutcome(outcomeA)
        XCTAssertEqual(outcomeB.id, outcomeA.id)
    }

    func testUpdateFailsForUnsavedOutcomes() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcome = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [])

        do {
            try await store.updateOutcome(outcome)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    // MARK: Deletion

    func testDeleteOutcome() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcome = try await store.addOutcome(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        try await store.deleteOutcome(outcome)
        let fetched = try await store.fetchOutcomes(query: OCKOutcomeQuery())
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteOutcomeFailsIfOutcomeDoesntExist() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [])

        do {
            try await store.deleteOutcome(outcome)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testCannotUpdateOutcomeAfterDeleting() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = task.uuid

        let outcome = try await store.addOutcome(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: []))
        try await store.deleteOutcome(outcome)

        let update = OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [])

        do {
            try await store.updateOutcome(update)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    // MARK: - Versioning

    func testFetchingLatestVersion() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        let value = OCKOutcomeValue(0)
        var outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [value])
        try await store.addOutcome(outcome)

        for i in 1...5 {
            outcome.values = [OCKOutcomeValue(i)]
            outcome = try await store.updateOutcome(outcome)
        }

        let query = OCKOutcomeQuery(for: Date())
        let fetched = try await store.fetchOutcomes(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.values.first?.integerValue, 5)
    }
}


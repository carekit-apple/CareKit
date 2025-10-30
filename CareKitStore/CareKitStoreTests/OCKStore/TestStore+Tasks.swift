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
import HealthKit
import XCTest


class TestStoreTasks: XCTestCase {

    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }

    // MARK: Insertion

    func testAddTask() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil, targetValues: [OCKOutcomeValue(11.1)])
        var task = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule)
        task = try await store.addTask(task)
        XCTAssertNotNil(task.uuid)
        XCTAssertNotNil(task.schemaVersion)
    }

    func testScheduleDurationIsPersisted() async throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: Date(), end: nil, text: nil, duration: .seconds(123), targetValues: [])
        var task = OCKTask(id: "lunges", title: "Lunges", carePlanUUID: nil, schedule: schedule)
        task = try await store.addTask(task)
        XCTAssert(task.schedule.elements.allSatisfy { $0.duration == .seconds(123) })
    }

    func testAddTaskFailsIfIdentifierAlreadyExists() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "exercise", title: "Push Ups", carePlanUUID: nil, schedule: schedule)
        try await store.addTask(task)

        do {
            try await store.addTask(task)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testAllDaySchedulesArePersistedCorrectly() async throws {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 1), duration: .allDay)
        let schedule = OCKSchedule(composing: [element])
        var task = OCKTask(id: "benadryl", title: "Benadryl", carePlanUUID: nil, schedule: schedule)
        task = try await store.addTask(task)
        guard let fetchedElement = task.schedule.elements.first else { XCTFail("Bad schedule"); return }
        XCTAssertEqual(fetchedElement.duration, .allDay)
    }

    // MARK: Querying

    func testQueryTaskByIdentifier() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule)
        try await store.addTasks([task1, task2])
        let tasks = try await store.fetchTasks(query: OCKTaskQuery(id: task1.id))
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, task1.id)
    }

    func testQueryTaskByCarePlanIdentifier() async throws {
        let carePlan = try await store.addCarePlan(OCKCarePlan(id: "plan", title: "Plan", patientUUID: nil))
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "Task", carePlanUUID: carePlan.uuid, schedule: schedule))
        var query = OCKTaskQuery()
        query.carePlanIDs = [carePlan.id]
        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched, [task])
    }

    func testQueryTaskByCarePlanVersionID() async throws {
        let carePlan = try await store.addCarePlan(OCKCarePlan(id: "plan", title: "Plan", patientUUID: nil))
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "A", title: "Task", carePlanUUID: carePlan.uuid, schedule: schedule))
        var query = OCKTaskQuery()
        query.carePlanUUIDs = [carePlan.uuid]
        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched, [task])
    }

    func testTaskQueryGroupIdentifier() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule)
        task1.groupIdentifier = "group1"
        try await store.addTasks([task1, task2])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.groupIdentifiers = ["group1"]
        let tasks = try await store.fetchTasks(query: query)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, task1.id)
    }

    func testTaskQueryForNilGroupIdentifier() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule)
        task1.groupIdentifier = "group1"
        try await store.addTasks([task1, task2])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.groupIdentifiers = [nil]
        let tasks = try await store.fetchTasks(query: query)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, task2.id)
    }

    func testTaskQueryOrdered() async throws {
        let today = Calendar.current.startOfDay(for: Date())
        let schedule1 = OCKSchedule.mealTimesEachDay(start: today, end: nil)
        let schedule2 = OCKSchedule.mealTimesEachDay(start: today, end: Calendar.current.date(byAdding: .day, value: 1, to: today)!)
        let task1 = OCKTask(id: "aa", title: "aa", carePlanUUID: nil, schedule: schedule2)
        let task2 = OCKTask(id: "bb", title: "bb", carePlanUUID: nil, schedule: schedule1)
        let task3 = OCKTask(id: "cc", title: nil, carePlanUUID: nil, schedule: schedule2)
        try await store.addTasks([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 10, to: today)!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.sortDescriptors = [.title(ascending: true)]
        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched.map { $0.title }, [nil, "aa", "bb"])
    }

    func testTaskQueryLimited() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule)
        let task3 = OCKTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule)
        try await store.addTasks([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.sortDescriptors = [.title(ascending: true)]
        query.limit = 2

        let tasks = try await store.fetchTasks(query: query)
        XCTAssertEqual(tasks.map { $0.id }, ["a", "b"])
    }

    func testTaskQueryTags() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule)
        task1.tags = ["A"]
        var task2 = OCKTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule)
        task2.tags = ["A", "B"]
        var task3 = OCKTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule)
        task3.tags = ["A", "B", "C"]
        try await store.addTasks([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.tags = ["B"]
        query.sortDescriptors = [.title(ascending: true)]
        let fetched = try await store.fetchTasks(query: query)
        let titles = fetched.map { $0.title }
        XCTAssertEqual(titles, ["b", "c"], "Expected [b, c], but got \(titles)")
    }

    func testTaskQueryWithNilQueryReturnsAllTasks() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule)
        let task3 = OCKTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule)
        try await store.addTasks([task1, task2, task3])
        let tasks = try await store.fetchTasks(query: OCKTaskQuery())
        XCTAssertEqual(tasks.count, 3)
    }

    func testQueryTaskByRemoteID() async throws {
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task.remoteID = "abc"
        task = try await store.addTask(task)

        var query = OCKTaskQuery(for: Date())
        query.remoteIDs = ["abc"]
        let fetched = try await store.fetchTasks(query: query).first
        XCTAssertEqual(fetched, task)
    }

    func testQueryTaskByCarePlanRemoteID() async throws {
        var plan = OCKCarePlan(id: "A", title: "B", patientUUID: nil)
        plan.remoteID = "abc"
        plan = try await store.addCarePlan(plan)

        var task = OCKTask(id: "B", title: "C", carePlanUUID: plan.uuid, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try await store.addTask(task)

        var query = OCKTaskQuery(for: Date())
        query.carePlanRemoteIDs = ["abc"]
        let fetched = try await store.fetchTasks(query: query).first
        XCTAssertEqual(fetched, task)
    }

    // MARK: Versioning

    func testUpdateTaskCreateNewVersion() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        let updatedTask = try await store.updateTask(OCKTask(id: "meds", title: "New Medication", carePlanUUID: nil, schedule: schedule))
        XCTAssertEqual(updatedTask.title, "New Medication")
        XCTAssertEqual(updatedTask.previousVersionUUIDs.first, task.uuid)
    }

    func testCanFetchEventsWhenCurrentTaskVersionStartsAtSameTimeOrEarlierThanThePreviousVersion() async throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let manyDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: thisMorning)!
        let scheduleV1 = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: manyDaysAgo, end: nil, text: nil)
        let scheduleV2 = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: aFewDaysAgo, end: nil, text: nil)
        let scheduleV3 = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: aFewDaysAgo, end: nil, text: nil)

        var nausea = OCKTask(id: "nausea", title: "V1", carePlanUUID: nil, schedule: scheduleV1)
        let v1 = try await store.addTask(nausea)
        XCTAssertEqual(v1.effectiveDate, scheduleV1.startDate())

        nausea.title = "V2"
        nausea.schedule = scheduleV2
        nausea.effectiveDate = scheduleV2.startDate()
        let v2 = try await store.updateTask(nausea)
        XCTAssertEqual(v2.effectiveDate, scheduleV2.startDate())

        nausea.title = "V3"
        nausea.schedule = scheduleV3
        nausea.effectiveDate = scheduleV3.startDate()
        let v3 = try await store.updateTask(nausea)
        XCTAssertEqual(v3.effectiveDate, scheduleV3.startDate())

        var query = OCKEventQuery(dateInterval: DateInterval(start: manyDaysAgo, end: thisMorning))
        query.taskIDs = ["nausea"]

        let events = try await store.fetchEvents(query: query)
        XCTAssertEqual(events.count, 10, "Expected 10, but got \(events.count)")
        XCTAssertEqual(events.first?.task.title, "V1")
        XCTAssertEqual(events.last?.task.title, "V3")
    }

    func testCannotUpdateTaskIfItResultsInImplicitDataLoss() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 5, values: [OCKOutcomeValue(1)])
        try await store.addOutcomes([outcome])

        do {
            try await store.updateTask(task)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testCanUpdateTaskWithOutcomesIfDoesNotCauseDataLoss() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = try await store.addTask(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        let outcome = OCKOutcome(taskUUID: task.uuid, taskOccurrenceIndex: 0, values: [OCKOutcomeValue(1)])
        try await store.addOutcomes([outcome])
        task.effectiveDate = task.schedule[5].start
        try await store.updateTask(task)
    }

    func testQueryUpdatedTasksEvents() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil) // 7:30AM, 12:00PM, 5:30PM
        let original = try await store.addTask(OCKTask(id: "meds", title: "Original", carePlanUUID: nil, schedule: schedule))

        var updated = original
        updated.effectiveDate = schedule[5].start // 5:30PM tomorrow
        updated.title = "Updated"
        updated = try await store.updateTask(updated)

        var query = OCKEventQuery(for: schedule[5].start) // 0:00AM - 23:59.99PM tomorrow
        query.taskIDs = ["meds"]

        let events = try await store.fetchEvents(query: query)

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0].task.uuid, original.uuid)
        XCTAssertEqual(events[1].task.uuid, original.uuid)
        XCTAssertEqual(events[2].task.uuid, updated.uuid)
    }

    func testUpdateFailsForUnsavedTasks() async {
        let task = OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))

        do {
            try await store.updateTask(task)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testVersioningReturnsOldVersionForOldQueryRange() async throws {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)!

        let schedule1 = OCKSchedule.mealTimesEachDay(start: lastWeek, end: nil, targetValues: [OCKOutcomeValue(11.1)])
        let task1 = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule1)

        let schedule2 = OCKSchedule.mealTimesEachDay(start: tomorrow, end: nil)
        let task2 = OCKTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule2)
        try await store.addTasks([task1, task2])

        let tasks = try await store.fetchTasks(query: OCKTaskQuery(for: Date()))
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, task1.id)
    }

    func testTaskQueryOnPastDateReturnsPastVersionOfATask() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule)
        taskA.effectiveDate = dateA
        taskA = try await store.addTask(taskA)

        let dateB = dateA.addingTimeInterval(100)
        var taskB = OCKTask(id: "A", title: "b", carePlanUUID: nil, schedule: schedule)
        taskB.effectiveDate = dateB
        taskB = try await store.updateTask(taskB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let query = OCKTaskQuery(dateInterval: interval)
        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched.count, 1, "Expected to get 1 task, but got \(fetched.count)")
        XCTAssertEqual(fetched.first?.title, taskA.title)
    }

    func testFetchTaskByIdConvenienceMethodReturnsNewestVersionOfTask() async throws {
        let coordinator = OCKStoreCoordinator()
        let store = OCKStore(name: "test", type: .inMemory)
        coordinator.attach(store: store)

        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil)
        var taskV1 = OCKTask(id: "task", title: "V1", carePlanUUID: nil, schedule: schedule)
        taskV1 = try await store.addTask(taskV1)

        var taskV2 = taskV1
        taskV2.title = "V2"
        taskV2.effectiveDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        taskV2 = try await store.updateTask(taskV2)

        let fetchedTask = try await store.fetchAnyTask(withID: "task")
        XCTAssertEqual(fetchedTask.title, "V2")
    }

    func testTaskQueryStartingExactlyOnEffectiveDateOfNewVersion() async throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil)
        let query = OCKTaskQuery(dateInterval: DateInterval(start: schedule[5].start, end: schedule[5].end))

        var task = try await store.addTask(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        task.effectiveDate = task.schedule[5].start
        task = try await store.updateTask(task)

        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched.first, task)
    }

    func testTaskQuerySpanningVersionsReturnsNewestVersionOnly() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule)
        taskA.effectiveDate = dateA
        taskA = try await store.addTask(OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule))

        let dateB = Date().addingTimeInterval(100)
        var taskB = OCKTask(id: "A", title: "b", carePlanUUID: nil, schedule: schedule)
        taskB.effectiveDate = dateB
        taskB = try await store.updateTask(taskB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let query = OCKTaskQuery(dateInterval: interval)
        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched.count, 1, "Expected to get 1 task, but got \(fetched.count)")
        XCTAssertEqual(fetched.first?.title, taskB.title, "Expected title to be \(taskB.title ?? "nil"), but got \(fetched.first?.title ?? "nil")")
    }

    // MARK: Deletion

    func testDeleteTask() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try await store.addTask(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        try await store.deleteTask(task)
        let fetched = try await store.fetchTasks(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteTaskFailsIfTaskDoesntExist() async {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule)

        do {
            try await store.deleteTask(task)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }
}


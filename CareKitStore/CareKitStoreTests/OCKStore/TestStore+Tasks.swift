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
import HealthKit
import XCTest

class TestStoreTasks: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "TestDatabase", type: .inMemory)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    // MARK: Relationship Validation

    func testStorePreventsMissingPlanRelationshipOnTasks() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "medicine", title: "Advil", carePlanUUID: nil, schedule: schedule)
        store.configuration.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addTaskAndWait(task))
    }

    func testStoreAllowsMissingPlanRelationshipOnTasks() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "medicine", title: "Advil", carePlanUUID: nil, schedule: schedule)
        XCTAssertNoThrow(try store.addTaskAndWait(task))
    }

    // MARK: Insertion

    func testAddTask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil, targetValues: [OCKOutcomeValue(11.1)])
        var task = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        XCTAssertNotNil(task.uuid)
        XCTAssertNotNil(task.schemaVersion)
    }

    func testScheduleDurationIsPersisted() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: Date(), end: nil, text: nil, duration: .seconds(123), targetValues: [])
        var task = OCKTask(id: "lunges", title: "Lunges", carePlanUUID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        XCTAssert(task.schedule.elements.allSatisfy { $0.duration == .seconds(123) })
    }

    func testAddTaskFailsIfIdentifierAlreadyExists() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "exercise", title: "Push Ups", carePlanUUID: nil, schedule: schedule)
        try store.addTaskAndWait(task)
        XCTAssertThrowsError(try store.addTaskAndWait(task))
    }

    func testAllDaySchedulesArePersistedCorrectly() throws {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 1), duration: .allDay)
        let schedule = OCKSchedule(composing: [element])
        var task = OCKTask(id: "benadryl", title: "Benadryl", carePlanUUID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        guard let fetchedElement = task.schedule.elements.first else { XCTFail("Bad schedule"); return }
        XCTAssertTrue(fetchedElement.duration == .allDay)
    }

    func testAddUpdateOrDelete() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let taskC = OCKTask(id: "C", title: "OriginalC", carePlanUUID: nil, schedule: schedule)
        try store.addTaskAndWait(OCKTask(id: "A", title: "OriginalA", carePlanUUID: nil, schedule: schedule))
        try store.addTaskAndWait(taskC)

        let taskA = OCKTask(id: "A", title: "UpdatedA", carePlanUUID: nil, schedule: schedule)
        let taskB = OCKTask(id: "B", title: "OriginalB", carePlanUUID: nil, schedule: schedule)
        try store.addUpdateOrDeleteTasksAndWait(addOrUpdate: [taskA, taskB], delete: [taskC])

        let tasks = try store.fetchTasksAndWait(query: .init(for: Date()))
        let titles = tasks.map { $0.title }
        XCTAssert(tasks.count == 2)
        XCTAssert(titles.contains("UpdatedA"))
        XCTAssert(titles.contains("OriginalB"))
    }

    // MARK: Querying

    func testQueryTaskByIdentifier() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule)
        try store.addTasksAndWait([task1, task2])
        let tasks = try store.fetchTasksAndWait(query: OCKTaskQuery(id: task1.id))
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == task1.id)
    }

    func testQueryTaskByCarePlanIdentifier() throws {
        let carePlan = try store.addCarePlanAndWait(OCKCarePlan(id: "plan", title: "Plan", patientUUID: nil))
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "Task", carePlanUUID: carePlan.uuid, schedule: schedule))
        var query = OCKTaskQuery()
        query.carePlanIDs = [carePlan.id]
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched == [task])
    }

    func testQueryTaskByCarePlanVersionID() throws {
        let carePlan = try store.addCarePlanAndWait(OCKCarePlan(id: "plan", title: "Plan", patientUUID: nil))
        guard let versionID = carePlan.uuid else { XCTFail("Missing versionID"); return }
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "A", title: "Task", carePlanUUID: carePlan.uuid, schedule: schedule))
        var query = OCKTaskQuery()
        query.carePlanUUIDs = [versionID]
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched == [task])
    }

    func testTaskQueryGroupIdentifier() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule)
        task1.groupIdentifier = "group1"
        try store.addTasksAndWait([task1, task2])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.groupIdentifiers = ["group1"]
        let tasks = try store.fetchTasksAndWait(query: query)
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == task1.id)
    }

    func testTaskQueryOrdered() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let schedule1 = OCKSchedule.mealTimesEachDay(start: today, end: nil)
        let schedule2 = OCKSchedule.mealTimesEachDay(start: today, end: Calendar.current.date(byAdding: .day, value: 1, to: today)!)
        let task1 = OCKTask(id: "aa", title: "aa", carePlanUUID: nil, schedule: schedule2)
        let task2 = OCKTask(id: "bb", title: "bb", carePlanUUID: nil, schedule: schedule1)
        let task3 = OCKTask(id: "cc", title: nil, carePlanUUID: nil, schedule: schedule2)
        try store.addTasksAndWait([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 10, to: today)!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.extendedSortDescriptors = [.title(ascending: true)]
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.map { $0.title } == [nil, "aa", "bb"])
    }

    func testTaskQueryLimited() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule)
        let task3 = OCKTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule)
        try store.addTasksAndWait([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.extendedSortDescriptors = [.title(ascending: true)]
        query.limit = 1
        query.offset = 2

        let tasks = try store.fetchTasksAndWait(query: query)
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == task3.id)
    }

    func testTaskQueryTags() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule)
        task1.tags = ["A"]
        var task2 = OCKTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule)
        task2.tags = ["A", "B"]
        var task3 = OCKTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule)
        task3.tags = ["A", "B", "C"]
        try store.addTasksAndWait([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.tags = ["B"]
        query.extendedSortDescriptors = [.title(ascending: true)]
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.map { $0.title } == ["b", "c"])
    }

    func testTaskQueryWithNilQueryReturnsAllTasks() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule)
        let task2 = OCKTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule)
        let task3 = OCKTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule)
        try store.addTasksAndWait([task1, task2, task3])
        let tasks = try store.fetchTasksAndWait(query: OCKTaskQuery())
        XCTAssert(tasks.count == 3)
    }

    func testQueryTaskByRemoteID() throws {
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task.remoteID = "abc"
        task = try store.addTaskAndWait(task)

        var query = OCKTaskQuery(for: Date())
        query.remoteIDs = ["abc"]
        let fetched = try store.fetchTasksAndWait(query: query).first
        XCTAssert(fetched == task)
    }

    func testQueryTaskByCarePlanRemoteID() throws {
        var plan = OCKCarePlan(id: "A", title: "B", patientUUID: nil)
        plan.remoteID = "abc"
        plan = try store.addCarePlanAndWait(plan)

        var task = OCKTask(id: "B", title: "C", carePlanUUID: plan.uuid, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)

        var query = OCKTaskQuery(for: Date())
        query.carePlanRemoteIDs = ["abc"]
        let fetched = try store.fetchTasksAndWait(query: query).first
        XCTAssert(fetched == task)
    }
    // MARK: Versioning

    func testUpdateTaskCreateNewVersion() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        let updatedTask = try store.updateTaskAndWait(OCKTask(id: "meds", title: "New Medication", carePlanUUID: nil, schedule: schedule))
        XCTAssert(updatedTask.title == "New Medication")
        XCTAssert(updatedTask.previousVersionUUID == task.uuid)
    }

    func testCanFetchEventsWhenCurrentTaskVersionStartsAtSameTimeOrEarlierThanThePreviousVersion() throws {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let manyDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: thisMorning)!
        let scheduleV1 = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: manyDaysAgo, end: nil, text: nil)
        let scheduleV2 = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: aFewDaysAgo, end: nil, text: nil)
        let scheduleV3 = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: aFewDaysAgo, end: nil, text: nil)

        var nausea = OCKTask(id: "nausea", title: "V1", carePlanUUID: nil, schedule: scheduleV1)
        let v1 = try store.addTaskAndWait(nausea)
        XCTAssert(v1.effectiveDate == scheduleV1.startDate())

        nausea.title = "V2"
        nausea.schedule = scheduleV2
        nausea.effectiveDate = scheduleV2.startDate()
        let v2 = try store.updateTaskAndWait(nausea)
        XCTAssert(v2.effectiveDate == scheduleV2.startDate())

        nausea.title = "V3"
        nausea.schedule = scheduleV3
        nausea.effectiveDate = scheduleV3.startDate()
        let v3 = try store.updateTaskAndWait(nausea)
        XCTAssert(v3.effectiveDate == scheduleV3.startDate())

        let query = OCKEventQuery(dateInterval: DateInterval(start: manyDaysAgo, end: thisMorning))
        let events = try store.fetchEventsAndWait(taskID: "nausea", query: query)
        XCTAssert(events.count == 10, "Expected 10, but got \(events.count)")
        XCTAssert(events.first?.task.title == "V1")
        XCTAssert(events.last?.task.title == "V3")
    }

    func testCannotUpdateTaskIfItResultsInImplicitDataLoss() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        let outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 5, values: [OCKOutcomeValue(1)])
        try store.addOutcomesAndWait([outcome])
        XCTAssertThrowsError(try store.updateTaskAndWait(task))
    }

    func testCanUpdateTaskWithOutcomesIfDoesNotCauseDataLoss() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = try store.addTaskAndWait(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        let outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [OCKOutcomeValue(1)])
        try store.addOutcomesAndWait([outcome])
        task.effectiveDate = task.schedule[5].start
        XCTAssertNoThrow(try store.updateTaskAndWait(task))
    }

    func testQueryUpdatedTasksEvents() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil) // 7:30AM, 12:00PM, 5:30PM
        let original = try store.addTaskAndWait(OCKTask(id: "meds", title: "Original", carePlanUUID: nil, schedule: schedule))

        var updated = original
        updated.effectiveDate = schedule[5].start // 5:30PM tomorrow
        updated.title = "Updated"
        updated = try store.updateTaskAndWait(updated)
        let query = OCKEventQuery(for: schedule[5].start) // 0:00AM - 23:59.99PM tomorrow
        let events = try store.fetchEventsAndWait(taskID: "meds", query: query)

        XCTAssert(events.count == 3)
        XCTAssert(events[0].task.uuid == original.uuid)
        XCTAssert(events[1].task.uuid == original.uuid)
        XCTAssert(events[2].task.uuid == updated.uuid)
    }

    func testUpdateFailsForUnsavedTasks() {
        let task = OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        XCTAssertThrowsError(try store.updateTaskAndWait(task))
    }

    func testVersioningReturnsOldVersionForOldQueryRange() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)!

        let schedule1 = OCKSchedule.mealTimesEachDay(start: lastWeek, end: nil, targetValues: [OCKOutcomeValue(11.1)])
        let task1 = OCKTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule1)

        let schedule2 = OCKSchedule.mealTimesEachDay(start: tomorrow, end: nil)
        let task2 = OCKTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule2)
        try store.addTasksAndWait([task1, task2])

        let tasks = try store.fetchTasksAndWait(query: OCKTaskQuery(for: Date()))
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == task1.id)
    }

    func testTaskQueryOnPastDateReturnsPastVersionOfATask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule)
        taskA.effectiveDate = dateA
        taskA = try store.addTaskAndWait(OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule))

        let dateB = dateA.addingTimeInterval(100)
        var taskB = OCKTask(id: "A", title: "b", carePlanUUID: nil, schedule: schedule)
        taskB.effectiveDate = dateB
        taskB = try store.updateTaskAndWait(taskB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let query = OCKTaskQuery(dateInterval: interval)
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.count == 1, "Expected to get 1 task, but got \(fetched.count)")
        XCTAssert(fetched.first?.title == taskA.title)
    }

    func testTaskQueryStartingExactlyOnEffectiveDateOfNewVersion() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil)
        let query = OCKTaskQuery(dateInterval: DateInterval(start: schedule[5].start, end: schedule[5].end))

        var task = try store.addTaskAndWait(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        task.effectiveDate = task.schedule[5].start
        task = try store.updateTaskAndWait(task)

        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.first == task)
    }

    func testTaskQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule)
        taskA.effectiveDate = dateA
        taskA = try store.addTaskAndWait(OCKTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule))

        let dateB = Date().addingTimeInterval(100)
        var taskB = OCKTask(id: "A", title: "b", carePlanUUID: nil, schedule: schedule)
        taskB.effectiveDate = dateB
        taskB = try store.updateTaskAndWait(taskB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let query = OCKTaskQuery(dateInterval: interval)
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.count == 1, "Expected to get 1 task, but got \(fetched.count)")
        XCTAssert(fetched.first?.title == taskB.title, "Expected title to be \(taskB.title ?? "nil"), but got \(fetched.first?.title ?? "nil")")
    }

    // MARK: Deletion

    func testDeleteTask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule))
        try store.deleteTaskAndWait(task)
        let fetched = try store.fetchTasksAndWait(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteTaskFailsIfTaskDoesntExist() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule)
        XCTAssertThrowsError(try store.deleteTaskAndWait(task))
    }
}

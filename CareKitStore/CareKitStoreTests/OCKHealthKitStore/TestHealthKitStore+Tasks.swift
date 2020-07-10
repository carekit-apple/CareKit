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

class TestHealthKitStoreTasks: XCTestCase {
    var store: OCKHealthKitPassthroughStore!
    let link = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())

    override func setUp() {
        super.setUp()
        store = OCKHealthKitPassthroughStore(name: "TestDatabase", type: .inMemory)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    // MARK: Relationship Validation

    func testStoreAllowsMissingPlanRelationshipOnTasks() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKHealthKitTask(id: "medicine", title: "Advil", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        XCTAssertNoThrow(try store.addTaskAndWait(task))
    }

    // MARK: Insertion

    func testAddTask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil, targetValues: [OCKOutcomeValue(11.1)])
        var task = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task = try store.addTaskAndWait(task)
        XCTAssertNotNil(task.uuid)
        XCTAssertNotNil(task.schemaVersion)
    }

    func testScheduleDurationIsPersisted() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: Date(), end: nil, text: nil, duration: .seconds(123), targetValues: [])
        var task = OCKHealthKitTask(id: "lunges", title: "Lunges", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task = try store.addTaskAndWait(task)
        XCTAssert(task.schedule.elements.allSatisfy { $0.duration == .seconds(123) })
    }

    func testHealthKitLinkageIsPersisted() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil, targetValues: [OCKOutcomeValue(11.1)])
        let linkage = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        var task = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task.healthKitLinkage = linkage
        task = try store.addTaskAndWait(task)
        XCTAssertNotNil(task.healthKitLinkage)
        XCTAssert(task.healthKitLinkage == linkage)
    }

    func testAddTaskFailsIfIdentifierAlreadyExists() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKHealthKitTask(id: "exercise", title: "Push Ups", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        try store.addTaskAndWait(task)
        XCTAssertThrowsError(try store.addTaskAndWait(task))
    }

    func testAllDaySchedulesArePersistedCorrectly() throws {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 1), duration: .allDay)
        let schedule = OCKSchedule(composing: [element])
        var task = OCKHealthKitTask(id: "benadryl", title: "Benadryl", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task = try store.addTaskAndWait(task)
        guard let fetchedElement = task.schedule.elements.first else { XCTFail("Bad schedule"); return }
        XCTAssertTrue(fetchedElement.duration == .allDay)
    }

    // MARK: Querying

    func testQueryTaskByIdentifier() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        try store.addTasksAndWait([task1, task2])
        let tasks = try store.fetchTasksAndWait(query: OCKTaskQuery(id: task1.id))
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == task1.id)
    }

    func testTaskQueryGroupIdentifier() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
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
        let task1 = OCKHealthKitTask(id: "aa", title: "aa", carePlanUUID: nil, schedule: schedule2, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "bb", title: "bb", carePlanUUID: nil, schedule: schedule1, healthKitLinkage: link)
        let task3 = OCKHealthKitTask(id: "cc", title: nil, carePlanUUID: nil, schedule: schedule2, healthKitLinkage: link)
        try store.addTasksAndWait([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 10, to: today)!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.extendedSortDescriptors = [.title(ascending: true)]

        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.map { $0.title } == [nil, "aa", "bb"])
    }

    func testTaskQueryLimited() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKHealthKitTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task3 = OCKHealthKitTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
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
        var task1 = OCKHealthKitTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task1.tags = ["A"]
        var task2 = OCKHealthKitTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task2.tags = ["A", "B"]
        var task3 = OCKHealthKitTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
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
        let task1 = OCKHealthKitTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task3 = OCKHealthKitTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        try store.addTasksAndWait([task1, task2, task3])
        let tasks = try store.fetchTasksAndWait()
        XCTAssert(tasks.count == 3)
    }

    func testQueryTaskByRemoteID() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKHealthKitTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task.remoteID = "abc"
        task = try store.addTaskAndWait(task)

        var query = OCKTaskQuery(for: Date())
        query.remoteIDs = ["abc"]

        let fetched = try store.fetchTasksAndWait(query: query).first
        XCTAssert(fetched == task)
    }

    // MARK: Versioning

    func testUpdateTaskCreateNewVersion() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let version1 = OCKHealthKitTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task = try store.addTaskAndWait(version1)
        let version2 = OCKHealthKitTask(id: "meds", title: "New Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let updatedTask = try store.updateTaskAndWait(version2)
        XCTAssert(updatedTask.title == "New Medication")
        XCTAssert(updatedTask.previousVersionUUID == task.uuid)
    }

    func testUpdateFailsForUnsavedTasks() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKHealthKitTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        XCTAssertThrowsError(try store.updateTaskAndWait(task))
    }

    func testVersioningReturnsOldVersionForOldQueryRange() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)!

        let schedule1 = OCKSchedule.mealTimesEachDay(start: lastWeek, end: nil, targetValues: [OCKOutcomeValue(11.1)])
        let task1 = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule1, healthKitLinkage: link)

        let schedule2 = OCKSchedule.mealTimesEachDay(start: tomorrow, end: nil)
        let task2 = OCKHealthKitTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule2, healthKitLinkage: link)
        try store.addTasksAndWait([task1, task2])

        let tasks = try store.fetchTasksAndWait(query: OCKTaskQuery(for: Date()))
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.id == task1.id)
    }

    func testTaskQueryOnPastDateReturnsPastVersionOfATask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKHealthKitTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        taskA.effectiveDate = dateA
        taskA = try store.addTaskAndWait(OCKHealthKitTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link))

        let dateB = dateA.addingTimeInterval(100)
        var taskB = OCKHealthKitTask(id: "A", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        taskB.effectiveDate = dateB
        taskB = try store.updateTaskAndWait(taskB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let query = OCKTaskQuery(dateInterval: interval)
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.count == 1, "Expected to get 1 task, but got \(fetched.count)")
        XCTAssert(fetched.first?.title == taskA.title)
    }

    func testTaskQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKHealthKitTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        taskA.effectiveDate = dateA
        taskA = try store.addTaskAndWait(OCKHealthKitTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link))

        let dateB = Date().addingTimeInterval(100)
        var taskB = OCKHealthKitTask(id: "A", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        taskB.effectiveDate = dateB
        taskB = try store.updateTaskAndWait(taskB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let query = OCKTaskQuery(dateInterval: interval)
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.title == taskB.title)
    }

    // MARK: Deletion

    func testDeleteTask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKHealthKitTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task = try store.addTaskAndWait(task)
        try store.deleteTaskAndWait(task)
        let fetched = try store.fetchTasksAndWait(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteTaskFailsIfTaskDoesntExist() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKHealthKitTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        XCTAssertThrowsError(try store.deleteTaskAndWait(task))
    }
}

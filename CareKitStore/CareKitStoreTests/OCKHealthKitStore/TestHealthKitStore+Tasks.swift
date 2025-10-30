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

class TestHealthKitStoreTasks: XCTestCase {
    var store: OCKHealthKitPassthroughStore!
    let link = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())

    override func setUp() {
        super.setUp()
        let inMemory = OCKStore(name: UUID().uuidString, type: .inMemory)
        store = OCKHealthKitPassthroughStore(store: inMemory)
    }

    // MARK: Relationship Validation

    func testStoreAllowsMissingPlanRelationshipOnTasks() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKHealthKitTask(id: "medicine", title: "Advil", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        try await store.addTask(task)
    }

    // MARK: Insertion

    func testAddTask() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil, targetValues: [OCKOutcomeValue(11.1)])
        var task = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task = try await store.addTask(task)
        XCTAssertNotNil(task.uuid)
        XCTAssertNotNil(task.schemaVersion)
    }

    func testScheduleDurationIsPersisted() async throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: Date(), end: nil, text: nil, duration: .seconds(123), targetValues: [])
        var task = OCKHealthKitTask(id: "lunges", title: "Lunges", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task = try await store.addTask(task)
        XCTAssert(task.schedule.elements.allSatisfy { $0.duration == .seconds(123) })
    }

    func testHealthKitLinkageIsPersisted() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil, targetValues: [OCKOutcomeValue(11.1)])
        let linkage = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        var task = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task.healthKitLinkage = linkage
        task = try await store.addTask(task)
        XCTAssertNotNil(task.healthKitLinkage)
        XCTAssertEqual(task.healthKitLinkage, linkage)
    }

    func testAddTaskFailsIfIdentifierAlreadyExists() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKHealthKitTask(id: "exercise", title: "Push Ups", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
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
        var task = OCKHealthKitTask(id: "benadryl", title: "Benadryl", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task = try await store.addTask(task)
        guard let fetchedElement = task.schedule.elements.first else { XCTFail("Bad schedule"); return }
        XCTAssertEqual(fetchedElement.duration, .allDay)
    }

    // MARK: Querying

    func testQueryTaskByIdentifier() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        try await store.addTasks([task1, task2])
        let tasks = try await store.fetchTasks(query: OCKTaskQuery(id: task1.id))
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, task1.id)
    }

    func testTaskQueryGroupIdentifier() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task1.groupIdentifier = "group1"
        try await store.addTasks([task1, task2])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.groupIdentifiers = ["group1"]

        let tasks = try await store.fetchTasks(query: query)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, task1.id)
    }

    func testTaskQueryOrdered() async throws {
        let today = Calendar.current.startOfDay(for: Date())
        let schedule1 = OCKSchedule.mealTimesEachDay(start: today, end: nil)
        let schedule2 = OCKSchedule.mealTimesEachDay(start: today, end: Calendar.current.date(byAdding: .day, value: 1, to: today)!)
        let task1 = OCKHealthKitTask(id: "aa", title: "aa", carePlanUUID: nil, schedule: schedule2, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "bb", title: "bb", carePlanUUID: nil, schedule: schedule1, healthKitLinkage: link)
        let task3 = OCKHealthKitTask(id: "cc", title: nil, carePlanUUID: nil, schedule: schedule2, healthKitLinkage: link)
        try await store.addTasks([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 10, to: today)!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.sortDescriptors = [.title(ascending: true)]

        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched.map { $0.title }, [nil, "aa", "bb"])
    }

    func testTaskQueryLimited() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKHealthKitTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task3 = OCKHealthKitTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        try await store.addTasks([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.sortDescriptors = [.title(ascending: true)]
        query.limit = 2

        let tasks = try await store.fetchTasks(query: query)
        XCTAssertEqual(tasks.count, 2)
    }

    func testTaskQueryTags() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKHealthKitTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task1.tags = ["A"]
        var task2 = OCKHealthKitTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task2.tags = ["A", "B"]
        var task3 = OCKHealthKitTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task3.tags = ["A", "B", "C"]
        try await store.addTasks([task1, task2, task3])

        let interval = DateInterval(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        var query = OCKTaskQuery(dateInterval: interval)
        query.tags = ["B"]
        query.sortDescriptors = [.title(ascending: true)]

        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched.map { $0.title }, ["b", "c"])
    }

    func testTaskQueryWithNilQueryReturnsAllTasks() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKHealthKitTask(id: "a", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task2 = OCKHealthKitTask(id: "b", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task3 = OCKHealthKitTask(id: "c", title: "c", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        try await store.addTasks([task1, task2, task3])
        let tasks = try await store.fetchTasks(query: OCKTaskQuery())
        XCTAssertEqual(tasks.count, 3)
    }

    func testQueryTaskByRemoteID() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKHealthKitTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task.remoteID = "abc"
        task = try await store.addTask(task)

        var query = OCKTaskQuery(for: Date())
        query.remoteIDs = ["abc"]

        let fetched = try await store.fetchTasks(query: query).first
        XCTAssertEqual(fetched, task)
    }

    // MARK: Versioning

    func testUpdateTaskCreateNewVersion() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let version1 = OCKHealthKitTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let task = try await store.addTask(version1)
        let version2 = OCKHealthKitTask(id: "meds", title: "New Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        let updatedTask = try await store.updateTask(version2)
        XCTAssertEqual(updatedTask.title, "New Medication")
        XCTAssertEqual(updatedTask.previousVersionUUIDs.first, task.uuid)
    }

    func testUpdateFailsForUnsavedTasks() async {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKHealthKitTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)

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
        let task1 = OCKHealthKitTask(id: "squats", title: "Front Squats", carePlanUUID: nil, schedule: schedule1, healthKitLinkage: link)

        let schedule2 = OCKSchedule.mealTimesEachDay(start: tomorrow, end: nil)
        let task2 = OCKHealthKitTask(id: "lunges", title: "Forward Lunges", carePlanUUID: nil, schedule: schedule2, healthKitLinkage: link)
        try await store.addTasks([task1, task2])

        let tasks = try await store.fetchTasks(query: OCKTaskQuery(for: Date()))
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, task1.id)
    }

    func testTaskQueryOnPastDateReturnsPastVersionOfATask() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKHealthKitTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        taskA.effectiveDate = dateA
        taskA = try await store.addTask(taskA)

        let dateB = dateA.addingTimeInterval(100)
        var taskB = OCKHealthKitTask(id: "A", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        taskB.effectiveDate = dateB
        taskB = try await store.updateTask(taskB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let query = OCKTaskQuery(dateInterval: interval)
        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched.count, 1, "Expected to get 1 task, but got \(fetched.count)")
        XCTAssertEqual(fetched.first?.title, taskA.title)
    }

    func testTaskQuerySpanningVersionsReturnsNewestVersionOnly() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKHealthKitTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        taskA.effectiveDate = dateA
        taskA = try await store.addTask(OCKHealthKitTask(id: "A", title: "a", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link))

        let dateB = Date().addingTimeInterval(100)
        var taskB = OCKHealthKitTask(id: "A", title: "b", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        taskB.effectiveDate = dateB
        taskB = try await store.updateTask(taskB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let query = OCKTaskQuery(dateInterval: interval)
        let fetched = try await store.fetchTasks(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, taskB.title)
    }

    // MARK: Deletion

    func testDeleteTask() async throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKHealthKitTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)
        task = try await store.addTask(task)
        try await store.deleteTask(task)
        let fetched = try await store.fetchTasks(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteTaskFailsIfTaskDoesntExist() async {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKHealthKitTask(id: "meds", title: "Medication", carePlanUUID: nil, schedule: schedule, healthKitLinkage: link)

        do {
            try await store.deleteTask(task)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }
}

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
        let task = OCKTask(identifier: "medicine", title: "Advil", carePlanID: nil, schedule: schedule)
        store.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addTaskAndWait(task))
    }

    func testStoreAllowsMissingPlanRelationshipOnTasks() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(identifier: "medicine", title: "Advil", carePlanID: nil, schedule: schedule)
        XCTAssertNoThrow(try store.addTaskAndWait(task))
    }

    // MARK: Insertion

    func testAddTask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil, targetValues: [OCKOutcomeValue(11.1)])
        var task = OCKTask(identifier: "squats", title: "Front Squats", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        XCTAssertNotNil(task.localDatabaseID)
        XCTAssertNotNil(task.schemaVersion)
    }

    func testScheduleDurationIsPersisted() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 8, minutes: 0, start: Date(), end: nil, text: nil, duration: 123, targetValues: [])
        var task = OCKTask(identifier: "lunges", title: "Lunges", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        XCTAssert(task.schedule.elements.allSatisfy { $0.duration == 123 })
    }

    func testAddTaskFailsIfIdentifierAlreadyExists() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(identifier: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        try store.addTaskAndWait(task)
        XCTAssertThrowsError(try store.addTaskAndWait(task))
    }

    func testAllDaySchedulesArePersistedCorrectly() throws {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 1), isAllDay: true)
        let schedule = OCKSchedule(composing: [element])
        var task = OCKTask(identifier: "benadryl", title: "Benadryl", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        guard let fetchedElement = task.schedule.elements.first else { XCTFail("Bad schedule"); return }
        XCTAssertTrue(fetchedElement.isAllDay)
    }

    // MARK: Querying

    func testQueryTaskByIdentifier() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(identifier: "squats", title: "Front Squats", carePlanID: nil, schedule: schedule)
        let task2 = OCKTask(identifier: "lunges", title: "Forward Lunges", carePlanID: nil, schedule: schedule)
        try store.addTasksAndWait([task1, task2])
        let tasks = try store.fetchTasksAndWait(.taskIdentifiers([task1.identifier]))
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.identifier == task1.identifier)
    }

    func testQueryTaskByCarePlanIdentifier() throws {
        let carePlan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "plan", title: "Plan", patientID: nil))
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(identifier: "A", title: "Task", carePlanID: carePlan.localDatabaseID, schedule: schedule))
        let anchor = OCKTaskAnchor.carePlanIdentifiers([carePlan.identifier])
        let fetched = try store.fetchTasksAndWait(anchor, query: nil)
        XCTAssert(fetched == [task])
    }

    func testQueryTaskByCarePlanVersionID() throws {
        let carePlan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "plan", title: "Plan", patientID: nil))
        guard let versionID = carePlan.versionID else { XCTFail("Missing versionID"); return }
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(identifier: "A", title: "Task", carePlanID: carePlan.localDatabaseID, schedule: schedule))
        let anchor = OCKTaskAnchor.carePlanVersions([versionID])
        let fetched = try store.fetchTasksAndWait(anchor, query: nil)
        XCTAssert(fetched == [task])
    }

    func testTaskQueryGroupIdentifier() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKTask(identifier: "squats", title: "Front Squats", carePlanID: nil, schedule: schedule)
        let task2 = OCKTask(identifier: "lunges", title: "Forward Lunges", carePlanID: nil, schedule: schedule)
        task1.groupIdentifier = "group1"
        try store.addTasksAndWait([task1, task2])
        var query = OCKTaskQuery(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        query.groupIdentifiers = ["group1"]
        let tasks = try store.fetchTasksAndWait(query: query)
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.identifier == task1.identifier)
    }

    func testTaskQueryOrdered() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let schedule1 = OCKSchedule.mealTimesEachDay(start: today, end: nil)
        let schedule2 = OCKSchedule.mealTimesEachDay(start: today, end: Calendar.current.date(byAdding: .day, value: 1, to: today)!)
        let task1 = OCKTask(identifier: "aa", title: "aa", carePlanID: nil, schedule: schedule2)
        let task2 = OCKTask(identifier: "bb", title: "bb", carePlanID: nil, schedule: schedule1)
        let task3 = OCKTask(identifier: "cc", title: nil, carePlanID: nil, schedule: schedule2)
        try store.addTasksAndWait([task1, task2, task3])

        var query = OCKTaskQuery(start: Date(), end: Calendar.current.date(byAdding: .day, value: 10, to: today)!)
        query.sortDescriptors = [.title(ascending: true)]
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.map { $0.title } == [nil, "aa", "bb"])
    }

    func testTaskQueryLimited() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(identifier: "a", title: "a", carePlanID: nil, schedule: schedule)
        let task2 = OCKTask(identifier: "b", title: "b", carePlanID: nil, schedule: schedule)
        let task3 = OCKTask(identifier: "c", title: "c", carePlanID: nil, schedule: schedule)
        try store.addTasksAndWait([task1, task2, task3])
        var query = OCKTaskQuery(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        query.sortDescriptors = [.title(ascending: true)]
        query.limit = 1
        query.offset = 2
        let tasks = try store.fetchTasksAndWait(query: query)
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.identifier == task3.identifier)
    }

    func testTaskQueryTags() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task1 = OCKTask(identifier: "a", title: "a", carePlanID: nil, schedule: schedule)
        task1.tags = ["A"]
        var task2 = OCKTask(identifier: "b", title: "b", carePlanID: nil, schedule: schedule)
        task2.tags = ["A", "B"]
        var task3 = OCKTask(identifier: "c", title: "c", carePlanID: nil, schedule: schedule)
        task3.tags = ["A", "B", "C"]
        try store.addTasksAndWait([task1, task2, task3])
        var query = OCKTaskQuery(start: Date(), end: Calendar.current.date(byAdding: .day, value: 2, to: Date())!)
        query.tags = ["B"]
        query.sortDescriptors = [.title(ascending: true)]
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.map { $0.title } == ["b", "c"])
    }

    func testTaskQueryWithNilQueryReturnsAllTasks() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(identifier: "a", title: "a", carePlanID: nil, schedule: schedule)
        let task2 = OCKTask(identifier: "b", title: "b", carePlanID: nil, schedule: schedule)
        let task3 = OCKTask(identifier: "c", title: "c", carePlanID: nil, schedule: schedule)
        try store.addTasksAndWait([task1, task2, task3])
        let tasks = try store.fetchTasksAndWait(nil, query: nil)
        XCTAssert(tasks.count == 3)
    }

    func testQueryTaskByRemoteID() throws {
        var task = OCKTask(identifier: "A", title: nil, carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task.remoteID = "abc"
        task = try store.addTaskAndWait(task)

        let fetched = try store.fetchTasksAndWait(.taskRemoteIDs(["abc"]), query: .today).first
        XCTAssert(fetched == task)
    }

    func testQueryTaskByCarePlanRemoteID() throws {
        var plan = OCKCarePlan(identifier: "A", title: "B", patientID: nil)
        plan.remoteID = "abc"
        plan = try store.addCarePlanAndWait(plan)

        var task = OCKTask(identifier: "B", title: "C", carePlanID: plan.versionID, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)

        let fetched = try store.fetchTasksAndWait(.carePlanRemoteIDs(["abc"]), query: .today).first
        XCTAssert(fetched == task)
    }
    // MARK: Versioning

    func testUpdateTaskCreateNewVersion() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: schedule))
        let updatedTask = try store.updateTaskAndWait(OCKTask(identifier: "meds", title: "New Medication", carePlanID: nil, schedule: schedule))
        XCTAssert(updatedTask.title == "New Medication")
        XCTAssert(updatedTask.previousVersionID == task.localDatabaseID)
    }

    func testUpdateTasksWithoutVersioning() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: schedule))
        store.configuration.updatesCreateNewVersions = false
        let updatedTask = try store.updateTaskAndWait(OCKTask(identifier: "meds", title: "New Medication", carePlanID: nil, schedule: schedule))
        XCTAssert(updatedTask.title == "New Medication")
        XCTAssert(updatedTask.localDatabaseID == task.localDatabaseID)
    }

    func testUpdateFailsForUnsavedTasks() {
        let task = OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        XCTAssertThrowsError(try store.updateTaskAndWait(task))
    }

    func testVersioningReturnsOldVersionForOldQueryRange() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)!

        let schedule1 = OCKSchedule.mealTimesEachDay(start: lastWeek, end: nil, targetValues: [OCKOutcomeValue(11.1)])
        let task1 = OCKTask(identifier: "squats", title: "Front Squats", carePlanID: nil, schedule: schedule1)

        let schedule2 = OCKSchedule.mealTimesEachDay(start: tomorrow, end: nil)
        let task2 = OCKTask(identifier: "lunges", title: "Forward Lunges", carePlanID: nil, schedule: schedule2)
        try store.addTasksAndWait([task1, task2])

        let tasks = try store.fetchTasksAndWait(query: .today)
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.identifier == task1.identifier)
    }

    func testTaskQueryOnPastDateReturnsPastVersionOfATask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKTask(identifier: "A", title: "a", carePlanID: nil, schedule: schedule)
        taskA.effectiveDate = dateA
        taskA = try store.addTaskAndWait(OCKTask(identifier: "A", title: "a", carePlanID: nil, schedule: schedule))

        let dateB = Date().addingTimeInterval(100)
        var taskB = OCKTask(identifier: "A", title: "b", carePlanID: nil, schedule: schedule)
        taskB.effectiveDate = dateB
        taskB = try store.updateTaskAndWait(taskB)

        let query = OCKTaskQuery(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.title == taskA.title)
    }

    func testTaskQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)

        let dateA = Date().addingTimeInterval(-100)
        var taskA = OCKTask(identifier: "A", title: "a", carePlanID: nil, schedule: schedule)
        taskA.effectiveDate = dateA
        taskA = try store.addTaskAndWait(OCKTask(identifier: "A", title: "a", carePlanID: nil, schedule: schedule))

        let dateB = Date().addingTimeInterval(100)
        var taskB = OCKTask(identifier: "A", title: "b", carePlanID: nil, schedule: schedule)
        taskB.effectiveDate = dateB
        taskB = try store.updateTaskAndWait(taskB)

        let query = OCKTaskQuery(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let fetched = try store.fetchTasksAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.title == taskB.title)
    }

    func testContactQueryBeforeContactWasCreatedReturnsNoResults() throws {
        let dateA = Date()
        try store.addContactAndWait(OCKContact(identifier: "A", givenName: "a", familyName: "b", carePlanID: nil))
        let query = OCKContactQuery(start: dateA.addingTimeInterval(-100), end: dateA)
        let fetched = try store.fetchContactsAndWait(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: Deletion

    func testDeleteTask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: schedule))
        try store.deleteTaskAndWait(task)
        let fetched = try store.fetchTasksAndWait()
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteTaskFailsIfTaskDoesntExist() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: schedule)
        XCTAssertThrowsError(try store.deleteTaskAndWait(task))
    }
}

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

@testable import CareKit
@testable import CareKitStore
import Combine
import Foundation
import XCTest


class TestTaskController: XCTestCase {

    var store: OCKStore!
    var manager: OCKSynchronizedStoreManager!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "ockstore", type: .inMemory)
        manager = OCKSynchronizedStoreManager(wrapping: store)
        cancellables = []
    }

    // MARK: - View model gets set

    func testSetViewModel() {
        let controller = OCKTaskController(storeManager: manager)
        let doxylamineUUID = UUID()
        let events = [
            OCKAnyEvent.mockDaily(taskUUID: doxylamineUUID, occurrence: 0),
            OCKAnyEvent.mockDaily(taskUUID: doxylamineUUID, occurrence: 1)
        ]
        let modifiedEvents = events.map { controller.modified(event: $0) }
        let taskEvents = OCKTaskEvents(events: modifiedEvents)

        controller.setViewModelAndObserve(events: events, query: .init(for: Date()))
        XCTAssertFalse(controller.taskEvents.isEmpty)
        XCTAssertEqual(taskEvents.id, controller.taskEvents.id)
    }

    func testFetchWithTaskQuerySetsViewModel() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupSetViewModelTest(controller: controller)

        var taskQuery = OCKTaskQuery()
        taskQuery.ids = ["doxylamine", "nausea"]
        controller.fetchAndObserveEvents(forTaskQuery: taskQuery, eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    func testFetchWithTaskIdsSetsViewModel() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupSetViewModelTest(controller: controller)

        controller.fetchAndObserveEvents(forTaskIDs: ["doxylamine", "nausea"], eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    func testFetchWithTaskQueryPartiallyFailsAndSetsViewModel() throws {
        let controller = MockController(storeManager: manager)
        let tasks: [OCKTask] = [ .mockAtMealtimes(taskID: "doxylamine") ]
        let addedTasks = try store.addTasksAndWait(tasks)

        let valuesFetched = expectation(description: "Value updated")
        controller.$taskEvents.dropFirst().sink { newValue in
            let observedDoxylamineEvents = newValue.events(forTask: addedTasks[0])
            XCTAssertEqual(newValue.events.count, 3)
            XCTAssertEqual(observedDoxylamineEvents.count, 3)
            valuesFetched.fulfill()
        }.store(in: &cancellables)

        var taskQuery = OCKTaskQuery()
        taskQuery.ids = ["unknown-task", "doxylamine"]
        controller.fetchAndObserveEvents(forTaskQuery: taskQuery, eventQuery: .init(for: Date()))
        wait(for: [valuesFetched], timeout: 2)
    }

    func testFetchWithTaskIdsPartiallyFailsAndSetsViewModel() throws {
        let controller = MockController(storeManager: manager)
        let tasks: [OCKTask] = [ .mockAtMealtimes(taskID: "doxylamine") ]
        let addedTasks = try store.addTasksAndWait(tasks)

        let valuesFetched = expectation(description: "Value updated")
        controller.$taskEvents.dropFirst().sink { newValue in
            let observedDoxylamineEvents = newValue.events(forTask: addedTasks[0])
            XCTAssertEqual(newValue.events.count, 3)
            XCTAssertEqual(observedDoxylamineEvents.count, 3)
            valuesFetched.fulfill()
        }.store(in: &cancellables)

        controller.fetchAndObserveEvents(forTaskIDs: ["unknown-task", "doxylamine"], eventQuery: .init(for: Date()))
        wait(for: [valuesFetched], timeout: 2)
    }

    private func setupSetViewModelTest(controller: MockController) throws -> [XCTestExpectation] {
        let tasks: [OCKTask] = [
            .mockAtMealtimes(taskID: "doxylamine"),
            .mockAtMealtimes(taskID: "nausea")
        ]
        let addedTasks = try store.addTasksAndWait(tasks)

        let valuesFetched = expectation(description: "Value updated")
        controller.$taskEvents.dropFirst().sink { newValue in

            let observedDoxylamineEvents = newValue.events(forTask: addedTasks[0])
            let observedNauseaEvents = newValue.events(forTask: addedTasks[1])

            XCTAssertEqual(newValue.events.count, 6)
            XCTAssertEqual(observedDoxylamineEvents.count, 3)
            XCTAssertEqual(observedNauseaEvents.count, 3)

            valuesFetched.fulfill()
        }.store(in: &cancellables)

        return [valuesFetched]
    }

    // MARK: - Outcome notifications

    func testSetViewModelReceivesOutcomeNotifications() {
        let controller = OCKTaskController(storeManager: manager)
        let doxylamineUUID = UUID()
        let oldEvent = OCKAnyEvent.mockDaily(taskUUID: doxylamineUUID, occurrence: 0, hasOutcome: false)
        let updatedEvent = OCKAnyEvent.mockDaily(taskUUID: doxylamineUUID, occurrence: 0, hasOutcome: true)

        controller.setViewModelAndObserve(events: [oldEvent], query: .init(for: Date()))

        let valueUpdated = expectation(description: "Value updated")
        controller.$taskEvents.dropFirst().sink { newValue in
            XCTAssertEqual(newValue.events.count, 1)
            if newValue.events.count == 1 {
                XCTAssertTrue(newValue.contains(event: updatedEvent))
                XCTAssertNotNil(newValue.events[0].outcome)
            }
            valueUpdated.fulfill()
        }.store(in: &cancellables)

        let notification = OCKOutcomeNotification(outcome: updatedEvent.outcome!, category: .update, storeManager: controller.storeManager)
        controller.storeManager.subject.send(notification)
        wait(for: [valueUpdated], timeout: 2)
    }

    func testFetchWithTaskIDsReceivesOutcomeNotifications() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupReceivesOutcomeNotificationsTest(controller: controller)

        controller.fetchAndObserveEvents(forTaskIDs: ["doxylamine"], eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    func testFetchWithTaskQueryReceivesOutcomeNotifications() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupReceivesOutcomeNotificationsTest(controller: controller)

        var query = OCKTaskQuery()
        query.ids = ["doxylamine"]
        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    private func setupReceivesOutcomeNotificationsTest(controller: MockController) throws -> [XCTestExpectation] {
        // Create a task and add it to the store
        let task = OCKTask.mockAtMealtimes(taskID: "doxylamine")
        let addedTask = try store.addTaskAndWait(task)

        // Initialize the events with an updated outcome
        let eventsToUpdate = try store.fetchEventsAndWait(taskID: addedTask.id, query: .init(for: Date()))
        let updatedEvents = eventsToUpdate.map { $0.updatedWithOutcome() }

        // Send outcome notifications once the controller subscribes
        let notificationsSent = expectation(description: "Notifications sent")
        var didStartSendingNotifications = false
        controller.$subscribedToTasks.sink { count in
            guard count == 1 else { return }
            XCTAssertEqual(controller.taskEvents.events.count, 3)
            didStartSendingNotifications = true
            self.sendUpdateOutcomeNotificationsTo(controller: controller, events: updatedEvents)
            notificationsSent.fulfill()
        }.store(in: &cancellables)

        var eventUpdatedCount = 0
        let eventsUpdated = expectation(description: "Events updated")
        eventsUpdated.expectedFulfillmentCount = 3
        controller.$taskEvents.sink { taskEvents in
            guard didStartSendingNotifications, !taskEvents.isEmpty else { return }

            // Ensure the events update with outcomes
            XCTAssertEqual(taskEvents.events.count, 3)
            XCTAssertTrue(taskEvents.contains(event: OCKAnyEvent(updatedEvents[eventUpdatedCount])))
            XCTAssertNotNil(taskEvents.events[eventUpdatedCount].outcome)
            eventUpdatedCount += 1
            eventsUpdated.fulfill()
        }.store(in: &cancellables)

        return [notificationsSent, eventsUpdated]
    }

    // MARK: - Updated task notifications

    func testFetchWithTaskIDsReceivesUpdatedTaskNotifications() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupUpdatedTaskTest(controller: controller)

        controller.fetchAndObserveEvents(forTaskIDs: ["doxylamine"], eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    func testFetchWithTaskQueryReceivesUpdatedTaskNotifications() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupUpdatedTaskTest(controller: controller)

        var query = OCKTaskQuery()
        query.ids = ["doxylamine"]
        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    private func setupUpdatedTaskTest(controller: MockController) throws -> [XCTestExpectation] {

        // Create a task and add it to the store
        let doxylamineTask = OCKTask.mockAtMealtimes(taskID: "doxylamine")
        try store.addTaskAndWait(doxylamineTask)

        // Send update notifications once the controller subscribes
        let notificationSent = expectation(description: "Notification sent")
        var didStartSendingNotification = false
        controller.$subscribedToTasks.sink { count in
            guard count == 1 else { return }
            XCTAssertEqual(controller.taskEvents.events.count, 3)
            didStartSendingNotification = true
            let updatedTask = doxylamineTask.updatedWithDailySchedule()
            try! self.store.updateTaskAndWait(updatedTask)
            notificationSent.fulfill()
        }.store(in: &cancellables)

        // Validate the view model
        let eventsUpdated = expectation(description: "Events updated")
        controller.$taskEvents.sink { taskEvents in
            guard didStartSendingNotification, !taskEvents.isEmpty else { return }
            XCTAssertEqual(taskEvents.events.count, 1)
            eventsUpdated.fulfill()
        }.store(in: &cancellables)

        return [notificationSent, eventsUpdated]
    }

    // MARK: - Deleted task notifications

    func testFetchWithTaskIDsReceivesDeletedTaskNotifications() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupDeletedTaskNotificationTest(controller: controller)

        controller.fetchAndObserveEvents(forTaskIDs: ["doxylamine"], eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    func testFetchWithTaskQueryReceivesDeletedTaskNotifications() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupDeletedTaskNotificationTest(controller: controller)

        var query = OCKTaskQuery()
        query.ids = ["doxylamine"]
        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    private func setupDeletedTaskNotificationTest(controller: MockController) throws -> [XCTestExpectation] {
        // Create a task and add it to the store
        let doxylamineTask = OCKTask.mockAtMealtimes(taskID: "doxylamine")
        try store.addTaskAndWait(doxylamineTask)

        // Send the notifications once the controller subscribes
        let notificationSent = expectation(description: "Notification sent")
        var didStartSendingNotification = false
        controller.$subscribedToTasks.sink { count in
            guard count == 1 else { return }
            XCTAssertEqual(controller.taskEvents.events.count, 3)
            didStartSendingNotification = true
            try! self.store.deleteTaskAndWait(doxylamineTask)
            notificationSent.fulfill()
        }.store(in: &cancellables)

        // Validate the view model
        let eventsUpdated = expectation(description: "Events updated")
        controller.$taskEvents.dropFirst().sink { taskEvents in
            guard didStartSendingNotification else { return }
            XCTAssertTrue(taskEvents.isEmpty)
            eventsUpdated.fulfill()
        }.store(in: &cancellables)

        return [notificationSent, eventsUpdated]
    }

    // MARK: - Added task notifications

    func testFetchWithTaskIdsReceivesAddedTaskNotifications() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupAddedTaskNotificationTest(controller: controller,
                                                              subscribedPublisher: controller.$subscribedToTaskIDs.eraseToAnyPublisher())

        controller.fetchAndObserveEvents(forTaskIDs: ["doxylamine"], eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    func testFetchWithTaskQueryReceivesAddedTaskNotifications() throws {
        let controller = MockController(storeManager: manager)
        let expectations = try setupAddedTaskNotificationTest(controller: controller,
                                                              subscribedPublisher: controller.$subscribedToTaskQuery.eraseToAnyPublisher())

        var query = OCKTaskQuery()
        query.ids = ["doxylamine"]
        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        wait(for: expectations, timeout: 2)
    }

    private func setupAddedTaskNotificationTest(controller: MockController,
                                                subscribedPublisher publisher: AnyPublisher<Int, Never>) throws -> [XCTestExpectation] {
        let doxylamineTask = OCKTask.mockAtMealtimes(taskID: "doxylamine")

        // Send the notification once the controller subscribes
        let notificationSent = expectation(description: "Notification sent")
        var didStartSendingNotification = false
        publisher.sink { count in
            guard count == 1 else { return }
            XCTAssertTrue(controller.taskEvents.isEmpty)
            didStartSendingNotification = true
            try! self.store.addTaskAndWait(doxylamineTask)
            notificationSent.fulfill()
        }.store(in: &cancellables)

        // Validate the view model
        let eventsUpdated = expectation(description: "Events updated")
        controller.$taskEvents.dropFirst().sink { taskEvents in
            guard didStartSendingNotification, !taskEvents.isEmpty else { return }
            XCTAssertEqual(taskEvents.events.count, 3)
            eventsUpdated.fulfill()
        }.store(in: &cancellables)

        return [notificationSent, eventsUpdated]
    }

    // MARK: - Misc

    func testMultipleFetchesClearsViewModelForDayWithNoEvents() throws {
        let controller = MockController(storeManager: manager)
        let task = OCKTask.mockAtMealtimes(taskID: "doxylamine")
        try store.addTaskAndWait(task)

        var query = OCKTaskQuery()
        query.ids = ["doxylamine"]

        var count = 0
        let valuesFetched = expectation(description: "Value updated")
        valuesFetched.expectedFulfillmentCount = 2
        controller.$taskEvents.dropFirst().sink { taskEvents in
            count += 1

            // Refetch events with in a date range outside of the current schedule
            if count == 1 {
                XCTAssertEqual(taskEvents.events.count, 3)

                let beforeSchedule = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
                controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: beforeSchedule))
            } else if count == 2 {
                XCTAssertTrue(taskEvents.isEmpty)
            }

            valuesFetched.fulfill()
        }.store(in: &cancellables)

        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        wait(for: [valuesFetched], timeout: 2)
    }

    func testMultipleFetchAndObserveEventsExecutesOnce() throws {
        let controller = MockController(storeManager: manager)
        let task = OCKTask.mockAtMealtimes(taskID: "doxylamine")
        try store.addTaskAndWait(task)

        // The first fetch should get cancelled, and the view model should only get set once
        let valuesFetched = expectation(description: "Value updated")
        controller.$taskEvents.dropFirst().sink { taskEvents in
            XCTAssertEqual(taskEvents.events.count, 3)
            valuesFetched.fulfill()
        }.store(in: &cancellables)

        var query = OCKTaskQuery()
        query.ids = ["doxylamine"]

        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        wait(for: [valuesFetched], timeout: 2)
    }

    func testRefetchWithTaskIDsDoesNotCauseDuplicateViewModelUpdates() throws {
        let controller = MockController(storeManager: manager)
        let task = OCKTask.mockAtMealtimes(taskID: "doxylamine")
        try store.addTaskAndWait(task)

        // The first fetch should get cancelled, and the view model should only get set once
        let valuesFetched = expectation(description: "Value updated")
        valuesFetched.expectedFulfillmentCount = 2
        var count = 0
        controller.$taskEvents.dropFirst().sink { taskEvents in
            count += 1
            XCTAssertEqual(taskEvents.events.count, 3)

            // Now fetch events with a task ID
            if count == 1 {
                controller.fetchAndObserveEvents(forTaskIDs: ["doxylamine"], eventQuery: .init(for: Date()))
            }

            valuesFetched.fulfill()
        }.store(in: &cancellables)

        var query = OCKTaskQuery()
        query.ids = ["doxylamine"]

        // Begin by fetching events with a task query
        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        wait(for: [valuesFetched], timeout: 2)
    }

    func testNotificationsForMultipleTaskIDsUpdateViewModelIndependently() throws {
        let controller = MockController(storeManager: manager)
        let doxylamine = OCKTask.mockAtMealtimes(taskID: "doxylamine")
        let nauseau = OCKTask.mockAtMealtimes(taskID: "nausea")
        try store.addTasksAndWait([doxylamine, nauseau])

        // Send the notification once the controller subscribes
        let notificationSent = expectation(description: "Notification sent")
        var didStartSendingNotification = false
        controller.$subscribedToTasks.sink { count in
            guard count == 1 else { return }
            XCTAssertEqual(controller.taskEvents.events.count, 6)
            didStartSendingNotification = true

            // Send multiple task notifications
            try! self.store.deleteTaskAndWait(doxylamine)
            try! self.store.deleteTaskAndWait(nauseau)

            notificationSent.fulfill()
        }.store(in: &cancellables)

        // Validate the view model
        let eventsUpdated = expectation(description: "Events updated")
        eventsUpdated.expectedFulfillmentCount = 2
        var count = 0
        controller.$taskEvents.dropFirst().sink { taskEvents in
            guard didStartSendingNotification else { return }
            count += 1

            // We cannot guarantee which update comes first because they are done asynchronously, but each update removes three events
            if count == 1 {
                XCTAssertEqual(taskEvents.events.count, 3)
            } else if count == 2 {
                XCTAssertTrue(taskEvents.isEmpty)
            }

            eventsUpdated.fulfill()
        }.store(in: &cancellables)

        var query = OCKTaskQuery()
        query.ids = ["doxylamine", "nausea"]

        controller.fetchAndObserveEvents(forTaskQuery: query, eventQuery: .init(for: Date()))
        wait(for: [notificationSent, eventsUpdated], timeout: 2)
    }

    func testErrorPropagates() {
        let errorOccurred = XCTestExpectation(description: "error occurred")
        let controller = MockController(storeManager: manager)
        controller.$error
            .compactMap { $0 }
            .sink { error in
                XCTAssertNotNil(error as? MockError)
                errorOccurred.fulfill()
            }
            .store(in: &cancellables)
        controller.error = MockError()
        wait(for: [errorOccurred], timeout: 1)
    }

    private func sendUpdateOutcomeNotificationsTo(controller: OCKTaskController, events: [OCKEvent<OCKTask, OCKOutcome>]) {
        events.forEach {
            let notification = OCKOutcomeNotification(outcome: $0.outcome!, category: .update, storeManager: controller.storeManager)
            controller.storeManager.subject.send(notification)
        }
    }
}

private extension OCKTask {
    static func mockAtMealtimes(taskID: String) -> OCKTask {
        .init(id: taskID, title: nil, carePlanUUID: nil, schedule: .mealtimes)
    }

    func updatedWithDailySchedule() -> OCKTask {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return .init(id: id, title: title, carePlanUUID: carePlanUUID,
                     schedule: .dailyAtTime(hour: 1, minutes: 0, start: startOfDay, end: nil, text: nil))
    }
}

private extension OCKAnyEvent {

    static func mockDaily(taskUUID: UUID, occurrence: Int, hasOutcome: Bool = false) -> OCKAnyEvent {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.dailyAtTime(hour: 1, minutes: 0, start: startOfDay, end: nil, text: nil)
        var task = OCKTask(id: taskUUID.uuidString, title: nil, carePlanUUID: nil, schedule: schedule)
        task.uuid = taskUUID

        let outcome = hasOutcome ?
            OCKOutcome(taskUUID: task.uuid!, taskOccurrenceIndex: occurrence, values: []) :
            nil

        let event = OCKAnyEvent(task: task, outcome: outcome, scheduleEvent: schedule.event(forOccurrenceIndex: occurrence)!)
        return event
    }
}

private extension OCKEvent where Task == OCKTask, Outcome == OCKOutcome {
    func updatedWithOutcome() -> Self {
        var newEvent = self
        newEvent.outcome = OCKOutcome(taskUUID: newEvent.task.uuid!, taskOccurrenceIndex: newEvent.scheduleEvent.occurrence, values: [])
        return newEvent
    }
}

private extension OCKSchedule {
    static var mealtimes: OCKSchedule {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let breakfast = OCKSchedule.dailyAtTime(hour: 7, minutes: 0, start: startOfDay, end: nil, text: nil)
        let lunch = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: startOfDay, end: nil, text: nil)
        let dinner = OCKSchedule.dailyAtTime(hour: 18, minutes: 0, start: startOfDay, end: nil, text: nil)
        return .init(composing: [breakfast, lunch, dinner])
    }
}

private extension OCKAnyEvent {
    init(_ event: OCKEvent<OCKTask, OCKOutcome>) {
        self.init(task: event.task, outcome: event.outcome, scheduleEvent: event.scheduleEvent)
    }
}

private class MockController: OCKTaskController {

    @Published var subscribedToTasks = 0
    @Published var subscribedToTaskQuery = 0
    @Published var subscribedToTaskIDs = 0

    override func subscribeTo(tasks: [OCKAnyTask], query: OCKEventQuery) {
        super.subscribeTo(tasks: tasks, query: query)
        subscribedToTasks += 1
    }

    override func refreshOnAddedTaskNotificationFor(taskIDs: [String], query: OCKEventQuery) {
        super.refreshOnAddedTaskNotificationFor(taskIDs: taskIDs, query: query)
        subscribedToTaskIDs += 1
    }

    override func refreshOnAddedTaskNotificationFor(taskQuery: OCKTaskQuery, eventQuery: OCKEventQuery) {
        super.refreshOnAddedTaskNotificationFor(taskQuery: taskQuery, eventQuery: eventQuery)
        subscribedToTaskQuery += 1
    }
}

private extension OCKTaskEvents {
    var events: [OCKAnyEvent] { flatMap { $0 } }
}

private struct MockError: Error {}


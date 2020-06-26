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

@testable import CareKit
@testable import CareKitStore
import CareKitUI
import Foundation
import XCTest

private extension OCKTask {

    static let id = UUID()

    static func mockWithEvents(forDate date: Date, impactsAdherence: Bool, eventCount: Int) -> (OCKTask, [OCKAnyEvent]) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let schedules = (1...eventCount).map {
            OCKSchedule.dailyAtTime(hour: $0, minutes: 0, start: startOfDay, end: nil, text: nil)
        }
        var task = OCKTask(id: "doxylamine", title: "Doxylamine", carePlanUUID: nil, schedule: .init(composing: schedules))
        task.uuid = id
        task.impactsAdherence = impactsAdherence
        let events = schedules.enumerated().map {
            return OCKAnyEvent(task: task, outcome: nil, scheduleEvent: $1.event(forOccurrenceIndex: $0)!)
        }
        return (task, events)
    }
}

class TestDailyTasksPageViewController: XCTestCase {

    var viewController: OCKDailyTasksPageViewController!

    override func setUp() {
        super.setUp()
        let store = OCKStore(name: "test-store", type: .inMemory)
        viewController = .init(storeManager: .init(wrapping: store))
    }

    func testDelegate() {
        viewController.loadViewIfNeeded()
        XCTAssertTrue(viewController.tasksDelegate === viewController)
    }

    func testViewControllerForTask() {
        // Expecting a grid filled with the correct data
        var (task, events) = OCKTask.mockWithEvents(forDate: Date(), impactsAdherence: true, eventCount: 2)
        var observedViewController = viewController.dailyTasksPageViewController(viewController, viewControllerForTask: task, events: events,
                                                                                 eventQuery: .init(for: Date()))
        let expectedViewController1 = observedViewController as? OCKGridTaskViewController
        XCTAssertNotNil(expectedViewController1)
        XCTAssertEqual(events.count, expectedViewController1?.controller.taskEvents.first?.count)
        events.enumerated().forEach { offset, expectedEvent in
            let observedEvent = expectedViewController1?.controller.taskEvents[0][offset]
            XCTAssertEqual(expectedEvent.task.id, observedEvent?.task.id)
            XCTAssertEqual(expectedEvent.scheduleEvent.occurrence, observedEvent?.scheduleEvent.occurrence)
        }

        // Expecting a button log filled with the correct data
        (task, events) = OCKTask.mockWithEvents(forDate: Date(), impactsAdherence: false, eventCount: 2)
        observedViewController = viewController.dailyTasksPageViewController(viewController, viewControllerForTask: task, events: events,
                                                                             eventQuery: .init(for: Date()))
        let expectedViewController2 = observedViewController as? OCKButtonLogTaskViewController
        XCTAssertNotNil(expectedViewController2)
        XCTAssertEqual(events.count, expectedViewController2?.controller.taskEvents.first?.count)
        events.enumerated().forEach { offset, expectedEvent in
            let observedEvent = expectedViewController2?.controller.taskEvents[0][offset]
            XCTAssertEqual(expectedEvent.task.id, observedEvent?.task.id)
            XCTAssertEqual(expectedEvent.scheduleEvent.occurrence, observedEvent?.scheduleEvent.occurrence)
        }

        // Expecting a simple log filled with the correct data
        (task, events) = OCKTask.mockWithEvents(forDate: Date(), impactsAdherence: true, eventCount: 1)
        observedViewController = viewController.dailyTasksPageViewController(viewController, viewControllerForTask: task, events: events,
                                                                             eventQuery: .init(for: Date()))
        let expectedViewController3 = observedViewController as? OCKSimpleTaskViewController
        XCTAssertNotNil(expectedViewController3)
        XCTAssertEqual(events.count, expectedViewController3?.controller.taskEvents.first?.count)
        events.enumerated().forEach { offset, expectedEvent in
            let observedEvent = expectedViewController3?.controller.taskEvents[0][offset]
            XCTAssertEqual(expectedEvent.task.id, observedEvent?.task.id)
            XCTAssertEqual(expectedEvent.scheduleEvent.occurrence, observedEvent?.scheduleEvent.occurrence)
        }
    }
}

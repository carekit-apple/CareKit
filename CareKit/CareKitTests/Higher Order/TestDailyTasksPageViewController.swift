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

class TestDailyTasksPageViewController: XCTestCase {

    private var dailyTasksViewController: OCKDailyTasksPageViewController!
    private var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
        dailyTasksViewController = OCKDailyTasksPageViewController(store: store)
    }

    func testGridIsCreated() throws {
        let task = OCKTask.sample(
            uuid: UUID(),
            id: "task",
            schedule: .mealTimesEachDay(startingOn: Date())
        )
        try store.addAnyTaskAndWait(task)
        let events = task.anyEvents(for: Date())

        let gridViewController = dailyTasksViewController.dailyTasksPageViewController(
            dailyTasksViewController,
            viewControllerForTask: task,
            events: events,
            eventQuery: .init(for: Date())
        ) as? OCKGridTaskViewController

        // Validate the view controller type
        XCTAssertNotNil(gridViewController)
    }

    func testButtonLogIsCreated() throws {
        let task = OCKTask.sample(
            uuid: UUID(),
            id: "task",
            schedule: .mealTimesEachDay(startingOn: Date()),
            impactsAdherence: false
        )
        try store.addAnyTaskAndWait(task)
        let events = task.anyEvents(for: Date())

        let buttonLogViewController = dailyTasksViewController.dailyTasksPageViewController(
            dailyTasksViewController,
            viewControllerForTask: task,
            events: events,
            eventQuery: .init(for: Date())
        ) as? OCKButtonLogTaskViewController

        // Validate the view controller type
        XCTAssertNotNil(buttonLogViewController)
    }

    func testSimpleIsCreated() throws {
        let task = OCKTask.sample(uuid: UUID(), id: "task")
        try store.addAnyTaskAndWait(task)
        let events = task.anyEvents(for: Date())

        let simpleViewController = dailyTasksViewController.dailyTasksPageViewController(
            dailyTasksViewController,
            viewControllerForTask: task,
            events: events,
            eventQuery: OCKEventQuery(for: Date())
        ) as? OCKSimpleTaskViewController

        // Validate the view controller type
        XCTAssertNotNil(simpleViewController)
    }
}

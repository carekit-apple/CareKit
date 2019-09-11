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
import UIKit
import XCTest

private class MockCalendarView: UIView, OCKCalendarDisplayable {
    static var intervalComponent: Calendar.Component = .month
    var completionRings: [OCKCompletionRingButton] = []
    var intervalComponent: Calendar.Component = .month
    weak var delegate: OCKCalendarViewDelegate?
    var selectedDate = Date()
    var dateInterval: DateInterval = MockCalendarView.monthDateInterval(for: Date())

    func selectDate(_ date: Date) {
        guard let ring = completionRingFor(date: date) else { return }
        completionRings.first(where: { $0.isSelected })?.isSelected = false
        ring.isSelected = true
        selectedDate = date
    }

    func showDate(_ date: Date) {
        completionRings = []
        let numberOfDays = Calendar.current.dateComponents([.day], from: dateInterval.start, to: dateInterval.end).day!
        for _ in 0...numberOfDays {
            completionRings.append(.init())
        }
        selectDate(date)
        dateInterval = MockCalendarView.monthDateInterval(for: date)
    }

    func completionRingFor(date: Date) -> OCKCompletionRingButton? {
        let offset = Calendar.current.dateComponents([.day], from: dateInterval.start, to: date).day!
        guard offset < completionRings.count else { return nil }
        return completionRings[offset]
    }

    private static func monthDateInterval(for date: Date) -> DateInterval {
        var interval = Calendar.current.dateInterval(of: .month, for: date)!
        interval.duration -= 1   // The default interval contains 1 second of the next day after the interval. Subtract that off
        return interval
    }
}

private class MockCalendarViewController: OCKCalendarViewController<MockCalendarView, OCKStore> {
    typealias View = MockCalendarView

    override func makeView() -> MockCalendarView {
        return .init()
    }

    override func updateView(_ view: MockCalendarView, context: OCKSynchronizationContext<[OCKCompletionRingButton.CompletionState]>) { }
}

private class MonthPageViewController: OCKCalendarPageViewController<MockCalendarViewController, OCKStore> {
    override func makeViewController(for date: Date) -> MockCalendarViewController {
        let viewController = MockCalendarViewController(storeManager: storeManager, date: date, aggregator: aggregator)
        let interval = Calendar.current.dateInterval(of: MockCalendarViewController.View.intervalComponent, for: date)!
        viewController.calendarView.showDate(interval.start)
        viewController.calendarView.delegate = self
        return viewController
    }
}

class TestAbstractPageViewController: XCTestCase {
    enum Constants {
        static let timeout: TimeInterval = 5
    }

    var storeManager: OCKSynchronizedStoreManager<OCKStore>!
    private var delegateManager: MockSynchronizationDelegate<OCKStore.Event>!
    var task: OCKTask!

    override func setUp() {
        super.setUp()
        storeManager = OCKSynchronizedStoreManager(wrapping: OCKStore(name: "ckstore", type: .inMemory))

        // add new task
        let task = OCKTask(identifier: "doxylamine", title: "Doxylamine", carePlanID: nil,
                           schedule: .mealTimesEachDay(start: Calendar.current.startOfDay(for: Date()), end: nil))
        self.task = try? storeManager.store.addTaskAndWait(task)
        XCTAssertNotNil(self.task)
    }

    func testSelectedRing() {
        // Test selection for the current day
        let pageViewController = MonthPageViewController(storeManager: storeManager, aggregator: .countOutcomes)
        pageViewController.loadViewIfNeeded()
        let today = Date()
        var dayNumber = Calendar.current.component(.day, from: today)
        let view = pageViewController.currentViewController?.calendarView as? MockCalendarView
        let completionRingToday = view?.completionRingFor(date: today)
        XCTAssertNotNil(completionRingToday)
        XCTAssertTrue(completionRingToday?.isSelected ?? false)
        XCTAssertNotNil(view?.selectedDate)
        if let selectedDate = view?.selectedDate {
            XCTAssertTrue(Calendar.current.isDate(selectedDate, inSameDayAs: today))
        }

        // check if tomorrow is in the current month. If not, test yesterday
        var offsetDate = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        dayNumber += 1
        if !Calendar.current.isDate(offsetDate, equalTo: today, toGranularity: .month) {
            offsetDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            dayNumber -= 2
        }

        // Test selection for tomorrow/yesterday
        pageViewController.currentViewController?.calendarView.selectDate(offsetDate)
        let completionRingForOffsetDate = view?.completionRingFor(date: offsetDate)
        XCTAssertNotNil(completionRingForOffsetDate)
        XCTAssertNotEqual(completionRingForOffsetDate, completionRingToday)
        XCTAssertTrue(completionRingForOffsetDate?.isSelected ?? false)
        XCTAssertNotNil(view?.selectedDate)
        if let selectedDate = view?.selectedDate {
            XCTAssertTrue(Calendar.current.isDate(selectedDate, inSameDayAs: offsetDate))
        }
    }

    func testPaging() {
        // Ensure the view controller is showing the current month
        let pageViewController = MonthPageViewController(storeManager: storeManager, aggregator: .countOutcomes)
        pageViewController.loadViewIfNeeded()
        var view = pageViewController.currentViewController?.calendarView
        let today = Date()
        var currentInterval = Calendar.current.dateInterval(of: .month, for: today)!
        currentInterval.duration -= 1   // The default interval contains 1 second of the next day after the interval. Subtract that off
        var displayedInterval = view?.dateInterval
        XCTAssertNotNil(view)
        XCTAssertEqual(currentInterval, displayedInterval)

        // Check the number of completion rings
        var customView = view as? MockCalendarView
        var numberOfDays = numberOfDaysInMonthOf(date: today)
        var numberOfCompletionRings = customView?.completionRings.count
        XCTAssertNotNil(customView)
        XCTAssertEqual(numberOfDays, numberOfCompletionRings)

        // Ensure the view controller is displaying the next month
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today)!
        pageViewController.selectDate(nextMonth, animated: false)
        var nextMonthInterval = Calendar.current.dateInterval(of: .month, for: nextMonth)!
        nextMonthInterval.duration -= 1   // The default interval contains 1 second of the next day after the interval. Subtract that off
        view = pageViewController.currentViewController?.calendarView
        displayedInterval = view?.dateInterval
        XCTAssertNotNil(view)
        XCTAssertEqual(nextMonthInterval, displayedInterval)

        // Check the number of completion rings
        customView = view as? MockCalendarView
        numberOfDays = numberOfDaysInMonthOf(date: nextMonth)
        numberOfCompletionRings = customView?.completionRings.count
        XCTAssertNotNil(customView)
        XCTAssertEqual(numberOfDays, numberOfCompletionRings)
    }

    func numberOfDaysInMonthOf(date: Date) -> Int {
        let components = Calendar.current.dateComponents([.month, .year], from: date)
        let month = Calendar.current.date(from: components)!
        let range = Calendar.current.range(of: .day, in: .month, for: month)!
        return range.count
    }
}

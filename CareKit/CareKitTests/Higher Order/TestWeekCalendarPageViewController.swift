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
import CareKitStore
import Foundation
import XCTest

class TestWeekCalendarPageViewController: XCTestCase {

    private var viewController: MockWeekCalendarPageViewController!

    var storeManager: OCKSynchronizedStoreManager!

    let today = Calendar.current.startOfDay(for: Date())

    override func setUp() {
        super.setUp()
        let store = OCKStore(name: "test-store", type: .inMemory)
        self.storeManager = .init(wrapping: store)
        viewController = .init(storeManager: storeManager, aggregator: .outcomeExists, currentViewControllerDate: today)
    }

    func testPreviousSelectedDateStartsAsToday() {
        XCTAssertTrue(Calendar.current.isDate(viewController.previousSelectedDate, inSameDayAs: today))
    }

    func testPreviousSelectedDateUpdatesOnManualSelection() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        viewController.selectDate(tomorrow, animated: false)
        XCTAssertTrue(Calendar.current.isDate(today, inSameDayAs: viewController.previousSelectedDate))
    }

    func testPreviousSelectedDateUpdatesOnPageUpdate() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let previousPage = OCKWeekCalendarViewController(weekOfDate: tomorrow, aggregator: .outcomeExists, storeManager: storeManager)

        // Simulate the end of the transition to the next page
        viewController.pageViewController(viewController, didFinishAnimating: true,
                                          previousViewControllers: [previousPage], transitionCompleted: true)

        XCTAssertTrue(Calendar.current.isDate(tomorrow, inSameDayAs: viewController.previousSelectedDate))
    }
}

private class MockWeekCalendarPageViewController: OCKWeekCalendarPageViewController {

    private let currentViewControllerDate: Date

    init(storeManager: OCKSynchronizedStoreManager, aggregator: OCKAdherenceAggregator, currentViewControllerDate: Date) {
        self.currentViewControllerDate = currentViewControllerDate
        super.init(storeManager: storeManager, aggregator: aggregator)
    }

    override var currentViewController: OCKWeekCalendarViewController? {
        .init(weekOfDate: currentViewControllerDate, aggregator: .outcomeExists, storeManager: storeManager)
    }
}

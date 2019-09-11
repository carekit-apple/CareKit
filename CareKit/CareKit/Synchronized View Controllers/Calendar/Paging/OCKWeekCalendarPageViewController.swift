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

import CareKitStore
import CareKitUI
import UIKit

/// Paging view controller that displays an `OCKWeekCalendarViewController` and handles displaying days when paged.
open class OCKWeekCalendarPageViewController<Store: OCKStoreProtocol>: OCKCalendarPageViewController<OCKWeekCalendarViewController<Store>, Store> {
    /// The type of the view controller used by this page view controller.
    public typealias ViewController = OCKWeekCalendarViewController

    /// Create an instance that when paged, will update the days in the calendar automatically. Scrolling is horizontal by default.
    /// - Parameter storeManager: The store manager used to provide synchronization.
    /// - Parameter aggregator: Aggregator that can be used when creating an `OCKCalendarDisplayer` instance.
    override public init(storeManager: OCKSynchronizedStoreManager<Store>, aggregator: OCKAdherenceAggregator<Store.Event> = .countOutcomes) {
        super.init(storeManager: storeManager, aggregator: aggregator)
    }

    /// Makes a view controller for a particular date.
    /// - Parameter date: The date displayed by the view controller.
    override open func makeViewController(for date: Date) -> OCKWeekCalendarViewController<Store> {
        let viewController = OCKWeekCalendarViewController(storeManager: storeManager, date: date, aggregator: aggregator)
        let interval = Calendar.current.dateInterval(of: ViewController.View.intervalComponent, for: date)!
        viewController.calendarView.showDate(interval.start)
        viewController.calendarView.delegate = self
        return viewController
    }
}

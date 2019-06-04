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

import UIKit
import CareKitStore
import CareKitUI

internal protocol OCKCalendarPageViewControllerDelegate: class {
    func calendarPageViewController<Store: OCKStoreProtocol>(
        _ calendarPageViewController: OCKCalendarPageViewController<Store>,
        didSelectDate date: Date, previousDate: Date?)
    
    func calendarPageViewController<Store: OCKStoreProtocol>(
        _ calendarPageViewController: OCKCalendarPageViewController<Store>,
        didChangeDateInterval interval: DateInterval)
    
    func calendarPageViewController<Store: OCKStoreProtocol>(
        _ calendarPageViewController: OCKCalendarPageViewController<Store>,
        didFailWithError error: Error)
}

internal class OCKCalendarPageViewController<Store: OCKStoreProtocol>:
UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, OCKCalendarViewControllerDelegate, OCKCalendarWeekViewDelegate {
    
    public weak var calendarDelegate: OCKCalendarPageViewControllerDelegate?
    
    private let storeManager: OCKSynchronizedStoreManager<Store>
    
    private var week = Calendar.current.component(.weekOfYear, from: Date())
    private var year = Calendar.current.component(.year, from: Date())
    
    private var previouslySelectedDate: Date?
    
    public var selectedDate: Date {
        guard let weekView = currentViewController?.calendarWeekView else { return Date() }
        return Calendar.current.date(byAdding: .day, value: weekView.selectedIndex, to: weekView.dateRange.start)!
    }
    
    public var currentDateRange: DateInterval {
        return dateIntervalFor(week: week, year: year)
    }
    
    internal var currentViewController: OCKWeekCalendarViewController<Store>? {
        return viewControllers?.first as? OCKWeekCalendarViewController<Store>
    }

    public init(storeManager: OCKSynchronizedStoreManager<Store>) {
        self.storeManager = storeManager
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        let now = Date()
        let viewController = makeViewController(week: week, year: year)
        let completionRingButton = viewController.calendarWeekView.completionRingFor(date: now)
        completionRingButton?.sendActions(for: .touchUpInside)
        setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
        calendarDelegate?.calendarPageViewController(self, didSelectDate: now, previousDate: nil)
    }
    
    private func makeViewController(week: Int, year: Int) -> OCKWeekCalendarViewController<Store> {
        let interval = dateIntervalFor(week: week, year: year)
        let query = OCKAdherenceQuery(dateInterval: interval)
        let viewController = OCKWeekCalendarViewController(storeManager: storeManager, adherenceQuery: query)
        viewController.calendarWeekView.displayWeek(of: interval.start)
        viewController.calendarWeekView.delegate = self
        viewController.unsubscribesWhenNotShown = false
        return viewController
    }
    
    public func selectDate(_ date: Date, animated: Bool) {
        guard let currentVC = currentViewController else { return }
        if currentVC.calendarWeekView.dateRange.contains(date) {
            currentVC.calendarWeekView.selectDate(date)
            return
        }
        
        let isLeft = currentVC.calendarWeekView.dateRange.start > date
        week = Calendar.current.component(.weekOfYear, from: date)
        year = Calendar.current.component(.year, from: date)
        let nextVC = makeViewController(week: week, year: year)
        
        nextVC.calendarWeekView.selectDate(date)
        self.setViewControllers([nextVC], direction: isLeft ? .reverse : .forward,
                                animated: animated, completion: nil)
    }
    
    private func weekAndYearShiftedBy(weeks: Int) -> (week: Int, year: Int) {
        let shiftedStartDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: currentDateRange.start)!
        let week = Calendar.current.component(.weekOfYear, from: shiftedStartDate)
        let year = Calendar.current.component(.year, from: shiftedStartDate)
        return (week, year)
    }
    
    private func dateIntervalFor(week: Int, year: Int) -> DateInterval {
        let components = DateComponents(year: year, weekday: 1, weekOfYear: week)
        let start = Calendar.current.date(from: components)!
        let end = Calendar.current.date(byAdding: DateComponents(second: -1, weekOfYear: 1), to: start)!
        return DateInterval(start: start, end: end)
    }
    
    // MARK: UIPageViewController DataSource & Delegate
    
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let (week, year) = weekAndYearShiftedBy(weeks: -1)
        let previousPage = makeViewController(week: week, year: year)
        return previousPage
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let (week, year) = weekAndYearShiftedBy(weeks: 1)
        let previousPage = makeViewController(week: week, year: year)
        return previousPage
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                   previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
            let previousViewController = previousViewControllers.first as? OCKWeekCalendarViewController<Store>,
            let currentViewController = currentViewController
        else { return }
        
        let startComponents = Calendar.current.dateComponents([.weekOfYear, .year], from: currentViewController.calendarWeekView.dateRange.start)
        week = startComponents.weekOfYear!
        year = startComponents.year!
        
        let targetRing = currentViewController.calendarWeekView.completionRingButtons[previousViewController.calendarWeekView.selectedIndex]
        targetRing.sendActions(for: .touchUpInside)
        calendarDelegate?.calendarPageViewController(self, didChangeDateInterval: dateIntervalFor(week: week, year: year))
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard
            let viewController = pendingViewControllers.first as? OCKWeekCalendarViewController<Store>,
            let selectedIndex = currentViewController?.calendarWeekView.selectedIndex
        else { return }
        let tempSelectedDate = Calendar.current.date(byAdding: .day, value: selectedIndex, to: viewController.calendarWeekView.dateRange.start)!
        viewController.calendarWeekView.selectDate(tempSelectedDate)
    }

    // MARK: OCKCalendarViewControllerDelegate
    func calendarViewController<S>(
        _ calendarViewController: OCKCalendarViewController<S>,
        didFailWithError error: Error) where S: OCKStoreProtocol {
        calendarDelegate?.calendarPageViewController(self, didFailWithError: error)
    }
    
    // MARK: OCKCalendarWeekViewDelegate
    
    public func calendarWeekView(_ calendar: OCKCalendarWeekView, didSelectDate date: Date, at index: Int) {
        let comparison = Calendar.current.compare(calendar.dateRange.start, to: currentDateRange.start, toGranularity: .weekOfYear)
        guard comparison == .orderedSame else { return }
        calendarDelegate?.calendarPageViewController(self, didSelectDate: date, previousDate: previouslySelectedDate)
        previouslySelectedDate = date
    }
}

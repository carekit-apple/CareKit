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
#if !os(watchOS)

import CareKitStore
import CareKitUI
import UIKit

/// Handles events related to an `OCKWeekCalendarPageViewController`.
public protocol OCKWeekCalendarPageViewControllerDelegate: AnyObject {
    /// Called when a date in the calendar has been selected.
    /// - Parameter viewController: The view controller that displays the calendar.
    /// - Parameter date: The newly selected date.
    /// - Parameter previousDate: The previously selected date.
    func weekCalendarPageViewController(_ viewController: OCKWeekCalendarPageViewController, didSelectDate date: Date, previousDate: Date)

    /// Called when the date interval in the calendar has been changed.
    /// - Parameter viewController: The view controller that displays the calendar.
    /// - Parameter interval: The new date interval.
    func weekCalendarPageViewController(_ viewController: OCKWeekCalendarPageViewController, didChangeDateInterval interval: DateInterval)

    func weekCalendarPageViewController(_ viewController: OCKWeekCalendarPageViewController, didEncounterError error: Error)
}

/// A view controller that allows paging through adjacent weeks of task adherence content.
open class OCKWeekCalendarPageViewController:
UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, OCKCalendarViewDelegate {
    // MARK: Properties

    /// Handles events related to an `OCKCalendarPageViewController`.
    public weak var calendarDelegate: OCKWeekCalendarPageViewControllerDelegate?

    /// The currently selected date in the calendar.
    public var selectedDate: Date {
        return currentViewController?.calendarView.selectedDate ?? startingDate
    }

    /// The date interval currently being displayed.
    public var dateInterval: DateInterval? {
        return currentViewController?.calendarView.dateInterval
    }

    private var currentViewController: OCKWeekCalendarViewController? {
        guard
            let viewControllers = viewControllers,
            !viewControllers.isEmpty else { return nil }

        guard let viewController = viewControllers.first! as? OCKWeekCalendarViewController else { fatalError("Unsupported type") }
        return viewController
    }

    private let aggregator: OCKAdherenceAggregator

    // Many of the methods in this class get called when the selected date did change. During those times, this property helps access
    // the previous value.
    private(set) var cachedSelectedDate = Date()

    /// The initial date displayed when the view controller is loaded.
    private let startingDate = Date()

    let storeManager: OCKSynchronizedStoreManager

    // MARK: - Life Cycle

    public init(storeManager: OCKSynchronizedStoreManager, aggregator: OCKAdherenceAggregator) {
        self.storeManager = storeManager
        self.aggregator = aggregator
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        // Create the first view controller
        let viewController = makeViewController(forDate: startingDate)
        viewController.calendarView.delegate = self
        viewController.calendarView.selectDate(startingDate)
        setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
    }

    // MARK: - Methods

    private func makeViewController(forDate date: Date) -> OCKWeekCalendarViewController {
        let viewController = OCKWeekCalendarViewController(weekOfDate: date, aggregator: aggregator, storeManager: storeManager)
        viewController.calendarView.showDate(date)
        viewController.calendarView.delegate = self
        return viewController
    }

    // Send errors through to the calendarDelegate
    private func handleResult(_ result: Result<[OCKCompletionState], OCKStoreError>) {
        switch result {
        case .failure(let error):
            if calendarDelegate == nil {
                log(.error, "A calendar error occurred, but no delegate was set to forward it to!", error: error)
            }
            calendarDelegate?.weekCalendarPageViewController(self, didEncounterError: error)
        case .success: break
        }
    }

    private func makePage(beside page: OCKWeekCalendarViewController, addingWeeks value: Int) -> OCKWeekCalendarViewController {
        let baseDate = page.calendarView.selectedDate
        let nextDate = Calendar.current.date(byAdding: .weekOfYear, value: value, to: baseDate)!
        let page = makeViewController(forDate: nextDate)
        return page
    }

    /// Select a date in the calendar. If the date is not in the current date interval being displayed, the view controller will automatically
    /// page to the date interval that contains the new date.
    /// - Parameter date: The new date to select.
    /// - Parameter animated: True to animate selection of the new date.
    open func selectDate(_ date: Date, animated: Bool) {
        guard
            !Calendar.current.isDate(date, inSameDayAs: selectedDate),
            let dateInterval = dateInterval
        else { return }

        // Always make sure to update the cached selected date. Note that in this context, `cachedSelectedDate` is the current value
        // for the selected date since this method is called on `willSelect`.
        defer {
            cachedSelectedDate = date
        }

        // If the new date is within the currently displayed week, select it
        if dateInterval.contains(date) {
            currentViewController?.calendarView.selectDate(date)
            return
        }

        // Else create a new calendar view that contains the new date
        let nextVC = makeViewController(forDate: date)
        let isLeft = dateInterval.start > date
        setViewControllers([nextVC], direction: isLeft ? .reverse : .forward, animated: animated, completion: nil)
    }

    // MARK: UIPageViewController DataSource & Delegate

    open func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? OCKWeekCalendarViewController else { fatalError("Unsupported type") }
        return makePage(beside: page, addingWeeks: -1)
    }

    open func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let page = viewController as? OCKWeekCalendarViewController else { fatalError("Unsupported type") }
        return makePage(beside: page, addingWeeks: 1)
    }

    open func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        // Update each calendar to select the ring that is on the same weekday as the current selected ring. That way when transitioning to a
        // new page, the correct ring will be displayed immediately.
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        pendingViewControllers
            .compactMap { $0 as? OCKWeekCalendarViewController }
            .forEach {
                let newSelectedDate = Calendar.current.date(bySetting: .weekday, value: weekday, of: $0.calendarView.dateInterval.start)!
                $0.calendarView.selectDate(newSelectedDate)
            }
    }

    open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                 previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard
            completed,
            let dateInterval = dateInterval
        else { return }

        // Notify the delegate to update the displayed tasks. Note that in this context, `cachedSelectedDate` is the old value
        // for the selected date since this method is called on `didFinish`.
        calendarDelegate?.weekCalendarPageViewController(self, didChangeDateInterval: dateInterval)
        calendarDelegate?.weekCalendarPageViewController(self, didSelectDate: selectedDate, previousDate: cachedSelectedDate)

        cachedSelectedDate = selectedDate
    }

    // MARK: OCKCalendarViewDelegate

    /// Called when a particular date in the calendar was selected.
    /// - Parameter calendarView: The view displaying the calendar.
    /// - Parameter date: The date that was selected.
    /// - Parameter index: The index of the date that was selected with respect to the collection of days in the current `dateInterval`.
    /// - Parameter sender: The sender that initiated the selection.
    open func calendarView(_ calendarView: UIView & OCKCalendarDisplayable, didSelectDate date: Date, at index: Int, sender: Any?) {
        guard
            let startOfWeek = dateInterval?.start,
            let dateInterval = dateInterval
        else { return }

        // Make sure the selected date exists in the current calendar page
        let comparison = Calendar.current.compare(dateInterval.start, to: startOfWeek, toGranularity: .weekOfYear)
        guard comparison == .orderedSame else { return }

        // Notify the delegate to update the displayed tasks. Note that in this context, `cachedSelectedDate` is the old value
        // for the selected date since this method is called on `didSelect`.
        calendarDelegate?.weekCalendarPageViewController(self, didSelectDate: date, previousDate: cachedSelectedDate)

        cachedSelectedDate = date
    }
}
#endif

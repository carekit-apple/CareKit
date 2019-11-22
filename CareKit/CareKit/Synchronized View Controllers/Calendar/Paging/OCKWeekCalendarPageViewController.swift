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
        return currentViewController?.calendarView.selectedDate ?? Date()
    }

    /// The date interval currently being displayed.
    public var dateInterval: DateInterval? {
        return currentViewController?.calendarView.dateInterval
    }

    private let aggregator: OCKAdherenceAggregator
    private var previouslySelectedDate = Date()
    private let storeManager: OCKSynchronizedStoreManager

    var currentViewController: OCKWeekCalendarViewController? {
        guard
            let viewControllers = viewControllers,
            !viewControllers.isEmpty else { return nil }

        guard let viewController = viewControllers.first! as? OCKWeekCalendarViewController else { fatalError("Unsupported type") }
        return viewController
    }

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
        let viewController = makeViewController(forDate: previouslySelectedDate)
        viewController.calendarView.delegate = self
        viewController.calendarView.selectDate(previouslySelectedDate)
        setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
    }

    // MARK: - Methods

    private func makeViewController(forDate date: Date) -> OCKWeekCalendarViewController {
        let viewController = OCKWeekCalendarViewController(weekOfDate: date, aggregator: aggregator, storeManager: storeManager)

        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: date)!
        viewController.calendarView.showDate(interval.start)
        return viewController
    }

    // Send errors through to the calendarDelegate
    private func handleResult(_ result: Result<[OCKCompletionRingButton.CompletionState], OCKStoreError>) {
        switch result {
        case .failure(let error): calendarDelegate?.weekCalendarPageViewController(self, didEncounterError: error)
        case .success: break
        }
    }

    /// Select a date in the calendar. If the date is not in the current date interval being displayed, the view controller will automatically
    /// page to the date interval that contains the new date.
    /// - Parameter date: The new date to select.
    /// - Parameter animated: True to animate selection of the new date.
    open func selectDate(_ date: Date, animated: Bool) {
        guard let currentVC = currentViewController else { return }
        if currentVC.calendarView.dateInterval.contains(date) {
            currentVC.calendarView.selectDate(date)
            return
        }

        // Create the next view controller
        let nextVC = makeViewController(forDate: date)
        nextVC.calendarView.delegate = self
        let isLeft = currentVC.calendarView.dateInterval.start > date
        nextVC.calendarView.selectDate(date)
        setViewControllers([nextVC], direction: isLeft ? .reverse : .forward, animated: animated, completion: nil )
    }

    // MARK: UIPageViewController DataSource & Delegate

    open func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let typedViewController = viewController as? OCKWeekCalendarViewController else { fatalError("Unsupported type") }
        let dateInterval = typedViewController.calendarView.dateInterval
        let previousDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: dateInterval.start)!
        let previousPage = makeViewController(forDate: previousDate)
        previousPage.calendarView.delegate = self
        return previousPage
    }

    open func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let typedViewController = viewController as? OCKWeekCalendarViewController else { fatalError("Unsupported type") }
        let dateInterval = typedViewController.calendarView.dateInterval
        let nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: dateInterval.start)!
        let nextPage = makeViewController(forDate: nextDate)
        nextPage.calendarView.delegate = self
        return nextPage
    }

    open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                 previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard
            completed,
            let previousViewController = previousViewControllers.first,
            let currentViewController = currentViewController,
            let currentWeek = dateInterval
            else { return }
        guard let typedPreviousViewController = previousViewController as? OCKWeekCalendarViewController else { fatalError("Unsupported type") }

        let didMoveForwards = typedPreviousViewController.calendarView.dateInterval < currentViewController.calendarView.dateInterval
        let offset = didMoveForwards ? 1 : -1
        let previousSelectedDate = typedPreviousViewController.calendarView.selectedDate
        let newSelectedDate = Calendar.current.date(byAdding: .weekOfYear, value: offset,
                                                    to: typedPreviousViewController.calendarView.selectedDate)!
        currentViewController.calendarView.selectDate(newSelectedDate)
        calendarDelegate?.weekCalendarPageViewController(self, didChangeDateInterval: currentWeek)
        calendarDelegate?.weekCalendarPageViewController(self, didSelectDate: newSelectedDate, previousDate: previousSelectedDate)
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
            let dateInterval = dateInterval else { return }
        let comparison = Calendar.current.compare(dateInterval.start, to: startOfWeek, toGranularity: .weekOfYear)
        guard comparison == .orderedSame else { return }
        calendarDelegate?.weekCalendarPageViewController(self, didSelectDate: date, previousDate: previouslySelectedDate)
        previouslySelectedDate = date
    }
}

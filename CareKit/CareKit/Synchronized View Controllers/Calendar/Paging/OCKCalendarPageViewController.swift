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

/// Base class that can page an `OCKCalendarDisplayer` view controller. When paged, this view controller will update the days
/// displayed by the calendar automatically.
///
/// To provide a custom `OCKCalendarDisplayer` view controller, subclass and specialize the `ViewController` class generic and override the
/// `makeViewController(for:)` method to provide a view controller instance when it is neeeded by the page view controller.
open class OCKCalendarPageViewController<ViewController: OCKCalendarDisplayer & UIViewController, Store: OCKStoreProtocol>: UIPageViewController,
UIPageViewControllerDataSource, UIPageViewControllerDelegate, OCKCalendarViewControllerDelegate, OCKCalendarViewDelegate {
    // MARK: - Properties

    /// Handles events related to an `OCKCalendarPageViewController`.
    public weak var calendarDelegate: OCKCalendarPageViewControllerDelegate?

    /// The store manager used to provide synchronization.
    public let storeManager: OCKSynchronizedStoreManager<Store>

    /// Aggregator used to calculate adherence per day.
    public let aggregator: OCKAdherenceAggregator<Store.Event>

    /// The date interval currently being displayed.
    private var dateInterval: DateInterval? {
        return currentViewController?.calendarView.dateInterval
    }

    private var previouslySelectedDate = Date()

    /// The currently selected date in the calendar.
    public var selectedDate: Date {
        return currentViewController?.calendarView.selectedDate ?? Date()
    }

    var currentViewController: ViewController? {
        guard
            let viewControllers = viewControllers,
            !viewControllers.isEmpty
        else { return nil }

        guard let viewController = viewControllers.first! as? ViewController else { fatalError("Unsupported type") }
        return viewController
    }

    // MARK: - Life Cycle

    /// Create an instance that when paged, will update the days in the calendar automatically. Scrolling is horizontal by default.
    /// - Parameter storeManager: The store manager used to provide synchronization.
    /// - Parameter aggregator: Aggregator that can be used when creating an `OCKCalendarDisplayer` instance.
    init(storeManager: OCKSynchronizedStoreManager<Store>, aggregator: OCKAdherenceAggregator<Store.Event> = .countOutcomes) {
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
        let viewController = makeViewController(for: previouslySelectedDate)
        viewController.calendarView.selectDate(previouslySelectedDate)
        setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
    }

    // MARK: - Methods

    open func makeViewController(for date: Date) -> ViewController {
        fatalError("Need to override makeViewController(for:)")
    }

    /// Refresh the completion states for each day in the calendar.
    open func refreshAdherence() {
        currentViewController?.fetchAdherence()
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
        let nextVC = makeViewController(for: date)
        let isLeft = currentVC.calendarView.dateInterval.start > date
        nextVC.calendarView.selectDate(date)
        setViewControllers([nextVC], direction: isLeft ? .reverse : .forward, animated: animated, completion: nil )
    }

    // MARK: UIPageViewController DataSource & Delegate

    open func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let typedViewController = viewController as? ViewController else { fatalError("Unsupported type") }
        let dateInterval = typedViewController.calendarView.dateInterval
        let previousDate = Calendar.current.date(byAdding: type(of: typedViewController.calendarView).intervalComponent,
                                                 value: -1, to: dateInterval.start)!
        let previousPage = makeViewController(for: previousDate)
        return previousPage
    }

    open func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let typedViewController = viewController as? ViewController else { fatalError("Unsupported type") }
        let dateInterval = typedViewController.calendarView.dateInterval
        let nextDate = Calendar.current.date(byAdding: type(of: typedViewController.calendarView).intervalComponent,
                                             value: 1, to: dateInterval.start)!
        let nextPage = makeViewController(for: nextDate)
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
        guard let typedPreviousViewController = previousViewController as? ViewController else { fatalError("Unsupported type") }

        let didMoveForwards = typedPreviousViewController.calendarView.dateInterval < currentViewController.calendarView.dateInterval
        let offset = didMoveForwards ? 1 : -1
        let previousSelectedDate = typedPreviousViewController.calendarView.selectedDate
        let newSelectedDate = Calendar.current.date(byAdding: type(of: typedPreviousViewController.calendarView).intervalComponent,
                                                    value: offset, to: typedPreviousViewController.calendarView.selectedDate)!
        currentViewController.calendarView.selectDate(newSelectedDate)
        calendarDelegate?.calendarPageViewController(self, didChangeDateInterval: currentWeek)
        calendarDelegate?.calendarPageViewController(self, didSelectDate: newSelectedDate, previousDate: previousSelectedDate)
    }

    // MARK: OCKCalendarViewControllerDelegate

    /// Called when an unhandled error is encounted in a calendar view controller.
    /// - Parameter calendarViewController: The view controller in which the error occurred.
    /// - Parameter error: The error that occurred.
    open func calendarViewController<V: UIView, S: OCKStoreProtocol>(_ calendarViewController: OCKCalendarViewController<V, S>,
                                                                     didFailWithError error: Error) {
        calendarDelegate?.calendarPageViewController(self, didFailWithError: error)
    }

    // MARK: OCKCalendarViewDelegate

    /// Called when a particular date in the calendar was selected.
    /// - Parameter calendarView: The view displaying the calendar.
    /// - Parameter date: The date that was selected.
    /// - Parameter index: The index of the date that was selected with respect to the collection of days in the current `dateInterval`.
    /// - Parameter sender: The sender that initiated the selection.
    open func calendarView(_ calendarView: UIView & OCKCalendarDisplayable, didSelectDate date: Date, at index: Int, sender: Any?) {
        guard let startOfWeek = dateInterval?.start else { return }
        let comparison = Calendar.current.compare(calendarView.dateInterval.start, to: startOfWeek, toGranularity: .weekOfYear)
        guard comparison == .orderedSame else { return }
        calendarDelegate?.calendarPageViewController(self, didSelectDate: date, previousDate: previouslySelectedDate)
        previouslySelectedDate = date
    }
}

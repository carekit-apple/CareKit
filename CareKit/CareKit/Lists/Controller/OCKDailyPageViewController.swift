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

/// Conform to this protocol to receive callbacks when important events occur in an `OCKDailyPageViewController`.
public protocol OCKDailyPageViewControllerDelegate: AnyObject {
    /// This method will be called anytime an unhandled error is encountered.
    ///
    /// - Parameters:
    ///   - dailyPageViewController: The daily page view controller in which the error occurred.
    ///   - error: The error that occurred
    func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController, didFailWithError error: Error)
}

public extension OCKDailyPageViewControllerDelegate {
    /// This method will be called anytime an unhandled error is encountered.
    ///
    /// - Parameters:
    ///   - dailyPageViewController: The daily page view controller in which the error occurred.
    ///   - error: The error that occurred
    func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController, didFailWithError error: Error) {}
}

/// Any class that can provide content for an `OCKDailyPageViewController` should conform to this protocol.
public protocol OCKDailyPageViewControllerDataSource: AnyObject {
    /// - Parameters:
    ///   - dailyPageViewController: The daily page view controller for which content should be provided.
    ///   - listViewController: The list view controller that should be populated with content.
    ///   - date: A date that should be used to determine what content to insert into the list view controller.
    func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController,
                                 prepare listViewController: OCKListViewController, for date: Date)
}

/// Displays a calendar page view controller in the header, and a view controllers in the body. The view controllers must
/// be manually queried and set from outside of the class.
open class OCKDailyPageViewController: UIViewController,
OCKDailyPageViewControllerDataSource, OCKDailyPageViewControllerDelegate, OCKWeekCalendarPageViewControllerDelegate,
UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    // MARK: Properties

    public weak var dataSource: OCKDailyPageViewControllerDataSource?
    public weak var delegate: OCKDailyPageViewControllerDelegate?

    public var selectedDate: Date {
        return calendarWeekPageViewController.selectedDate
    }

    /// The store manager the view controller uses for synchronization
    public let storeManager: OCKSynchronizedStoreManager

    /// Page view managing ListViewControllers.
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

    /// The calendar view controller in the header.
    private let calendarWeekPageViewController: OCKWeekCalendarPageViewController

    // MARK: - Life cycle

    /// Create an instance of the view controller. Will hook up the calendar to the tasks collection,
    /// and query and display the tasks.
    ///
    /// - Parameter storeManager: The store from which to query the tasks.
    /// - Parameter adherenceAggregator: An aggregator that will be used to compute the adherence values shown at the top of the view.
    public init(storeManager: OCKSynchronizedStoreManager, adherenceAggregator: OCKAdherenceAggregator = .compareTargetValues) {
        self.storeManager = storeManager
        self.calendarWeekPageViewController = .init(storeManager: storeManager, aggregator: adherenceAggregator)
        super.init(nibName: nil, bundle: nil)
        self.calendarWeekPageViewController.dataSource = self
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        self.dataSource = self
        self.delegate = self
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Properties

    open func selectDate(_ date: Date, animated: Bool) {
        let previousDate = selectedDate
        guard !Calendar.current.isDate(previousDate, inSameDayAs: date) else { return }
        calendarWeekPageViewController.selectDate(date, animated: animated)
        weekCalendarPageViewController(calendarWeekPageViewController, didSelectDate: date, previousDate: previousDate)
    }
    
    override open func viewSafeAreaInsetsDidChange() {
        updateScrollViewInsets()
    }

    override open func loadView() {
        [calendarWeekPageViewController, pageViewController].forEach { addChild($0) }
        view = OCKHeaderBodyView(headerView: calendarWeekPageViewController.view, bodyView: pageViewController.view)
        [calendarWeekPageViewController, pageViewController].forEach { $0.didMove(toParent: self) }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        let now = Date()
        calendarWeekPageViewController.calendarDelegate = self
        calendarWeekPageViewController.selectDate(now, animated: false)
        pageViewController.setViewControllers([makePage(date: now)], direction: .forward, animated: false, completion: nil)
        pageViewController.accessibilityHint = loc("THREE_FINGER_SWIPE_DAY")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: loc("TODAY"), style: .plain, target: self, action: #selector(pressedToday(sender:)))
    }

    private func makePage(date: Date) -> OCKDatedListViewController {
        let listViewController = OCKDatedListViewController(date: date)
        let dateLabel = OCKDateLabel(textStyle: .title2, weight: .bold)
        dateLabel.setDate(date)
        dateLabel.accessibilityTraits = .header

        listViewController.insertView(dateLabel, at: 0, animated: false)

        setInsets(for: listViewController)
        dataSource?.dailyPageViewController(self, prepare: listViewController, for: date)
        return listViewController
    }

    @objc
    private func pressedToday(sender: UIBarButtonItem) {
        selectDate(Date(), animated: true)
    }

    private func updateScrollViewInsets() {
        pageViewController.viewControllers?.forEach({ child in
            guard let listVC = child as? OCKListViewController else { fatalError("Unexpected type") }
            setInsets(for: listVC)
        })
    }

    private func setInsets(for listViewController: OCKListViewController) {
        guard let listView = listViewController.view as? OCKListView else { fatalError("Unexpected type") }
        guard let headerView = view as? OCKHeaderBodyView else { fatalError("Unexpected type") }
        let insets = UIEdgeInsets(top: headerView.headerInset, left: 0, bottom: 0, right: 0)
        listView.scrollView.contentInset = insets
        listView.scrollView.scrollIndicatorInsets = insets
    }

    // MARK: - OCKCalendarPageViewControllerDelegate

    public func weekCalendarPageViewController(_ viewController: OCKWeekCalendarPageViewController, didSelectDate date: Date, previousDate: Date) {
        let newComponents = Calendar.current.dateComponents([.weekday, .weekOfYear, .year], from: date)
        let oldComponents = Calendar.current.dateComponents([.weekday, .weekOfYear, .year], from: previousDate)
        guard newComponents != oldComponents else { return } // do nothing if we have selected a date for the same day of the year
        let moveLeft = date < previousDate
        let listViewController = makePage(date: date)
        pageViewController.setViewControllers([listViewController], direction: moveLeft ? .reverse : .forward, animated: true, completion: nil)
    }

    public func weekCalendarPageViewController(_ viewController: OCKWeekCalendarPageViewController, didChangeDateInterval interval: DateInterval) {}

    public func weekCalendarPageViewController(_ viewController: OCKWeekCalendarPageViewController, didEncounterError error: Error) {
        delegate?.dailyPageViewController(self, didFailWithError: error)
    }

    // MARK: OCKDailyPageViewControllerDataSource & Delegate

    open func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController,
                                      prepare listViewController: OCKListViewController, for date: Date) {}

    open func dailyPageViewController(_ dailyPageViewController: OCKDailyPageViewController, didFailWithError error: Error) {}

    // MARK: - UIPageViewControllerDelegate

    open func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? OCKDatedListViewController else { fatalError("Unexpected type") }
        let targetDate = Calendar.current.date(byAdding: .day, value: -1, to: currentViewController.date)!
        return makePage(date: targetDate)
    }

    open func pageViewController(_ pageViewController: UIPageViewController,
                                 viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentViewController = viewController as? OCKDatedListViewController else { fatalError("Unexpected type") }
        let targetDate = Calendar.current.date(byAdding: .day, value: 1, to: currentViewController.date)!
        return makePage(date: targetDate)
    }

    // MARK: - UIPageViewControllerDataSource

    open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                                 previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        guard let listViewController = pageViewController.viewControllers?.first as? OCKDatedListViewController else { fatalError("Unexpected type") }
        calendarWeekPageViewController.selectDate(listViewController.date, animated: true)
    }
}

// This is private subclass of the list view controller that imbues it with a date that can be uesd by the page view controller to determine
// which direction was just swiped.
private class OCKDatedListViewController: OCKListViewController {
    let date: Date

    init(date: Date) {
        self.date = date
        super.init(nibName: nil, bundle: nil)
        listView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class OCKDateLabel: OCKLabel {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    func setDate(_ date: Date) {
        text = OCKDateLabel.dateFormatter.string(from: date)
    }

    override init(textStyle: UIFont.TextStyle, weight: UIFont.Weight) {
        super.init(textStyle: textStyle, weight: weight)
        styleDidChange()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func styleDidChange() {
        super.styleDidChange()
        textColor = style().color.label
    }
}

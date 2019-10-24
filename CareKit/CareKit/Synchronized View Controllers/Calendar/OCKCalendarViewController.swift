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
import Combine
import UIKit

/// A superclass to all view controllers that are synchronized with a list of completion states. Actions in the view sent through the
/// `OCKCalendarViewDelegate` protocol will automatically be hooked up to controller logic.
///
/// Alternatively, subclass and use your custom view by specializing the `View` generic and overriding the `makeView()` method. Override the
/// `updateView(view:context)` method to hook up the completion states to the view. This method will be called any time an outcome is added,
/// modified, or deleted.
open class OCKCalendarViewController<View: UIView & OCKCalendarDisplayable, Store: OCKStoreProtocol>:
OCKSynchronizedViewController<View, [OCKCompletionRingButton.CompletionState]>, OCKCalendarDisplayer, OCKCalendarViewDelegate {
    // MARK: Properties

    /// The calendar view displayed by the view controller.
    public var calendarView: UIView & OCKCalendarDisplayable { return synchronizedView }

    /// The delegate will receive callbacks when important events happen.
    public weak var delegate: OCKCalendarViewControllerDelegate?

    /// The store manager used to provide synchronization.
    public let storeManager: OCKSynchronizedStoreManager<Store>

    let aggregator: OCKAdherenceAggregator<Store.Event>
    let date: Date

    // MARK: - Initializers

    /// Create a view controller that queries for and displays completion states.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter date: Any date in the date interval to display.
    /// - Parameter aggregator: Used to aggregate events to compute completion.
    init(storeManager: OCKSynchronizedStoreManager<Store>, date: Date, aggregator: OCKAdherenceAggregator<Store.Event>) {
        self.storeManager = storeManager
        self.aggregator = aggregator
        self.date = date
        super.init()
    }

    // MARK: - Life cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        synchronizedView.showDate(date)
        calendarView.delegate = self
        fetchAdherence()
        subscribe()
    }

    // MARK: Methods

    /// Re-fetch adherence whenever an outcome notification occurs.
    override open func makeSubscription() -> AnyCancellable? {
        let subscription = storeManager.notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification<Store> }
            .sink(receiveValue: { [weak self] _ in
                self?.fetchAdherence()
            }
        )
        return AnyCancellable(subscription)
    }

    private func makeAdherenceQuery() -> OCKAdherenceQuery<Store.Event> {
        let component = type(of: synchronizedView).intervalComponent
        var dateInterval = Calendar.current.dateInterval(of: component, for: date)!
        dateInterval.duration -= 1  // The default interval contains 1 second of the next day after the interval. Subtract that off
        var adherenceQuery = OCKAdherenceQuery<Store.Event>(dateInterval: dateInterval)
        adherenceQuery.aggregator = aggregator
        return adherenceQuery
    }

    private func convertAdherenceToCompletionRingState(adherence: [OCKAdherence],
                                                       query: OCKAdherenceQuery<Store.Event>) -> [OCKCompletionRingButton.CompletionState] {
        return zip(query.dates(), adherence).map { date, adherence in
            let isInFuture = date > Date() && !Calendar.current.isDateInToday(date)
            switch adherence {
            case .noTasks: return .dimmed
            case .noEvents: return .empty
            case .progress(let value):
                if value > 0 { return .progress(CGFloat(value)) }
                return isInFuture ? .empty : .zero
            }
        }
    }

    /// Fetch the adherence state for the days in the calendar.
    open func fetchAdherence() {
        let query = makeAdherenceQuery()
        storeManager.store.fetchAdherence(query: query) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.calendarViewController(self, didFailWithError: error)
            case .success(let adherence):
                let states = self.convertAdherenceToCompletionRingState(adherence: adherence, query: query)
                self.setViewModel(states, animated: self.viewModel != nil)
            }
        }
    }

    // MARK: - OCKCalendarViewController

    /// Called when a particular date in the calendar was selected. The default implementation does nothing.
    /// - Parameter calendarView: The view displaying the calendar.
    /// - Parameter date: The date that was selected.
    /// - Parameter index: The index of the date that was selected with respect to the collection of days in the current `dateInterval`.
    /// - Parameter sender: The sender that initiated the selection.
    open func calendarView(_ calendarView: UIView & OCKCalendarDisplayable, didSelectDate date: Date, at index: Int, sender: Any?) { }
}

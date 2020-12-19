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
import Foundation
import UIKit

/// A basic controller capable of updating a calendar.
open class OCKCalendarController: OCKCalendarControllerProtocol, ObservableObject {

    // MARK: OCKCalendarControllerProtocol

    public var store: OCKAnyEventStore { storeManager.store }
    public let objectWillChange: CurrentValueSubject<[OCKCompletionRingButton.CompletionState], Never>

    // MARK: - Properties

    /// The store manager against which the calendar will be synchronized.
    public let storeManager: OCKSynchronizedStoreManager

    /// The date interval displayed by the calendar.
    public let dateInterval: DateInterval

    private var subscription: AnyCancellable?

    // MARK: - Life Cycle

    /// Initialize the controller.
    /// - Parameter dateInterval: The date interval for the adherence range.
    /// - Parameter storeManager: Wraps the store that contains the adherence data.
    public required init(dateInterval: DateInterval, storeManager: OCKSynchronizedStoreManager) {
        self.dateInterval = dateInterval
        self.storeManager = storeManager
        self.objectWillChange = .init([])
    }

    // MARK: - Methods

    /// Begin observing adherence in the calendar's date interval.
    ///
    /// - Parameters:
    ///   - aggregator: An aggregator that will be used to compute adherence.
    open func fetchAndObserveAdherence(usingAggregator aggregator: OCKAdherenceAggregator, errorHandler: ((OCKStoreError) -> Void)? = nil) {

        // Set the view model when outcomes change
        subscription = storeManager.notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification }
            .sink(receiveValue: { [weak self] _ in self?.fetchAdherence(usingAggregator: aggregator, completion: { result in
                if case let .failure(error) = result {
                    errorHandler?(error)
                }
            }) })

        // Fetch adherence and set the view model
        fetchAdherence(usingAggregator: aggregator) { result in
            if case let .failure(error) = result {
                errorHandler?(error)
            }
        }
    }

    private func makeAdherenceQuery(withAggregator aggregator: OCKAdherenceAggregator) -> OCKAdherenceQuery {
        var adherenceQuery = OCKAdherenceQuery(taskIDs: [], dateInterval: dateInterval)
        adherenceQuery.aggregator = aggregator
        return adherenceQuery
    }

    private func convertAdherenceToCompletionRingState(adherence: [OCKAdherence],
                                                       query: OCKAdherenceQuery) -> [OCKCompletionRingButton.CompletionState] {
        return zip(query.dateInterval.dates(), adherence).map { date, adherence in
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

    /// Fetch the adherence state for the days in the calendar and set the view model.
    private func fetchAdherence(usingAggregator aggregator: OCKAdherenceAggregator,
                                completion: OCKResultClosure<[OCKCompletionRingButton.CompletionState]>?) {
        let query = makeAdherenceQuery(withAggregator: aggregator)
        storeManager.store.fetchAdherence(query: query) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error): completion?(.failure(error))
            case .success(let adherence):
                let states = self.convertAdherenceToCompletionRingState(adherence: adherence, query: query)
                self.objectWillChange.value = states
                completion?(.success(states))
            }
        }
    }
}

private extension DateInterval {
    func dates() -> [Date] {
        var dates = [Date]()
        var currentDate = start
        while currentDate < end {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
}

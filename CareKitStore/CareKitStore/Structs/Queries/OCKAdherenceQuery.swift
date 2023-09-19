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

import Foundation

/// `OCKAdherenceQuery` is used to constrain the results returned when fetching adherence from a store.
public struct OCKAdherenceQuery {

    /// The IDs of the tasks for which adherence should be calculated.
    public var taskIDs: [String]

    /// The date interval for which to return adherence information.
    public var dateInterval: DateInterval

    /// Computes the combined progress for a series of CareKit events.
    @available(*, unavailable, message: "The aggregator is no longer available and will be removed in a future version of CareKit.")
    public var aggregator: OCKAdherenceAggregator! {
        fatalError("Property is unavailable")
    }

    let computeProgress: (OCKAnyEvent) -> CareTaskProgress

    /// Initialize a new query by specifying the taskIDs, dates, and aggregator.
    /// - Parameters:
    ///   - taskIDs: The identifiers of the tasks for which adherence should be computed.
    ///   - dateInterval: The date interval for which to return adherence information.
    ///   - aggregator: Produce a single progress value from an event.
    @available(*, deprecated, renamed: "init(taskIDs:dateInterval:computeProgress:)")
    public init(
        taskIDs: [String],
        dateInterval: DateInterval,
        aggregator: OCKAdherenceAggregator
    ) {
        self.taskIDs = taskIDs
        self.dateInterval = dateInterval

        computeProgress = { event in
            event.computeProgress(by: .checkingOutcomeExists)
        }
    }

    /// Initialize a new query by specifying the taskIDs, dates, and aggregator.
    /// - Parameters:
    ///   - taskIDs: The identifiers of the tasks for which adherence should be computed.
    ///   - dateInterval: The date interval for which to return adherence information.
    ///   - computeProgress: Used to compute progress for an event.
    public init(
        taskIDs: [String],
        dateInterval: DateInterval,
        computeProgress: @escaping (OCKAnyEvent) -> CareTaskProgress = { event in
            event.computeProgress(by: .checkingOutcomeExists)
        }
    ) {
        self.taskIDs = taskIDs
        self.dateInterval = dateInterval
        self.computeProgress = computeProgress
    }

    func dates() -> [Date] {
        var dates = [Date]()
        var currentDate = dateInterval.start
        while currentDate < dateInterval.end {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
}

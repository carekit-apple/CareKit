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
public struct OCKAdherenceQuery<Event: OCKEventConvertible & Equatable>: OCKDateIntervalQueryable {
    /// The earliest date from which to return adherence information.
    public var start: Date

    /// The latest date from which to return adherence information.
    public var end: Date

    /// An aggregator used to derive an adherence value from a series of events.
    public var aggregator: OCKAdherenceAggregator<Event>

    /// Initialize a new query by specifying the start and end dates.
    ///
    /// - Parameters:
    ///   - start: The date from which the query should begin.
    ///   - end: The date on which the query should end.
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
        self.aggregator = .countOutcomes
    }

    /// Initialize a new query by specifying the start and end dates.
    ///
    /// - Parameters:
    ///   - start: The date from which the query should begin.
    ///   - end: The date on which the query should end.
    ///   - aggregator: An aggregator used to derive an adherence value from a series of events.
    public init(start: Date, end: Date, aggregator: OCKAdherenceAggregator<Event>) {
        self.start = start
        self.end = end
        self.aggregator = aggregator
    }
}

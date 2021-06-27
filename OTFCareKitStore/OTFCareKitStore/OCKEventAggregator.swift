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

/// An enumerator that specifies a number of methods for computing a value given an array of events that occurred on some day.
public enum OCKEventAggregator {
    /// Counts the total number of outcome values in the entire array of events.
    case countOutcomeValues

    /// Count the total number of outcomes in the entire array of events.
    case countOutcomes

    /// Custom logic that operates a day's worth of events and returns a y-axis value.
    case custom(_ closure: ([OCKAnyEvent]) -> Double)

    /// Aggregates an array of events into an adherence score.
    ///
    /// - Parameters:
    ///   - events: An array of events
    public func aggregate(events: [OCKAnyEvent]) -> Double {
        switch self {
        case .countOutcomeValues:
            return Double(events.map { $0.outcome?.values.count ?? 0 }.reduce(0, +))
        case .countOutcomes:
            return Double(events.map { $0.outcome != nil ? 1 : 0 }.reduce(0, +))
        case .custom(let closure):
            return closure(events)
        }
    }
}

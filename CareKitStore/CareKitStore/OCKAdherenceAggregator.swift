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

/// An enumerator that specifies a number of methods for computing an adherence value given an array of events.
public enum OCKAdherenceAggregator<Event: OCKEventConvertible & Equatable> {
    /// Computes a percentage by checking if the outcome for each event exists.
    case countOutcomes

    /// Computes a percentage by dividing the number of outcomes values by the number of expected outcomes values for each event.
    case countOutcomeValues

    /// Specifies a custom closure that operates on a day's worth of events and returns an adherence value
    case custom(_ closure: ([Event]) -> OCKAdherence)

    /// Aggregates an array of events into an adherence score.
    /// 
    /// - Parameters:
    ///   - events: An array of events
    public func aggregate(events: [Event]) -> OCKAdherence {
        switch self {
        case .countOutcomes:
            return self.computeAverageCompletion(for: events, computation: computeOutcomeCompletion)
        case .countOutcomeValues:
            return self.computeAverageCompletion(for: events, computation: computeValuesCompletion)
        case .custom(let closure):
            return closure(events)
        }
    }

    private func computeAverageCompletion(for events: [Event],
                                          computation: (_ event: OCKEvent<OCKTask, OCKOutcome>) -> Double) -> OCKAdherence {
        guard !events.isEmpty else {
            return .noEvents
        }
        let events = events.map { $0.convert() }
        let percentsComplete = events.map(computation)
        let average = percentsComplete.reduce(0, +) / Double(events.count)
        return .progress(average)
    }

    private func computeValuesCompletion(for event: OCKEvent<OCKTask, OCKOutcome>) -> Double {
        let expectedValues = event.scheduleEvent.element.targetValues
        let valuesRequiredForComplete = !expectedValues.isEmpty ? expectedValues.count : 1
        let valueCount = event.outcome?.values.count ?? 0
        let fractionComplete = min(1.0, Double(valueCount) / Double(valuesRequiredForComplete))
        return fractionComplete
    }

    private func computeOutcomeCompletion(for event: OCKEvent<OCKTask, OCKOutcome>) -> Double {
        return event.outcome != nil ? 1 : 0
    }
}

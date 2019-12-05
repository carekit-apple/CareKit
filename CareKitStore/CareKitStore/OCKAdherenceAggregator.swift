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
public enum OCKAdherenceAggregator {

    /// Computes a percentage by checking if the outcome for each event exists. Any event with a non-nil outcome will be counted
    /// as 100% complete, and any event without an outcome will be counted as 0% complete. The average completion across all events
    /// will be returned.
    case outcomeExists

    /// Computes a percentage for each event by dividing the number of outcomes values by the number of expected outcomes values.
    /// The average completion across all events will be returned.
    case percentOfOutcomeValuesThatExist

    /// Computes a percentage for each event that is either 1.0 or 0.0 depending on if the outcomes values match or exceed the target values.
    /// If no target values are specified on the event, then the existence of an outcome will result in a value of 1.0.
    /// The average completion across all events will be returned.
    case compareTargetValues

    /// Computes an analog percentage for each event as the number of met target values divided by the total number of target goals.
    /// The average completion accross all events will be returned.
    case percentOfTargetValuesMet

    /// Specifies a custom closure that operates on a day's worth of events and returns an adherence value
    case custom(_ closure: ([OCKAnyEvent]) -> OCKAdherence)

    /// Aggregates an array of events into an adherence score.
    /// 
    /// - Parameters:
    ///   - events: An array of events
    public func aggregate(events: [OCKAnyEvent]) -> OCKAdherence {
        switch self {
        case .outcomeExists: return computeAverageCompletion(for: events, usingMetric: computeOutcomeExistsCompletion)
        case .percentOfOutcomeValuesThatExist:  return computeAverageCompletion(for: events, usingMetric: computePercentOfExpectedValuesThatExist)
        case .compareTargetValues: return computeAverageCompletion(for: events, usingMetric: computeTargetValueBinaryCompletion)
        case .percentOfTargetValuesMet: return computeAverageCompletion(for: events, usingMetric: computePercentOfTargetsMet)
        case .custom(let closure): return closure(events)
        }
    }

    // Applies a metric to an array of events and averages the results
    private func computeAverageCompletion(for events: [OCKAnyEvent],
                                          usingMetric computeMetric: (_ event: OCKAnyEvent) -> Double) -> OCKAdherence {
        guard !events.isEmpty else { return .noEvents }
        let percentsComplete = events.map(computeMetric)
        let average = percentsComplete.reduce(0, +) / Double(events.count)
        return .progress(average)
    }

    // Returns 1 or 0 based on whether or not an outcome exists
    private func computeOutcomeExistsCompletion(for event: OCKAnyEvent) -> Double {
        event.outcome != nil ? 1 : 0
    }

    // Returns (number of outcome values present) / (number of target values)
    private func computePercentOfExpectedValuesThatExist(for event: OCKAnyEvent) -> Double {
        let expectedValues = event.scheduleEvent.element.targetValues
        let valuesRequiredForComplete = !expectedValues.isEmpty ? expectedValues.count : 1
        let valueCount = event.outcome?.values.count ?? 0
        let fractionComplete = min(1.0, Double(valueCount) / Double(valuesRequiredForComplete))
        return fractionComplete
    }

    // Returns either 0 or 1 based on whether or not all target values have been met.
    // If there are no target values, always returns 1.
    private func computeTargetValueBinaryCompletion(for event: OCKAnyEvent) -> Double {
        guard let outcome = event.outcome else { return 0 }
        let targetValues = event.scheduleEvent.element.targetValues
        guard targetValues.count <= outcome.values.count else { return 0 }
        let indiciesToCheck = Array(0..<targetValues.count)
        for index in indiciesToCheck {
            if !outcomeFulfillsTarget(outcomeValue: outcome.values[index], target: targetValues[index]) { return 0 }
        }
        return 1
    }

    // Returns an analog value between 0 and 1 that is (number of met goals) / (number of goals)
    private func computePercentOfTargetsMet(for event: OCKAnyEvent) -> Double {
        guard let outcome = event.outcome else { return 0 }
        let targetValues = event.scheduleEvent.element.targetValues
        guard !targetValues.isEmpty else { return outcome.values.isEmpty ? 0 : 1 }
        let actualValues = outcome.values
        let indicesToCheck = Array(0..<min(targetValues.count, actualValues.count))
        var completionStatuses = [Bool](repeating: false, count: indicesToCheck.count)
        for index in indicesToCheck {
            completionStatuses[index] = outcomeFulfillsTarget(outcomeValue: actualValues[index], target: targetValues[index])
        }
        let numberComplete = completionStatuses.filter { $0 }.count
        let totalTargets = targetValues.count
        return Double(numberComplete) / Double(totalTargets)
    }

    private func outcomeFulfillsTarget(outcomeValue value: OCKOutcomeValue, target: OCKOutcomeValue) -> Bool {
        assert(value.type == target.type, "Actual outcome value and target value should not have different types!")
        guard value.type == target.type else { return false }

        switch value.type {
        case .binary: return checkEquality(lhs: value, rhs: target, keyPath: \.dateValue)
        case .boolean: return checkEquality(lhs: value, rhs: target, keyPath: \.booleanValue)
        case .text: return checkEquality(lhs: value, rhs: target, keyPath: \.stringValue)
        case .double: return compare(lhs: value, greaterThanOrEqualTo: target, keyPath: \.doubleValue)
        case .date: return compare(lhs: value, greaterThanOrEqualTo: target, keyPath: \.dateValue)
        case .integer: return compare(lhs: value, greaterThanOrEqualTo: target, keyPath: \.integerValue)
        }
    }

    private func checkEquality<T: Equatable>(lhs: OCKOutcomeValue,
                                             rhs: OCKOutcomeValue,
                                             keyPath: KeyPath<OCKOutcomeValue, T?>) -> Bool {
        guard let lhsValue = lhs[keyPath: keyPath], let rhsValue = rhs[keyPath: keyPath] else { return false }
        return lhsValue == rhsValue
    }

    private func compare<T: Comparable>(lhs: OCKOutcomeValue,
                                        greaterThanOrEqualTo rhs: OCKOutcomeValue,
                                        keyPath: KeyPath<OCKOutcomeValue, T?>) -> Bool {
        guard let lhsValue = lhs[keyPath: keyPath], let rhsValue = rhs[keyPath: keyPath] else { return false }
        return lhsValue >= rhsValue
    }
}

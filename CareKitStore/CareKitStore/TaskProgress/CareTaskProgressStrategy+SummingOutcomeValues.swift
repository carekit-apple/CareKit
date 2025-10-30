/*
 Copyright (c) 2022, Apple Inc. All rights reserved.
 
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

extension CareTaskProgressStrategy {

    static func computeProgressBySummingOutcomeValues(for event: OCKAnyEvent) -> LinearCareTaskProgress {

        let outcomeValues = event.outcome?.values ?? []

        let summedOutcomesValue = outcomeValues
            .map { Self.accumulableDoubleValue(for: $0) }
            .reduce(0, +)

        let targetValues = event.scheduleEvent.element.targetValues

        let summedTargetValue = targetValues
            .map { Self.accumulableDoubleValue(for: $0) }
            .reduce(nil) { partialResult, nextTarget -> Double? in
                return sum(partialResult, nextTarget)
            }

        let progress = LinearCareTaskProgress(
            value: summedOutcomesValue,
            goal: summedTargetValue
        )

        return progress
    }

    /// Convert an outcome value to a double that can be accumulated. If the underlying type is not a numeric,
    /// a default value of `1` will be used to indicate the existence of some outcome value.
    private static func accumulableDoubleValue(for outcomeValue: OCKOutcomeValue) -> Double {

        switch outcomeValue.type {

        // These types can be converted to a double value
        case .double, .integer:
            return outcomeValue.numberValue!.doubleValue

        // These types cannot be converted to a double value
        case .binary, .text, .date, .boolean:
            return 1
        }
    }

    private static func sum<T: AdditiveArithmetic>(
        _ lhs: T?,
        _ rhs: T?
    ) -> T? {

        // Note: The computation here assumes `nil` is a passthrough
        // value and acts the same as "0" in addition

        // If at least one side of the equation is nil
        if lhs == nil { return rhs }
        if rhs == nil { return lhs }

        // If both sides of the equation are non-nil
        let sum = lhs! + rhs!
        return sum
    }
}

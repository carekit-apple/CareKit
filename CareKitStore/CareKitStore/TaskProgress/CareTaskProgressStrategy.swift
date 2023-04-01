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

/// A structure that provides access to various strategies for computing progress for a task.
///
/// This structure is most commonly used when you already have access to an event and want to
/// specify a strategy for computing progress:
///
/// ```swift
/// let steps: OCKAnyEvent = getStepsEvent()
/// let stepsProgress = steps.computeProgress(by: .summingOutcomeValues)
/// ```
///
/// To create your own progress computation strategy, start by defining a data structure that stores task
/// progress. The data structure should conform to ``CareTaskProgress``.
///
/// ```swift
/// struct PhysicalTherapyProgress: CareTaskProgress {
///
///     // Custom properties here...
///
///     // Required by `CareTaskProgress`
///     var fractionCompleted: Double
/// }
/// ```
///
/// Next, extend ``CareTaskProgressStrategy`` and write out logic for computing the custom progress
/// for a task.
///
/// ```swift
/// extension CareTaskProgressStrategy {
///
///     public static var customStrategy: CareTaskProgressStrategy<PhysicalTherapyProgress> {
///
///         return CareTaskProgressStrategy<PhysicalTherapyProgress> { event in
///             return computeCustomProgress(for: event)
///         }
///
///     }
/// }
/// ```
///
/// Now you can acess the strategy just like the other strategies in the framework.
///
/// ```swift
///
/// // Custom strategy.
/// let physicalTherapy: OCKAnyEvent = getPhysicalTherapyEvent()
/// let physicalTherapyProgress = physicalTherapy.computeProgress(by: .customStrategy)
///
/// // Default strategy.
/// let steps: OCKAnyEvent = getStepsEvent()
/// let stepsProgress = steps.computeProgress(by: .summingOutcomeValues)
///
/// // You can aggregate both default and custom progress data structures.
/// let progress = AggregatedCareTaskProgress(combining: [stepsProgress, physicalTherapyProgress]
/// ```
public struct CareTaskProgressStrategy<Progress: CareTaskProgress> {

    /// A strategy that computes progress for a task by checking for the existence of an outcome.
    ///
    /// The task is considered completed if an ``OCKAnyEvent/outcome`` exists.
    public static var checkingOutcomeExists: CareTaskProgressStrategy<BinaryCareTaskProgress> {

        return CareTaskProgressStrategy<BinaryCareTaskProgress> { event in
            return computeProgressByCheckingOutcomeExists(for: event)
        }
    }

    /// A strategy that computes progress for a task.
    ///
    /// The strategy sums the ``OCKScheduleElement/targetValues`` for the event and compares
    /// the two results. The task is considered completed if the summed value reaches the summed target.
    ///
    /// > Note:
    /// If any of the outcome ``OCKAnyOutcome/values`` or ``OCKScheduleElement/targetValues``
    /// aren't numeric and can't be summed properly, they're assigned a value of one during the summation
    /// process.
    public static var summingOutcomeValues: CareTaskProgressStrategy<LinearCareTaskProgress> {

        return CareTaskProgressStrategy<LinearCareTaskProgress> { event in
            return computeProgressBySummingOutcomeValues(for: event)
        }
    }

    let computeProgress: (OCKAnyEvent) -> Progress

    /// Create a custom task progress computation strategy.
    ///
    /// - Parameters
    ///     - computeProgress: A closure that computes task progress for an event.
    public init(computeProgress: @escaping (OCKAnyEvent) -> Progress) {
        self.computeProgress = computeProgress
    }
}

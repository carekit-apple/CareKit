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

/// An object that combines the progress for multiple tasks.
///
/// This type can be useful for displaying progress for multiple tasks using a progress bar. If you have multiple events,
/// start by computing the progress for each event individually:
///
/// ```swift
/// let medication: OCKAnyEvent = getMedicationEvent()
/// let medicationProgress = medication.computeProgress(by: .checkingOutcomeExists)
///
/// let steps: OCKAnyEvent = getStepsEvent()
/// let stepsProgress = steps.computeProgress(by: .summingOutcomeValues)
///
/// let progress = AggregatedCareTaskProgress(combining: [medicationProgress, stepsProgress]
/// ```
///
/// Progress units are weighted equally when combining progress for multiple events. In the example above,
/// suppose each of the two events is 50% completed. The final combined progress becomes 50%. Now suppose one
/// event is 100% completed and the other is 50% completed. The final progress becomes 75%.
///
/// Use this type to create parent progress for a group of subtasks:
///
/// ```swift
/// let medicationDoseA: OCKAnyEvent = getDoseAEvent()
/// let medicationDoseB: OCKAnyEvent = getDoseBEvent()
/// let medicationProgress = AggregatedCareTaskProgress(events: [medicationDoseA, medicationDoseB])
///
/// let steps: OCKAnyEvent = getStepsEvent()
/// let stepsProgress = steps.computeProgress(by: .summingOutcomeValues)
///
/// let progress = AggregatedCareTaskProgress(combining: [medicationProgress, stepsProgress]
/// ```
///
/// Once progress is constructed, it can easily be applied to a
/// [ProgressView](https://developer.apple.com/documentation/swiftui/progressview)
/// in SwiftUI:
///
/// ```swift
/// var body: some View {
///     ProgressView(value: progress.fractionCompleted)
/// }
/// ```
public struct AggregatedCareTaskProgress: CareTaskProgress, Hashable, Sendable {

    /// Create user progress by combining the progress for multiple tasks.
    ///
    /// - Parameter progress: The progress units to combine. Each progress unit is equally weighted.
    public init(combining progress: [CareTaskProgress]) {

        guard progress.isEmpty == false else {
            fractionCompleted = 1
            return
        }

        let modifier = 1 / Double(progress.count)

        let fractionCompleted = progress.reduce(0) { partialResult, nextProgressUnit -> Double in
            let nextPercentCompleted = nextProgressUnit.clampedFractionCompleted * modifier
            return partialResult + nextPercentCompleted
        }

        self.fractionCompleted = fractionCompleted
    }

    /// Create user progress  by computing and combining the progress for multiple tasks using a single strategy.
    ///
    /// - Parameters:
    ///   - events: The events used to compute progress.
    ///   - strategy: The strategy used to compute progress for each event.
    public init<Progress>(
        events: [OCKAnyEvent],
        by strategy: CareTaskProgressStrategy<Progress> = .checkingOutcomeExists
    ) {
        let progressForEvents = events.map { event in
            event.computeProgress(by: strategy)
        }

        self.init(combining: progressForEvents)
    }

    // MARK: - CareTaskProgress

    public let fractionCompleted: Double
}

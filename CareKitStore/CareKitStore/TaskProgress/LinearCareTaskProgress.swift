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

/// A structure that defines user progress for a task that can be completed over time.
///
/// A progress value updates as a user progresses through the task. When the progress value
/// reaches its goal, the task is considered completed. If there's no goal, the task is considered completed if
/// the progress value is greater than zero.
///
/// This type of progress is useful for tasks such as "Walk 500 steps" or "Exercise for 30 minutes."
///
/// You can easily apply this progress to a user interface element such as a chart or a progress view.
///
/// ```swift
/// var body: some View {
///     ProgressView(value: progress.fractionCompleted)
/// }
/// ```
public struct LinearCareTaskProgress: CareTaskProgress, Hashable, Sendable {

    /// The progress that's been made towards reaching the goal.
    ///
    /// - Precondition: `value` >= 0
    public var value: Double {
        didSet { Self.validate(progressValue: value) }
    }

    /// A value that indicates whether the task is complete.
    ///
    /// When there is no goal, the value is `nil`.  The task is considered
    /// completed if the progress value is greater than zero.
    ///
    /// - Precondition: `value` >= 0
    public var goal: Double? {
        didSet { Self.validate(goal: goal) }
    }

    /// Create user progress by specifying the current value and goal of the progress. 
    /// 
    /// - Parameters: 
    ///   - value: The current value of a users progress for the task. 
    ///   - goal: The goal user progress value to consider the task complete. If there's no goal, the task is considered completed if
    /// the progress value is greater than zero.
    public init(
        value: Double,
        goal: Double? = nil
    ) {
        Self.validate(progressValue: value)
        Self.validate(goal: goal)

        self.value = value
        self.goal = goal
    }

    private static func validate(progressValue: Double) {
        precondition(progressValue >= 0)
    }

    private static func validate(goal: Double?) {
        guard let goal else { return }
        precondition(goal >= 0)
    }

    // MARK: - CareTaskProgress

    public var fractionCompleted: Double {

        // If there is no goal, a non-zero progress value indicates that progress
        // is 100% completed
        guard let goal else {

            let isCompleted = value > 0
            let fractionCompleted: Double = isCompleted ? 1 : 0
            return fractionCompleted
        }

        guard goal > 0 else {

            // The progress value is always guaranteed to be greater than or equal to
            // zero, so it's guaranteed to have reached the target value
            return 1
        }

        let fractionCompleted = value / goal
        let clampedFractionCompleted = min(fractionCompleted, 1)
        return clampedFractionCompleted
    }
}

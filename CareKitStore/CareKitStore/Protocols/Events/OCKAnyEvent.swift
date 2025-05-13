/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
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

/// A representation of a single occassion which a task was scheduled to occur on.
///
/// The event contains a copy of the task itself, as well as the
/// schedule event and an outcome that is non-`nil` if progress occurred on the task.
public struct OCKAnyEvent {

    /// The stable identifier that can be used for the `Identifiable` protocol.
    public let id: String

    /// The task that this event is associated with.
    public let task: OCKAnyTask

    /// The outcome for this event.
    ///
    /// If the outcome is empty, no actions were recorded.
    ///
    /// - Note: The outcome may be non-`nil` even if the task didn't complete. Checking the presence of an outcome isn't sufficient
    /// to determine whether or not the task completed. Here are some examples of times when the outcome is non-`nil` but the task didn't complete:
    ///    - The user created a note specifying why they weren't able to complete the task.
    ///    - The user completed the task, but then deleted all the values they recorded.
    ///    - The user only partially completed the task.
    public let outcome: OCKAnyOutcome?

    /// The schedule event for this task occurrence.
    ///
    /// The event contains information about the start, duration, occurrence number, and schedule element that
    /// resulted in this event.
    public let scheduleEvent: OCKScheduleEvent

    /// Creates an event with a task, schedule event, and optional outcome.
    ///
    /// - Parameters
    ///     - task: The task associated with this event.
    ///     - outcome: The outcome associated with this event, or `nil` if the outcome doesn't exists yet.
    ///     - scheduleEvent: The schedule event that resulted in this event.
    public init(task: OCKAnyTask, outcome: OCKAnyOutcome?, scheduleEvent: OCKScheduleEvent) {
        self.task = task
        self.outcome = outcome
        self.scheduleEvent = scheduleEvent

        var hasher = Hasher()
        hasher.combine(task.uuid)
        hasher.combine(scheduleEvent.occurrence)
        id = "\(hasher.finalize())"
    }

    /// Compute the progress for an event.
    ///
    /// The function computes progress according to the `strategy`. See ``CareTaskProgressStrategy`` for a list of
    /// the available strategies.
    ///
    /// Compute progress across multiple events using ``AggregatedCareTaskProgress``.
    ///
    /// - Parameter strategy: The strategy that the function uses to compute progress for the event.
    public func computeProgress<Progress>(
        by strategy: CareTaskProgressStrategy<Progress> = .checkingOutcomeExists
    ) -> Progress {

        let progress = strategy.computeProgress(self)
        return progress
    }
}

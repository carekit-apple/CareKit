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

/// An event that represents a single occasion that a task was scheduled to occur.
///
/// The event contains a copy of the task itself, the
/// schedule event, and an outcome that's non-`nil` if progress is made on the task.
public struct OCKEvent<Task: OCKAnyTask & Equatable, Outcome: OCKAnyOutcome & Equatable>: Identifiable, Comparable {

    /// The stable identifier to use.
    public let id: String

    /// A fully typed version of the task associated with this event.
    public let task: Task

    /// A fully typed version of the outcome associated with this event.
    public var outcome: Outcome?

    /// A value containing scheduling information for this event.
    public let scheduleEvent: OCKScheduleEvent

    /// Initialize an event with a task, optional outcome, and schedule event.
    ///
    /// - Parameters:
    ///   - task: The task associated with this event.
    ///   - outcome: The outcome associated with this event.
    ///   - scheduleEvent: The schedule event.
    public init(task: Task, outcome: Outcome?, scheduleEvent: OCKScheduleEvent) {
        self.task = task
        self.outcome = outcome
        self.scheduleEvent = scheduleEvent

        var hasher = Hasher()
        hasher.combine(task.uuid)
        hasher.combine(scheduleEvent.occurrence)
        id = "\(hasher.finalize())"
    }

    /// A property that creates an event from this event.
    var anyEvent: OCKAnyEvent {
        OCKAnyEvent(task: task, outcome: outcome, scheduleEvent: scheduleEvent)
    }

    /// Compute the progress for an event.
    ///
    /// Progress is computed according to the `strategy`. See ``CareTaskProgressStrategy`` for a list of
    /// the different strategies.
    ///
    /// Compute progress across multiple events using ``AggregatedCareTaskProgress``.
    ///
    /// - Parameter strategy: The strategy that computes progress for the event.
    public func computeProgress<Progress>(
        by strategy: CareTaskProgressStrategy<Progress> = .checkingOutcomeExists
    ) -> Progress {

        let progress = strategy.computeProgress(anyEvent)
        return progress
    }

    // MARK: - Comparable

    public static func < (lhs: Self, rhs: Self) -> Bool {

        let partialEventA = PartialEvent(task: lhs.task, scheduleEvent: lhs.scheduleEvent)
        let partialEventB = PartialEvent(task: rhs.task, scheduleEvent: rhs.scheduleEvent)
        return partialEventA.isOrderedBefore(other: partialEventB)
    }
}

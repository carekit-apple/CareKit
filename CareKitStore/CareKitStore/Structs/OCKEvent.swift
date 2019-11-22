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

/// An `OCKEvent` represents a single occassion on which a task was scheduled to occur. It contains a copy of the task itself as well as the
/// schedule event and an outcome that will be non-nil if progress was made on the task.
public struct OCKEvent<Task: OCKAnyTask, Outcome: OCKAnyOutcome> {

    /// A fully typed version of the task associated with this event.
    public let task: Task

    /// A fully typed version of the outcome associated with this event.
    public var outcome: Outcome?

    /// A value containing scheduling information for this event.
    public let scheduleEvent: OCKScheduleEvent

    /// Initialize an `OCKEvent` with a task, optional outcome, and schedule event.
    ///
    /// - Parameters:
    ///   - task: The task associated with this event.
    ///   - outcome: The outcome associated with this event.
    ///   - scheduleEvent: The schedule event.
    public init(task: Task, outcome: Outcome?, scheduleEvent: OCKScheduleEvent) {
        self.task = task
        self.outcome = outcome
        self.scheduleEvent = scheduleEvent
    }

    /// Creates an `OCKAnyEvent` from this event.
    var anyEvent: OCKAnyEvent {
        OCKAnyEvent(task: task, outcome: outcome, scheduleEvent: scheduleEvent)
    }
}

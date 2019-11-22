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

/// An event represents a single occassion on which a task was scheduled to occur. It contains a copy of the task itself as well as the
/// schedule event and an outcome that will be non-nil if progress was made on the task.
public struct OCKAnyEvent {

    /// The task that this event is associated with
    public let task: OCKAnyTask

    /// The outcome for this event. If the outcome is empty, that means that no actions were recorded.
    ///
    /// - Note: The outcome may be non-nil even if if the task was not completed, so simply checking the presence of an outcome is not sufficient
    /// to determing whether or not the task was completed. Examples of times when the outcome is non-nil but the task was not completed could
    /// include, among others
    ///     1. The user created a note specifying why they weren't able to complete the task.
    ///     2. The user completed the task, but then deleted all the values they recorded.
    ///     3. The user only partially completed the task.
    public let outcome: OCKAnyOutcome?

    /// The schedule event for this task occurrence. It contains information about the start, duration, occurrence number, and schedule element that
    /// resulted in this event.
    public let scheduleEvent: OCKScheduleEvent

    /// Initialize by specifying a task, schedule event, and optional outcome.
    ///
    /// - Parameter task: The task associated with this event.
    /// - Parameter outcome: The outcome associated with this event, or nil if no outcome exists yet.
    /// - Parameter scheduleEvent: The schedule event that resulted in this event.
    public init(task: OCKAnyTask, outcome: OCKAnyOutcome?, scheduleEvent: OCKScheduleEvent) {
        self.task = task
        self.outcome = outcome
        self.scheduleEvent = scheduleEvent
    }
}

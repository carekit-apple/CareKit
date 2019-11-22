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

/// Conforming a type to `OCKAnyOutcome` allows it to be queried and displayed by CareKit.
public protocol OCKAnyOutcome {

    /// A user-defined unique identifier, typically human readable.
    var id: String { get }

    /// Specifies how many events occured before this outcome was created. For example, if a task is schedule to happen twice per day, then
    /// the 2nd outcome on the 2nd day will have a `taskOccurrenceIndex` of 3.
    ///
    /// - Note: The task occurrence references a specific version of a task, so if a new version the task is created, the task occurrence index
    ///  will start again from 0.
    var taskOccurrenceIndex: Int { get }

    /// An array of values associated with this outcome. Most outcomes will have 0 or 1 values, but some may have more.
    /// - Examples:
    ///   - A task to call a physician might have 0 values, or 1 value containing the time stamp of when the call was placed.
    ///   - A task to walk 2,000 steps might have 1 value, with that value being the number of steps that were actually taken.
    ///   - A task to complete a survey might have multiple values corresponding to the answers to the questions in the survey.
    var values: [OCKOutcomeValue] { get set }

    /// An identifier for this outcome in a remote store.
    var remoteID: String? { get }

    /// An identifier that can be uesd to group this outcome with others.
    var groupIdentifier: String? { get }

    /// Any array of notes associated with this object.
    var notes: [OCKNote]? { get }

    /// Determines if this outcome is associated with the given task.
    /// 
    /// - Parameter task: A task which may or may not own this outcome.
    func belongs(to task: OCKAnyTask) -> Bool
}

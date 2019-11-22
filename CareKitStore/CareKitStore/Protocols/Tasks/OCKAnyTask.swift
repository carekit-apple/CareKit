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

/// Conforming a type to `OCKAnyTask` allows it to be queried and displayed by CareKit.
public protocol OCKAnyTask {

    /// A user-defined unique identifier, typically human readable.
    var id: String { get }

    /// A title that will be used to represent this care plan to the patient.
    var title: String? { get }

    /// Instructions about how this task should be performed.
    var instructions: String? { get }

    /// If true, completion of this task will be factored into the patient's overall adherence. True by default.
    var impactsAdherence: Bool { get }

    /// A schedule that specifies how often this task occurs.
    var schedule: OCKSchedule { get }

    /// A user-defined group identifer that can be used both for querying and sorting results.
    /// Examples may include: "medications", "exercises", "family", "males", "diabetics", etc.
    var groupIdentifier: String? { get }

    /// An identifier for this patient in a remote store.
    var remoteID: String? { get }

    /// Any array of notes associated with this object.
    var notes: [OCKNote]? { get }

    /// Determines if this task belongs to the given care plan.
    ///
    /// - Parameter plan: A care plan that may or may not own this task.
    func belongs(to plan: OCKAnyCarePlan) -> Bool
}

internal protocol OCKAnyMutableTask: OCKAnyTask {
    var title: String? { get set }
    var instructions: String? { get set }
    var impactsAdherence: Bool { get set }
    var schedule: OCKSchedule { get set }
}

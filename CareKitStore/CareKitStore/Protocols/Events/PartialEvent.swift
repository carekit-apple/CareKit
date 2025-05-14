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

struct PartialEvent<Task: OCKAnyTask> {

    var task: Task
    var scheduleEvent: OCKScheduleEvent

    // A PartialEvent is not always Equatable because the underlying Task is type erased,
    // so creating a compare method that doesn't rely on Equatable.
    func isOrderedBefore(other: PartialEvent<Task>) -> Bool {

        if scheduleEvent.start != other.scheduleEvent.start {
            return scheduleEvent.start < other.scheduleEvent.start
        }

        if task.uuid != other.task.uuid {
            return task.uuid.uuidString < other.task.uuid.uuidString
        }

        // At this point, the two events belong to the same task version and occur at the same time. Sort by occurrence
        // which should be guaranteed to be increasing between two events for the same task version.

        if scheduleEvent.occurrence == other.scheduleEvent.occurrence {
            assertionFailure("Unexpectedly found two events for the same task version with equal occurrences")
        }

        return scheduleEvent.occurrence < other.scheduleEvent.occurrence
    }
}

extension PartialEvent: Equatable where Task: Equatable {}

extension PartialEvent: Comparable where Task: Equatable {

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.isOrderedBefore(other: rhs)
    }
}

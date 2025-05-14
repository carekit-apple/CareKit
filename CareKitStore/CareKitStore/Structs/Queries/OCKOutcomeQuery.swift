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

/// A query that limits which outcomes will be returned when fetching.
public struct OCKOutcomeQuery: Equatable, OCKQueryProtocol {

    /// Specifies the order in which query results will be sorted.
    public enum SortDescriptor: Equatable {

        case effectiveDate(ascending: Bool)
        case groupIdentifier(ascending: Bool)

        var nsSortDescriptor: NSSortDescriptor {
            switch self {
            case let .effectiveDate(ascending):
                return NSSortDescriptor(keyPath: \OCKCDOutcome.effectiveDate, ascending: ascending)
            case let .groupIdentifier(ascending):
                return NSSortDescriptor(keyPath: \OCKCDOutcome.groupIdentifier, ascending: ascending)
            }
        }
    }

    /// An array of task identifiers to match against.
    public var taskIDs: [String] = []

    /// An array of universally unique identifiers of tasks for which outcomes should be returned.
    public var taskUUIDs: [UUID] = []

    /// An array of remote IDs of tasks for which outcomes should be returned.
    public var taskRemoteIDs: [String] = []

    /// The order in which the results will be sorted when returned from the query.
    public var sortDescriptors: [SortDescriptor] = []

    // MARK: OCKQuery
    public var ids: [String] = []
    public var uuids: [UUID] = []
    public var groupIdentifiers: [String?] = []
    public var tags: [String] = []
    public var remoteIDs: [String?] = []
    public var dateInterval: DateInterval?
    public var limit: Int?
    public var offset: Int = 0

    public init() {}

    public init(dateInterval: DateInterval? = nil) {
        self.dateInterval = dateInterval
    }

    /// Create a query with that spans the entire day on the date given.
    public init(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
        self = Self(dateInterval: DateInterval(start: startOfDay, end: endOfDay))
    }
}

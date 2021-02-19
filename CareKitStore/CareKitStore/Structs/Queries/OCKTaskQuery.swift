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

/// A query that limits which tasks will be returned when fetching.
public struct OCKTaskQuery: Equatable, OCKQueryProtocol {

    /// Specifies the order in which query results will be sorted.
    public enum SortDescriptor: Equatable {
        case effectiveDate(ascending: Bool)
        case groupIdentifier(ascending: Bool)
        case title(ascending: Bool)
    }

    /// An array of care plan identifiers to match against.
    public var carePlanIDs: [String] = []

    /// The version of the care plans for which tasks should match.
    public var carePlanUUIDs: [UUID] = []

    /// The remote IDs of the care plans for which tasks should match.
    public var carePlanRemoteIDs: [String] = []

    /// Determines if tasks with no events should be included in the query results or not. False be default.
    public var excludesTasksWithNoEvents: Bool = false

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

    public init(id: String) {
        self.ids = [id]
    }
}

internal extension Array where Element: OCKAnyTask {

    func filtered(dateInterval: DateInterval?, excludeTasksWithNoEvents: Bool) -> [Element] {

        guard let dateInterval = dateInterval else {
            return self
        }

        return filter { task -> Bool in
            let events = task.schedule.events(from: dateInterval.start, to: dateInterval.end)

            if excludeTasksWithNoEvents && events.isEmpty { return false }

            // Schedule with finite duration
            if let scheduleEnd = task.schedule.endDate() {
                let taskBeginsAfterQueryStarts = scheduleEnd >= dateInterval.start
                let taskBeginsBeforeQueryEnds = task.effectiveDate <= dateInterval.end
                guard taskBeginsAfterQueryStarts && taskBeginsBeforeQueryEnds else {
                    return false
                }
            }

            // Schedule with infinite duration
            else if events.isEmpty && task.effectiveDate > dateInterval.end {
                return false
            }

            return true
        }
    }
}

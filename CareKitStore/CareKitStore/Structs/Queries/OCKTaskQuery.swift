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

/// A protocol that all task queries are expected to conform to.
public protocol OCKAnyTaskQuery: OCKEntityQuery {

    /// The IDs of care plans for which tasks should match.
    var carePlanIDs: [String] { get set }

    /// The order in which the results will be sorted when returned from the query.
    var sortDescriptors: [OCKTaskSortDescriptor] { get set }
}

public extension OCKAnyTaskQuery {
    init(_ query: OCKAnyTaskQuery) {
        if let other = query as? Self {
            self = other
            return
        }
        self = Self(query as OCKEntityQuery)
        self.carePlanIDs = query.carePlanIDs
        self.sortDescriptors = query.sortDescriptors
    }
}

/// Describes the order in which tasks can be sorted when queried.
public enum OCKTaskSortDescriptor: Equatable {
    case groupIdentifier(ascending: Bool)
    case title(ascending: Bool)

    fileprivate var extendedVersion: OCKTaskQuery.SortDescriptor {
        switch self {
        case .groupIdentifier(let ascending): return .groupIdentifier(ascending: ascending)
        case .title(let ascending): return .title(ascending: ascending)
        }
    }
}

/// A query that limits which tasks will be returned when fetching.
public struct OCKTaskQuery: OCKAnyTaskQuery, Equatable {

    /// Specifies the order in which query results will be sorted.
    enum SortDescriptor: Equatable {
        case effectiveDate(ascending: Bool)
        case createdDate(ascending: Bool)
        case groupIdentifier(ascending: Bool)
        case title(ascending: Bool)

        fileprivate var basicVersion: OCKTaskSortDescriptor? {
            switch self {
            case .groupIdentifier(let ascending): return .groupIdentifier(ascending: ascending)
            case .title(let ascending): return .title(ascending: ascending)
            case .effectiveDate, .createdDate: return nil
            }
        }
    }

    /// The version of the care plans for which tasks should match.
    public var carePlanUUIDs: [UUID] = []

    /// The remote IDs of the care plans for which tasks should match.
    public var carePlanRemoteIDs: [String] = []

    /// Determines if tasks with no events should be included in the query results or not. False be default.
    public var excludesTasksWithNoEvents: Bool = false

    /// The order in which the results will be sorted when returned from the query.
    public var sortDescriptors: [OCKTaskSortDescriptor] {
        get { extendedSortDescriptors.compactMap { $0.basicVersion } }
        set { extendedSortDescriptors = newValue.map { $0.extendedVersion } }
    }

    /// The order in which the results will be sorted when returned from the query. This property supports
    /// additional sort descriptors unique to `OCKStore`.
    internal var extendedSortDescriptors: [SortDescriptor] = []

    /// An array of group identifiers to match against.
    public var groupIdentifiers: [String?] = []

    /// An array of tags to match against. If an object's tags contains one or more of entries, it will match the query.
    public var tags: [String] = []

    // MARK: OCKAnyTaskQuery
    public var ids: [String] = []
    public var uuids: [UUID] = []
    public var remoteIDs: [String?] = []
    public var carePlanIDs: [String] = []
    public var dateInterval: DateInterval?
    public var limit: Int?
    public var offset: Int = 0

    public init() {
        extendedSortDescriptors = [
            .effectiveDate(ascending: false),
            .createdDate(ascending: false),
            .title(ascending: false)
        ]
    }
}

internal extension Array where Element: OCKCDTaskCompatible {
    func filtered(against query: OCKTaskQuery) -> [Element] {

        var remaining = self

        if let dateInterval = query.dateInterval {
            remaining = filter(against: dateInterval, excludeTasksWithNoEvents: query.excludesTasksWithNoEvents)
        }

        return remaining.filter { task -> Bool in

            if !query.tags.isEmpty {
                let taskTags = task.tags ?? []
                let matchesExist = taskTags.map { query.tags.contains($0) }.contains(true)
                if !matchesExist { return false }
            }

            if !query.groupIdentifiers.isEmpty {
                guard let taskGroupIdentifier = task.groupIdentifier else { return false }
                if !query.groupIdentifiers.contains(taskGroupIdentifier) { return false }
            }

            return true
        }
    }

    func filter(against dateInterval: DateInterval, excludeTasksWithNoEvents: Bool) -> [Element] {
        filter { task -> Bool in
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

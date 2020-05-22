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

/// All queries that return non-ephemeral entities from the store are expected to conform to this protocol.
/// Examples of non-ephemeral entites are patients, care plans, contacts, tasks, and outcomes.
/// Ephemeral entities include events, adherence, and insights.
public protocol OCKEntityQuery {

    /// An array of unique identifiers belonging to the entities which should match the query.
    var ids: [String] { get set }

    /// An array of remote IDs for entities that should match the query.
    var remoteIDs: [String?] { get set }

    /// An array of group identifers that should match the query.
    var groupIdentifiers: [String?] { get set }

    /// A date interval for entities that should match the query.
    var dateInterval: DateInterval? { get set }

    /// The maximum number of results that will be returned by the query. A nil value indicates no upper limit.
    var limit: Int? { get set }

    /// An offset that can be used to paginate results.
    var offset: Int { get set }

    /// Initialize a new query with default properties.
    init()
}

public extension OCKEntityQuery {

    /// Create a query that spans an explicit date interval.
    init(dateInterval: DateInterval) {
        self = Self()
        self.dateInterval = dateInterval
    }

    /// Create a query to retrieve an entity with the specified unique identifier.
    init(id: String) {
        self = Self()
        self.ids = [id]
    }

    /// Create a query with that spans the entire day on the date given.
    init(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
        self = Self(dateInterval: DateInterval(start: startOfDay, end: endOfDay))
    }

    /// Create a new query from any other entity query. Properties common to both queries will be copied.
    init(_ query: OCKEntityQuery) {
        self = Self()
        self.ids = query.ids
        self.remoteIDs = query.remoteIDs
        self.limit = query.limit
        self.offset = query.offset
        self.dateInterval = query.dateInterval
    }
}

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

/// All query objects that are meaningful for when defined between two dates conform to this protocol.
/// For example, one may wish to query for all events that occur between two dates.
public protocol OCKDateIntervalQueryable {
    /// The date that the query begins on.
    var start: Date { get }

    /// The date that the query ends on.
    var end: Date { get }

    /// Create a new query with a start and end date.
    init(start: Date, end: Date)
}

public extension OCKDateIntervalQueryable {
    /// Initialize using a date internal.
    ///
    /// - Parameter dateInterval: A  date interval specifying the range in which objects should be returned.
    init(dateInterval: DateInterval) {
        self = Self(start: dateInterval.start, end: dateInterval.end)
    }

    /// Initialize for a given date.
    init(for date: Date) {
        self = Self.dayOf(date: date)
    }

    init(from query: OCKDateIntervalQueryable) {
        self = Self(start: query.start, end: query.end)
    }

    /// Builds a query that spans the full date of the date given.
    /// - Parameter date: A date on which the query should return objects.
    /// - Returns: A query covering the full extent of the day the given date falls on.
    static func dayOf(date: Date) -> Self {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
        return Self(start: startOfDay, end: endOfDay)
    }

    static var today: Self {
        dayOf(date: Date())
    }

    internal var dateInterval: DateInterval {
        DateInterval(start: start, end: end)
    }

    func dates() -> [Date] {
        var dates = [Date]()
        var currentDate = start
        while currentDate < end {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
}

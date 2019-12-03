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

extension Calendar {

    /// Returns a date interval that spans the entire week of the given date. The difference between this method and the
    /// Foundation `Calendar.dateInterval(of:for:)` method is that this method produces non-overlapping
    /// intervals.
    func dateIntervalOfWeek(for date: Date) -> DateInterval {
        var interval = Calendar.current.dateInterval(of: .weekOfYear, for: date)!
        interval.duration -= 1   // The default interval contains 1 second of the next day after the interval. Subtract that off
        return interval
    }

    /// Returns string representations of the weekdays, in the order the weekdays occur on the local calendar.
    /// This differs with the Foundation `Calendar.veryShortWeekdaySymbols` in that the ordering is changed such
    /// that the first element of the array corresponds to the first weekday in the current locale, instead of Sunday.
    ///
    /// This method is required for handling certain regions in which the first day of the week is Monday.
    func orderedWeekdaySymbolsVeryShort() -> [String] {
        var symbols = veryShortWeekdaySymbols
        Array(1..<firstWeekday).forEach { _ in
            let symbol = symbols.removeFirst()
            symbols.append(symbol)
        }
        return symbols
    }

    /// Returns string representations of the weekdays, in the order the weekdays occur on the local calendar.
    /// This differs with the Foundation `Calendar.weekdaySymbols` in that the ordering is changed such
    /// that the first element of the array corresponds to the first weekday in the current locale, instead of Sunday.
    ///
    /// This method is required for handling certain regions in which the first day of the week is Monday.
    func orderedWeekdaySymbols() -> [String] {
        var symbols = weekdaySymbols
        Array(1..<firstWeekday).forEach { _ in
            let symbol = symbols.removeFirst()
            symbols.append(symbol)
        }
        return symbols
    }
}

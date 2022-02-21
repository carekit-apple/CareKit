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

import Combine
import Foundation

/// A calendar controller that handles a calendar showing a single week.
open class OCKWeekCalendarController: OCKCalendarController {

    public init(weekOfDate date: Date, storeManager: OCKSynchronizedStoreManager) {
        var weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: date)!
        weekInterval.duration -= 1    // Note: Default interval includes the first second of the next week
        super.init(dateInterval: weekInterval, storeManager: storeManager)
    }

    public required init(dateInterval: DateInterval, storeManager: OCKSynchronizedStoreManager) {
        var weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        weekInterval.duration -= 1    // Note: Default interval includes the first second of the next week
        guard Self.dateIntervalIsValid(dateInterval) else { fatalError("Date interval should be one week long") }
        super.init(dateInterval: dateInterval, storeManager: storeManager)
    }

    // Date interval is valid if it spans one week
    private static func dateIntervalIsValid(_ dateInterval: DateInterval) -> Bool {
        var weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: dateInterval.start)!
        weekInterval.duration -= 1    // Note: Default interval includes the first second of the next week

        return weekInterval.start == dateInterval.start && weekInterval.end == dateInterval.end
    }
}

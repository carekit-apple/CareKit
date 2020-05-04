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

import CoreData
import Foundation

@objc(OCKCDScheduleElement)
class OCKCDScheduleElement: NSManagedObject {
    @NSManaged var text: String?
    @NSManaged var task: OCKCDTask?
    @NSManaged var targetValues: Set<OCKCDOutcomeValue>

    @NSManaged var startDate: Date
    @NSManaged var endDate: Date?

    @NSManaged var secondsInterval: Int64
    @NSManaged var minutesInterval: Int64
    @NSManaged var hoursInterval: Int64
    @NSManaged var daysInterval: Int64
    @NSManaged var weeksInterval: Int64
    @NSManaged var monthsInterval: Int64
    @NSManaged var yearsInterval: Int64

    // These 2 are controlled by the `duration` computed property.
    @NSManaged private var durationInSeconds: Double
    @NSManaged private var isAllDay: Bool

    var duration: OCKScheduleElement.Duration {
        get { isAllDay ? .allDay : .seconds(durationInSeconds) }
        set {
            isAllDay = newValue == .allDay
            durationInSeconds = newValue.seconds
        }
    }

    var interval: DateComponents {
        get {
            var interval = DateComponents()
            interval.year = Int(yearsInterval)
            interval.month = Int(monthsInterval)
            interval.weekOfYear = Int(weeksInterval)
            interval.day = Int(daysInterval)
            interval.hour = Int(hoursInterval)
            interval.minute = Int(minutesInterval)
            interval.second = Int(secondsInterval)
            return interval
        }

        set {
            yearsInterval = Int64(newValue.year ?? 0)
            monthsInterval = Int64(newValue.month ?? 0)
            weeksInterval = Int64(newValue.weekOfYear ?? 0)
            daysInterval = Int64(newValue.day ?? 0)
            hoursInterval = Int64(newValue.hour ?? 0)
            minutesInterval = Int64(newValue.minute ?? 0)
            secondsInterval = Int64(newValue.second ?? 0)
        }
    }
}

extension OCKCDScheduleElement {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        targetValues = Set()
    }

    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateForConsistency()
    }

    override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateForConsistency()
    }

    private func validateForConsistency() throws {
        if !atLeastOneIntervalIsNonZero { throw OCKStoreError.invalidValue(reason: "OCKScheduleElement must have at least 1 non-zero interval") }
        if task == nil && targetValues.isEmpty { throw OCKStoreError.invalidValue(reason: "OCKScheduleElement must be associated with a task!") }
    }

    private var atLeastOneIntervalIsNonZero: Bool {
        return secondsInterval + minutesInterval + hoursInterval + daysInterval + weeksInterval + monthsInterval + yearsInterval > 0
    }
}

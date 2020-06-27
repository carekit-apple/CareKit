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

import CareKitStore
import Foundation
import ModelsDSTU2

extension ModelsDSTU2.Timing: OCKFHIRResource {
    public typealias Release = DSTU2
}

struct OCKDSTU2ScheduleCoder: OCKFHIRResourceCoder {

    typealias Resource = Timing
    typealias Entity = OCKSchedule

    func convert(resource: Timing) throws -> OCKSchedule {
        // There could be any of 3 kinds of schedules: Timing, Period, String.
        // For now we're only considering the Timing case.
        guard
            let timing = resource.repeat,
            let periodUnit = timing.periodUnits?.value,
            let periodCount = timing.period.map({ Int(truncating: $0.value!.decimal as NSNumber) })
        else { throw OCKFHIRCodingError.missingRequiredField("schedule") }

        // Make sure the activity has a valid start date.

        guard
            case let .period(period) = timing.bounds,
            let start = period.start?.value?.foundationDate else {
            throw OCKFHIRCodingError.unrepresentableContent(
                "A FHIR CarePlanActivity with no start date cannot be represented in CareKit.")
        }

        // A valid end date is not required in CareKit.
        let end: Date? = period.end?.value?.foundationDate

        let targets: [OCKOutcomeValue] = []
        let text: String? = timing.when?.value?.string

        let interval = try makeInterval(units: periodUnit, count: periodCount)
        let duration = try makeDuration(units: timing.durationUnits?.value, count: timing.duration?.value)

        let element = OCKScheduleElement(
            start: start, end: end,
            interval: interval, text: text,
            targetValues: targets, duration: duration)

        return OCKSchedule(composing: [element])
    }

    func convert(entity: OCKSchedule) throws -> Timing {

        // Verify that the schedule can be represented in FHIR format.
        // There must be only 1 schedule element and its interval must have only 1 component.
        guard let element = entity.elements.first else {
            throw OCKFHIRCodingError.corruptData("OCKSchedule didn't have any elements.")
        }
        guard entity.elements.count == 1 else {
            throw OCKFHIRCodingError.unrepresentableContent("OCKSchedules with more than 1 element cannot be represented in FHIR.")
        }

        var nonZeroComponentCount = 0
        let keypaths: [KeyPath<DateComponents, Int?>] = [\.second, \.minute, \.hour, \.day, \.weekOfYear, \.month, \.year]
        for path in keypaths {
            if element.interval[keyPath: path] != nil {
                nonZeroComponentCount += 1
            }
        }

        guard nonZeroComponentCount == 1 else {
            throw OCKFHIRCodingError.unrepresentableContent("""
            OCKScheduleElements with intervals containing more than 1 component cannot be represented in FHIR.
            """)
        }

        // Reject components not support by FHIR.
        if element.interval.year != nil {
            throw OCKFHIRCodingError.unrepresentableContent("OCKScheduleElements with an interval in units of years are not supported in FHIR.")
        }

        // Build out the FHIR schedule
        let repetition = TimingRepeat(element: element)
        let start = FHIRPrimitive(entity.startDate().dstu2FHIRDateTime)
        let end = FHIRPrimitive(entity.endDate()?.dstu2FHIRDateTime)
        repetition.bounds = .period(Period(end: end, start: start))
        repetition.frequency = FHIRPrimitive(1)

        let timing = Timing()
        timing.repeat = repetition

        return timing
    }

    private func makeInterval(units: FHIRString, count: Int) throws -> DateComponents {
        switch units {
        case Calendar.Component.second.dstu2FHIRUnitString.value: return DateComponents(second: count)
        case Calendar.Component.minute.dstu2FHIRUnitString.value: return DateComponents(minute: count)
        case Calendar.Component.hour.dstu2FHIRUnitString.value: return DateComponents(hour: count)
        case Calendar.Component.day.dstu2FHIRUnitString.value: return DateComponents(day: count)
        case Calendar.Component.weekOfYear.dstu2FHIRUnitString.value: return DateComponents(weekOfYear: count)
        case Calendar.Component.month.dstu2FHIRUnitString.value: return DateComponents(month: count)
        default: throw OCKFHIRCodingError.corruptData("Unrecognized time units: \(units.string)")
        }
    }

    private func makeDuration(units: FHIRString?, count: FHIRDecimal?) throws -> OCKScheduleElement.Duration {
        guard let units = units, let count = count else { return .seconds(0) }
        let doubleValue = Double(truncating: count.decimal as NSNumber)

        // Treat units of days with duration of 1 as the special case `.allDay`.
        if units == Calendar.Component.day.dstu2FHIRUnitString && count == FHIRDecimal(1) {
            return .allDay
        }

        switch units {
        case Calendar.Component.second.dstu2FHIRUnitString.value: return .seconds(doubleValue)
        case Calendar.Component.minute.dstu2FHIRUnitString.value: return .minutes(doubleValue)
        case Calendar.Component.hour.dstu2FHIRUnitString.value: return .hours(doubleValue)
        default: throw OCKFHIRCodingError.corruptData("Unrecognized time unitss: \(units.string)")
        }
    }
}

private extension TimingRepeat {

    convenience init(element: OCKScheduleElement) {
        self.init()

        switch element.duration {
        case .allDay:
            durationUnits = Calendar.Component.day.dstu2FHIRUnitString
            duration = FHIRPrimitive(FHIRDecimal(Decimal(1)))
        case .seconds(let secs):
            durationUnits = Calendar.Component.second.dstu2FHIRUnitString
            duration = FHIRPrimitive(FHIRDecimal(Decimal(secs)))
        }

        if let seconds = element.interval.second {
            periodUnits = Calendar.Component.second.dstu2FHIRUnitString
            period = FHIRPrimitive(FHIRDecimal(Decimal(seconds)))
        } else if let minutes = element.interval.minute {
            periodUnits = Calendar.Component.minute.dstu2FHIRUnitString
            period = FHIRPrimitive(FHIRDecimal(Decimal(minutes)))
        } else if let hours = element.interval.hour {
            periodUnits = Calendar.Component.hour.dstu2FHIRUnitString
            period = FHIRPrimitive(FHIRDecimal(Decimal(hours)))
        } else if let days = element.interval.day {
            periodUnits = Calendar.Component.day.dstu2FHIRUnitString
            period = FHIRPrimitive(FHIRDecimal(Decimal(days)))
        } else if let weeks = element.interval.weekOfYear {
            periodUnits = Calendar.Component.weekOfYear.dstu2FHIRUnitString
            period = FHIRPrimitive(FHIRDecimal(Decimal(weeks)))
        } else if let months = element.interval.month {
            periodUnits = Calendar.Component.month.dstu2FHIRUnitString
            period = FHIRPrimitive(FHIRDecimal(Decimal(months)))
        } else {
            fatalError("Missing case")
        }
    }
}

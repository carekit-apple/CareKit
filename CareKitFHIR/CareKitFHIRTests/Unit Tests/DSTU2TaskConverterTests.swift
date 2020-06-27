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

@testable import CareKitFHIR
import CareKitStore
import ModelsDSTU2
import XCTest

class DSTU2TaskConverterTests: XCTestCase {

    // MARK: Convert FHIR Activity to OCKTask

    func testConvertFHIRActivityFailsWhenMissingID() {
        let activity = CarePlanActivity()
        let converter = OCKDSTU2CarePlanActivityCoder()
        let expectedError: OCKFHIRCodingError = .missingRequiredField("id")
        XCTAssertThrowsError(try converter.convert(resource: activity), matching: expectedError)
    }

    func testConvertFHIRActivityFailsWhenMissingSchedule() {
        let activity = CarePlanActivity()
        activity.id = "abc"
        let converter = OCKDSTU2CarePlanActivityCoder()
        let expectedError: OCKFHIRCodingError = .missingRequiredField("schedule")
        XCTAssertThrowsError(try converter.convert(resource: activity), matching: expectedError)
    }

    func testConvertFHIRTaskSucceedsForDefaultIDGetter() throws {
        let activity = CarePlanActivity()
        activity.id = "abc"

        let repetition = TimingRepeat()
        repetition.bounds = .period(Period(start: FHIRPrimitive(Date().dstu2FHIRDateTime)))
        repetition.period = FHIRPrimitive(FHIRDecimal(Decimal(1)))
        repetition.periodUnits = "d"
        repetition.frequency = FHIRPrimitive(1)

        let timing = Timing()
        timing.repeat = repetition

        activity.detail = CarePlanActivityDetail(prohibited: false, scheduled: .timing(timing))

        let converter = OCKDSTU2CarePlanActivityCoder()
        let task = try converter.convert(resource: activity)
        XCTAssert(task.id == "abc")
    }

    func testConvertFHIRTaskSucceedsForCustomIDGetter() throws {
        let activity = CarePlanActivity()

        let repetition = TimingRepeat()
        repetition.bounds = .period(Period(start: FHIRPrimitive(Date().dstu2FHIRDateTime)))
        repetition.period = FHIRPrimitive(FHIRDecimal(Decimal(1)))
        repetition.periodUnits = "d"
        repetition.frequency = FHIRPrimitive(1)

        let timing = Timing()
        timing.repeat = repetition
        activity.detail = CarePlanActivityDetail(prohibited: false, scheduled: .timing(timing))
        activity.detail?.description_fhir = "abc"

        var converter = OCKDSTU2CarePlanActivityCoder()
        converter.getCareKitID = { $0.detail!.description_fhir!.value!.string }

        let task = try converter.convert(resource: activity)
        XCTAssert(task.id == "abc")
    }

    func testConvertFHIRTaskSucceedsForDefaultTitleGetter() throws {
        let activity = CarePlanActivity()
        activity.id = "abc"

        let repetition = TimingRepeat()
        repetition.bounds = .period(Period(start: FHIRPrimitive(Date().dstu2FHIRDateTime)))
        repetition.period = FHIRPrimitive(FHIRDecimal(Decimal(1)))
        repetition.periodUnits = "d"
        repetition.frequency = FHIRPrimitive(1)

        let timing = Timing()
        timing.repeat = repetition

        activity.detail = CarePlanActivityDetail(prohibited: false, scheduled: .timing(timing))
        activity.detail?.description_fhir = "title"

        let converter = OCKDSTU2CarePlanActivityCoder()
        let task = try converter.convert(resource: activity)
        XCTAssert(task.title == "title")
    }

    func testConvertFHIRTaskSucceedsForDefaultScheduleGetter() throws {
        let activity = CarePlanActivity()
        activity.id = "abc"

        let repetition = TimingRepeat()
        repetition.bounds = .period(Period(start: FHIRPrimitive(Date().dstu2FHIRDateTime)))
        repetition.periodUnits = "d"
        repetition.period = FHIRPrimitive(FHIRDecimal(Decimal(1)))
        repetition.frequency = FHIRPrimitive(1)
        repetition.durationUnits = "h"
        repetition.duration = FHIRPrimitive(FHIRDecimal(2))

        let timing = Timing()
        timing.repeat = repetition

        activity.detail = CarePlanActivityDetail(prohibited: false, scheduled: .timing(timing))
        activity.detail?.description_fhir = "title"

        let converter = OCKDSTU2CarePlanActivityCoder()
        let task = try converter.convert(resource: activity)
        XCTAssert(task.schedule.elements.count == 1)
        XCTAssert(task.schedule.elements.first?.interval == DateComponents(day: 1))
        XCTAssert(task.schedule.elements.first?.duration == .hours(2))
    }

    func testConvertFHIRTaskSucceedsForAllDayScheduleElement() throws {
        let activity = CarePlanActivity()
        activity.id = "abc"

        let repetition = TimingRepeat()
        repetition.bounds = .period(Period(start: FHIRPrimitive(Date().dstu2FHIRDateTime)))
        repetition.periodUnits = "d"
        repetition.period = FHIRPrimitive(FHIRDecimal(Decimal(1)))
        repetition.frequency = FHIRPrimitive(1)
        repetition.durationUnits = "d"
        repetition.duration = FHIRPrimitive(FHIRDecimal(1))

        let timing = Timing()
        timing.repeat = repetition

        activity.detail = CarePlanActivityDetail(prohibited: false, scheduled: .timing(timing))
        activity.detail?.description_fhir = "title"

        let converter = OCKDSTU2CarePlanActivityCoder()
        let task = try converter.convert(resource: activity)
        XCTAssert(task.schedule.elements.count == 1)
        XCTAssert(task.schedule.elements.first?.interval == DateComponents(day: 1))
        XCTAssert(task.schedule.elements.first?.duration == .allDay)
    }

    // MARK: Convert OCKTask to FHIR Care Plan Activity

    func testConvertCareKitTaskToFHIRCarePlanActivitySucceedsForDefaultSetters() throws {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 2), duration: .hours(1))
        let schedule = OCKSchedule(composing: [element])
        let task = OCKTask(id: "abc", title: "title", carePlanUUID: nil, schedule: schedule)
        let converter = OCKDSTU2CarePlanActivityCoder()
        let activity = try converter.convert(entity: task)

        guard case let .timing(timing) = activity.detail?.scheduled else {
            XCTFail("Expected the schedule to be a timing")
            return
        }

        XCTAssert(activity.id == "abc")
        XCTAssert(activity.detail?.description_fhir == "title")
        XCTAssert(timing.repeat?.periodUnits == "d")
        XCTAssert(timing.repeat?.period == FHIRPrimitive(FHIRDecimal(2)))
        XCTAssert(timing.repeat?.frequency == FHIRPrimitive(1))
        XCTAssert(timing.repeat?.durationUnits == "s")
        XCTAssert(timing.repeat?.duration == FHIRPrimitive(FHIRDecimal(3_600)))
    }

    func testConvertCareKitTaskToFHIRCarePlanActivityConvertsAllDayElementsCorrectly() throws {
        let startDate = Date().truncatingNanoSeconds
        let endDate = Calendar.current.date(byAdding: .year, value: 2, to: startDate)
        let element = OCKScheduleElement(start: startDate, end: endDate, interval: DateComponents(day: 2), duration: .hours(2))
        let schedule = OCKSchedule(composing: [element])
        let task = OCKTask(id: "abc", title: "title", carePlanUUID: nil, schedule: schedule)
        let converter = OCKDSTU2CarePlanActivityCoder()
        let activity = try converter.convert(entity: task)

        guard
            case let .timing(timing) = activity.detail?.scheduled,
            case let .period(period) = timing.repeat?.bounds
        else {
            XCTFail("Expected the schedule to be a timing")
            return
        }

        XCTAssert(activity.id == "abc")
        XCTAssert(activity.detail?.description_fhir == "title")
        XCTAssert(timing.repeat?.periodUnits == "d")
        XCTAssert(timing.repeat?.period == FHIRPrimitive(FHIRDecimal(2)))
        XCTAssert(timing.repeat?.durationUnits == "s")
        XCTAssert(timing.repeat?.duration == FHIRPrimitive(FHIRDecimal(7_200)))
        XCTAssert(period.start?.value?.foundationDate == startDate)
        XCTAssert(period.end?.value?.foundationDate == endDate)

    }

    func testConvertCareKitTaskToFHIRCarePlanActivityFailsIfScheduleHasMoreThanOneElement() {
        let element1 = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(day: 2))
        let element2 = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(hour: 50))
        let schedule = OCKSchedule(composing: [element1, element2])
        let task = OCKTask(id: "abc", title: "title", carePlanUUID: nil, schedule: schedule)
        let converter = OCKDSTU2CarePlanActivityCoder()

        let errorMessage = "OCKSchedules with more than 1 element cannot be represented in FHIR."
        let expectedError = OCKFHIRCodingError.unrepresentableContent(errorMessage)
        XCTAssertThrowsError(try converter.convert(entity: task), matching: expectedError)
    }

    func testConvertCareKitTaskToFHIRCarePlanActivityFailsIfIntervalHasMultipleComponents() {
        let interval = DateComponents(day: 1, hour: 12)
        let element = OCKScheduleElement(start: Date(), end: nil, interval: interval)
        let schedule = OCKSchedule(composing: [element])
        let task = OCKTask(id: "abc", title: "title", carePlanUUID: nil, schedule: schedule)
        let converter = OCKDSTU2CarePlanActivityCoder()

        let errorMessage = "OCKScheduleElements with intervals containing more than 1 component cannot be represented in FHIR."
        let expectedError = OCKFHIRCodingError.unrepresentableContent(errorMessage)
        XCTAssertThrowsError(try converter.convert(entity: task), matching: expectedError)
    }

    func testConvertCareKitTaskToFHIRCarePlanActivityFailsIfIntervalHasYearComponent() {
        let element = OCKScheduleElement(start: Date(), end: nil, interval: DateComponents(year: 2))
        let schedule = OCKSchedule(composing: [element])
        let task = OCKTask(id: "abc", title: "title", carePlanUUID: nil, schedule: schedule)
        let converter = OCKDSTU2CarePlanActivityCoder()

        let errorMessage = "OCKScheduleElements with an interval in units of years are not supported in FHIR."
        let expectedError = OCKFHIRCodingError.unrepresentableContent(errorMessage)
        XCTAssertThrowsError(try converter.convert(entity: task), matching: expectedError)
    }
}

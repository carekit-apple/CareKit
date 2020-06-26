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
import Foundation
import ModelsDSTU2
import XCTest

class DSTU2MedicationOrderConverterTest: XCTestCase {

    func testConvertFHIRMedicationOrderToCareKitTask() throws {

        let repetition = TimingRepeat()
        repetition.bounds = .period(Period(start: FHIRPrimitive(Date().dstu2FHIRDateTime)))
        repetition.period = FHIRPrimitive(FHIRDecimal(Decimal(1)))
        repetition.periodUnits = "d"
        repetition.frequency = FHIRPrimitive(1)

        let concept = CodeableConcept()
        concept.text = "Title"

        let instructions = MedicationOrderDosageInstruction()
        instructions.timing = Timing(code: concept)
        instructions.timing?.repeat = repetition
        instructions.text = "Instructions"

        let medicationOrder = MedicationOrder(medication: .codeableConcept(concept))
        medicationOrder.id = "ABC"
        medicationOrder.dosageInstruction = [instructions]

        let task = try OCKDSTU2MedicationOrderCoder().convert(resource: medicationOrder)
        XCTAssert(task.id == "ABC")
        XCTAssert(task.title == "Title")
        XCTAssert(task.instructions == "Instructions")
        XCTAssert(task.schedule.elements.first?.interval == DateComponents(day: 1))
    }

    func testConvertCareKitTaskToFHIRMedicationOrder() throws {
        let startDate = Date().truncatingNanoSeconds
        let endDate = Calendar.current.date(byAdding: .day, value: 10, to: startDate)!.truncatingNanoSeconds

        let element = OCKScheduleElement(start: startDate, end: endDate, interval: DateComponents(day: 1), duration: .seconds(10))
        let schedule = OCKSchedule(composing: [element])
        var medication = OCKTask(id: "ABC", title: "Ibuprofen", carePlanUUID: nil, schedule: schedule)
        medication.instructions = "Instructions"

        let medicationOrder = try OCKDSTU2MedicationOrderCoder().convert(entity: medication)

        guard case let .period(period) = medicationOrder.dosageInstruction?.first?.timing?.repeat?.bounds else {
            XCTFail("Expected a period")
            return
        }

        XCTAssert(medicationOrder.id?.value?.string == "ABC")
        XCTAssert(medicationOrder.dosageInstruction?.first?.text == "Instructions")
        XCTAssert(medicationOrder.dosageInstruction?.first?.timing?.repeat?.periodUnits == "d")
        XCTAssert(medicationOrder.dosageInstruction?.first?.timing?.repeat?.period == FHIRPrimitive(FHIRDecimal(1)))
        XCTAssert(medicationOrder.dosageInstruction?.first?.timing?.repeat?.durationUnits == "s")
        XCTAssert(medicationOrder.dosageInstruction?.first?.timing?.repeat?.duration == FHIRPrimitive(FHIRDecimal(10)))
        XCTAssert(period.start?.value?.foundationDate == startDate)
        XCTAssert(period.end?.value?.foundationDate == endDate)
    }
}

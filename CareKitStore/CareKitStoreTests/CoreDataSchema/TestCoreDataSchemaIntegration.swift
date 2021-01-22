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

@testable import CareKitStore
import XCTest

class TestCoreDataSchemaIntegration: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "test", type: .inMemory)
    }

    func testAllEntitiesCanBeChainedAndSavedInABatch() throws {
        let patient = OCKCDPatient(context: try store.context())
        patient.id = "my_id"
        patient.uuid = UUID()
        patient.name = OCKCDPersonName(context: try store.context())
        patient.name.familyName = "Amy"
        patient.name.givenName = "Frost"
        patient.effectiveDate = Date()

        let plan = OCKCDCarePlan(context: try store.context())
        plan.title = "Post Operation Care Plan"
        plan.id = "post-op-plan"
        plan.uuid = UUID()
        plan.patient = patient
        plan.effectiveDate = Date()

        let task = OCKCDTask(context: try store.context())
        task.id = "measure-pulse"
        task.uuid = UUID()
        task.instructions = "Take your pulse for a 60s and record in BPM"
        task.carePlan = plan
        task.effectiveDate = Date()

        let schedule = OCKCDScheduleElement(context: try store.context())
        schedule.text = "Once each day"
        schedule.startDate = Date()
        schedule.daysInterval = 1
        schedule.duration = .hours(1)
        schedule.task = task

        let outcome = OCKCDOutcome(context: try store.context())
        outcome.taskOccurrenceIndex = 0
        outcome.task = task
        outcome.startDate = Date()
        outcome.endDate = Date()

        let value = OCKCDOutcomeValue(context: try store.context())
        value.kind = "pulse"
        value.units = "BPM"
        value.integerValue = 80
        value.type = .integer
        value.outcome = outcome

        XCTAssertNoThrow(try store.context().save())
        XCTAssert(patient.carePlans.first == plan)
        XCTAssert(task.scheduleElements.first == schedule)
        XCTAssert(task.outcomes.first == outcome)
        XCTAssert(outcome.values.first == value)
    }
}

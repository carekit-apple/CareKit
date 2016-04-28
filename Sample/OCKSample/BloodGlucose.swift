/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
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

import ResearchKit
import CareKit

/**
 Struct that conforms to the `Assessment` protocol to define a blood glucose
 assessment.
 */
struct BloodGlucose: Assessment {
    // MARK: Activity
    
    let activityType: ActivityType = .BloodGlucose
    
    func carePlanActivity() -> OCKCarePlanActivity {
        // Create a weekly schedule.
        let startDate = NSDateComponents(year: 2016, month: 01, day: 01)
        let schedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDate, occurrencesOnEachDay: [1, 1, 1, 1, 1, 1, 1])
        
        // Get the localized strings to use for the assessment.
        let title = NSLocalizedString("Blood Glucose", comment: "")
        let summary = NSLocalizedString("After dinner", comment: "")
        
        let activity = OCKCarePlanActivity.assessmentWithIdentifier(
            activityType.rawValue,
            groupIdentifier: nil,
            title: title,
            text: summary,
            tintColor: Colors.Purple.color,
            resultResettable: false,
            schedule: schedule,
            userInfo: nil
        )
        
        return activity
    }
    
    // MARK: Assessment
    
    func task() -> ORKTask {
        // Get the localized strings to use for the task.
        let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodGlucose)!
        let unit = HKUnit(fromString: "mg/dL")
        let answerFormat = ORKHealthKitQuantityTypeAnswerFormat(quantityType: quantityType, unit: unit, style: .Decimal)
        
        // Create a question.
        let title = NSLocalizedString("Input your blood glucose", comment: "")
        let questionStep = ORKQuestionStep(identifier: activityType.rawValue, title: title, answer: answerFormat)
        questionStep.optional = false
        
        // Create an ordered task with a single question.
        let task = ORKOrderedTask(identifier: activityType.rawValue, steps: [questionStep])
        
        return task
    }
}

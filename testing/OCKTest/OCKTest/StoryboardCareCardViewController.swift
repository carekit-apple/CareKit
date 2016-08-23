/*
 Copyright (c) 2016, Troy Tsubota. All rights reserved.
 
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

import CareKit

class StoryboardCareCardViewController: OCKCareCardViewController {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        var carePlanActivities = [OCKCarePlanActivity]()
        let firstGroupId = "Group I1"
        
        let startDateComponents = NSDateComponents()
        startDateComponents.day = 20
        startDateComponents.month = 2
        startDateComponents.year = 2015
        
        let dailySchedule = OCKCareSchedule.dailyScheduleWithStartDate(startDateComponents, occurrencesPerDay: 2)
        let weeklySchedule = OCKCareSchedule.weeklyScheduleWithStartDate(startDateComponents, occurrencesOnEachDay:[4, 0, 4, 0, 4, 0, 4])
        
        carePlanActivities.append(OCKCarePlanActivity(identifier: "Storyboard Activity #1", groupIdentifier: firstGroupId, type: .Intervention, title: "Storyboard Activity Title 1", text: "This view controller is instantiated in the storyboard.", tintColor: nil, instructions: "Perform the described task and report the results. Talk to your doctor if you need help", imageURL: nil, schedule: dailySchedule, resultResettable: true, userInfo: ["Key1":"Value1","Key2":"Value2"]))
        
        carePlanActivities.append(OCKCarePlanActivity(identifier: "Storyboard Activity #2", groupIdentifier: firstGroupId, type: .Intervention, title: "Alternate-Day Intervention Activity Title 2", text: "This activity is added in the default care plan store.", tintColor: UIColor.brownColor(), instructions: nil, imageURL: nil, schedule: weeklySchedule, resultResettable: true, userInfo: ["Key1":"Value1", "Key2":"Value2"]))
        
        for activity in carePlanActivities {
            OCKCarePlanStore.defaultStore().addActivity(activity) { (_, error) in
                if let error = error {
                    print("Adding activity failed with error code \(error.code): \(error.localizedDescription)")
                }
            }
        }
    }

}
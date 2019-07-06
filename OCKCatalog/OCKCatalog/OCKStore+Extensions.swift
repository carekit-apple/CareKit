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
import CareKit

extension OCKSchedule {
    
    /// Create a schedule that happens at meal times every day of the week.
    static func mealTimesEachDay(start: Date, end: Date?) -> OCKSchedule {
        let startDate = Calendar.current.startOfDay(for: start)
        let breakfast = OCKSchedule.dailyAtTime(hour: 7, minutes: 30, start: startDate, end: end, text: "Breakfast")
        let lunch = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: startDate, end: end, text: "Lunch")
        let dinner = OCKSchedule.dailyAtTime(hour: 17, minutes: 30, start: startDate, end: end, text: "Dinner")
        return OCKSchedule(composing: [breakfast, lunch, dinner])
    }
}

extension OCKStore {
    
    func fillWithDummyData(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        let startDate = Calendar.current.startOfDay(for: Date())
        
        dispatchGroup.enter()
        addTasks(makeTasks(on: startDate)) { result in
            switch result {
            case .failure(let error): print("[ERROR] \(error.localizedDescription)")
            case .success: break
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        addContacts(makeContacts()) { result in
            switch result {
            case .failure(let error): print("[ERROR] \(error.localizedDescription)")
            case .success: break
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    private func makeTasks(on start: Date) -> [OCKTask] {
        var task1 = OCKTask(identifier: "nausea", title: "Nausea", carePlanID: nil,
                            schedule: .dailyAtTime(hour: 7, minutes: 0, start: start, end: nil, text: nil))
        task1.instructions = "Log any time you experience nausea."
        task1.impactsAdherence = false
        
        var task2 = OCKTask(identifier: "doxylamine", title: "Doxylamine", carePlanID: nil,
                            schedule: .mealTimesEachDay(start: Calendar.current.startOfDay(for: Date()), end: nil))
        task2.instructions = "Take the tablet with a full glass of water."
        
        return [task1, task2]
    }

    private func makeContacts() -> [OCKContact] {
        var contact1 = OCKContact(identifier: "lexi-torres", givenName: "Lexi", familyName: "Torres", carePlanID: nil)
        contact1.role = "Dr. Torres is a family practice doctor with over 20 years of experience."
        let phoneNumbers1 = [OCKLabeledValue(label: "work", value: "2135558479")]
        contact1.phoneNumbers = phoneNumbers1
        contact1.title = "Family Practice"
        contact1.messagingNumbers = phoneNumbers1
        contact1.emailAddresses = [OCKLabeledValue(label: "work", value: "lexitorres@icloud.com")]
        let address1 = OCKPostalAddress()
        address1.street = "26 E Centerline Rd"
        address1.city = "Victor"
        address1.state = "MI"
        address1.postalCode = "48848"
        contact1.address = address1
        
        var contact2 = OCKContact(identifier: "matthew-reiff", givenName: "Matthew", familyName: "Reiff", carePlanID: nil)
        contact2.role = "Dr. Reiff is a family practice doctor with over 20 years of experience."
        contact2.title = "Family Practice"
        let phoneNumbers2 = [OCKLabeledValue(label: "work", value: "7745550146")]
        contact2.phoneNumbers = phoneNumbers2
        contact2.messagingNumbers = phoneNumbers2
        contact2.emailAddresses = [OCKLabeledValue(label: "work", value: "matthewreiff@icloud.com")]
        let address2 = OCKPostalAddress()
        address2.street = "9391 Burkshire Avenue"
        address2.city = "Cardiff"
        address2.state = "CA"
        address2.postalCode = "92007"
        contact2.address = address2
        
        return [contact1, contact2]
    }
}

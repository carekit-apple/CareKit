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

import WatchKit

enum WCKActivityType {
    // Care plan activities of type interventions.
    case intervention
    // Care plan activities of type assessments.
    case assessment
}

class WCKActivity : NSObject {
    
    // MARK: Properties
    
    // Unique identifier string.
    let identifier : String
    // The type of activity.
    let type : WCKActivityType
    // The title of the activity.
    var title : String
    // A descriptive text for the activity.
    var text : String?
    // The tint color for the activity.
    let tintColor : UIColor?
    // The bool: isOptional for the activity.
    let isOptional: Bool?
    // An array of all the events associated with the activity for today.
    var eventsForToday : [WCKEvent?]
    
    
    // MARK: Initialization
    
    init?(interventionWithIdentifier identifier: String,
                                     title: String,
                                     text: String?,
                                     isIntervention: Bool?,
                                     tintColor: UIColor?,
                                     isOptional: Bool?,
                                     numberOfEventsForToday: UInt) {
        self.identifier = identifier
        if isIntervention! {
            self.type = .intervention
        }
        else {
            self.type = .assessment
        }
        self.title = title
        self.text = text
        self.tintColor = tintColor
        self.isOptional = isOptional
        self.eventsForToday = [WCKEvent?](repeating: nil, count: Int(numberOfEventsForToday))
    }
    
    // MARK: Event Querying
    
    func getNumberOfCompletedEvents() -> Int {
        return eventsForToday.map({$0?.state == .completed ? 1 : 0}).reduce(0, +)
    }

}

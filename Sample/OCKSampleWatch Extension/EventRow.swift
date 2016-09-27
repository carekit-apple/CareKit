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

class EventRow : NSObject {
    
    // MARK: Properties
    
    var activityIdentifier : String?
    var tintColor : UIColor?
    var rowIndex : Int?
    var buttons : [WKInterfaceButton] = []
    var displayCompleted = [false, false, false]
    var parentInterfaceController : InterfaceController?
        
    @IBOutlet var leftButton: WKInterfaceButton!
    @IBOutlet var centerButton: WKInterfaceButton!
    @IBOutlet var rightButton: WKInterfaceButton!
    
    
    // MARK: Rendering
    
    func load(fromActivity activity: WCKActivity, withRowIndex rowIndex: Int, parent: InterfaceController) {
        self.activityIdentifier = activity.identifier
        self.tintColor = activity.tintColor
        self.rowIndex = rowIndex
        self.buttons = [leftButton, centerButton, rightButton]
        self.parentInterfaceController = parent
        
        for columnIndex in 0..<3 {
            if 3 * rowIndex + columnIndex < activity.eventsForToday.count {
                buttons[columnIndex].setHidden(false)
                buttons[columnIndex].setBackgroundColor(tintColor)
                
                displayCompleted[columnIndex] = (activity.eventsForToday[3 * rowIndex + columnIndex]!.state == .completed)
                
                buttons[columnIndex].setBackgroundImageNamed(displayCompleted[columnIndex] ? "bubble-fill" : "bubble-empty")
            } else {
                buttons[columnIndex].setHidden(true)
            }
        }
    }
    
    func updateButton(withColumnIndex columnIndex: Int, toState state : WCKEventState) {
        let completed = (state == .completed)
        buttons[columnIndex].setBackgroundImageNamed(completed ? "bubble-fill" : "bubble-empty")
        displayCompleted[columnIndex] = completed
    }
    
    func updateButton(withEventIndex eventIndex : Int, toState state : WCKEventState) {
        updateButton(withColumnIndex: eventIndex - 3 * rowIndex!, toState: state)
    }
    
    // MARK: Handle user inputs
    
    func didSelectButton(withColumnIndex columnIndex : Int) {
        updateButton(withColumnIndex: columnIndex, toState: displayCompleted[columnIndex] ? .notCompleted : .completed)
        parentInterfaceController?.updateDataStoreEvent(withActivityIdentifier: activityIdentifier!, atIndex: 3 * rowIndex! + columnIndex, toCompletedState: displayCompleted[columnIndex])
    }
    
    @IBAction func leftButtonPressed() {
        didSelectButton(withColumnIndex: 0)
    }
    
    @IBAction func centerButtonPressed() {
        didSelectButton(withColumnIndex: 1)
    }
    
    @IBAction func rightButtonPressed() {
        didSelectButton(withColumnIndex: 2)
    }
    
}

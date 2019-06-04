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

import UIKit
import CareKitUI
import CareKitStore

internal class OCKBindableChecklistTaskView<Task: Equatable & OCKTaskConvertible, Outcome: Equatable & OCKOutcomeConvertible>:
OCKChecklistTaskView, OCKBindable {
   
    public typealias Data = [OCKEvent<Task, Outcome>]
    
    private let scheduleFormatter = OCKScheduleFormatter<Task, Outcome>()
   
    public func updateView(with model: Data?, animated: Bool) {
        setupWithTask(model?.first?.task.convert())
        setupWithEvents(model, animated: animated)
    }

    private func setupWithNilTask() {
        headerView.titleLabel.text = nil
        headerView.detailLabel.text = nil
        instructionsLabel.text = nil
    }
    
    private func setupWithEmptyEvents(animated: Bool) {
        clearItems(animated: animated)
        headerView.detailLabel.text = nil
    }
    
    private func setupWithTask(_ task: OCKTask?) {
        guard let task = task else {
            setupWithNilTask()
            return
        }
        
        headerView.titleLabel.text = task.title
        instructionsLabel.text = task.instructions
    }
    
    private func setupWithEvents(_ events: [OCKEvent<Task, Outcome>]?, animated: Bool) {
        guard let events = events, !events.isEmpty else {
            setupWithEmptyEvents(animated: animated)
            return
        }
        
        for (i, event) in events.enumerated() {
            if i < items.count {
                let item = updateItem(at: i, withTitle: event.scheduleEvent.element.text ?? scheduleFormatter.timeLabel(for: event))
                item?.isSelected = event.outcome != nil
            } else {
                let item = appendItem(withTitle: event.scheduleEvent.element.text ?? scheduleFormatter.timeLabel(for: event), animated: animated)
                item.isSelected = event.outcome != nil
            }
        }
        
        // delete any extra button
        var counter = events.count
        while counter < items.count {
            removeItem(at: counter, animated: animated)
            counter += 1
        }
        
        headerView.detailLabel.text = scheduleFormatter.scheduleLabel(for: events)
    }
}

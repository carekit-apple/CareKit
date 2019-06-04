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

internal class OCKBindableSimpleLogTaskView<Task: Equatable & OCKTaskConvertible, Outcome: Equatable & OCKOutcomeConvertible>:
OCKSimpleLogTaskView, OCKBindable {
    
    private let scheduleFormatter = OCKScheduleFormatter<Task, Outcome>()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    public func updateView(with model: OCKEvent<Task, Outcome>?, animated: Bool) {
        guard let model = model else {
            clear(animated: animated)
            return
        }
        
        let event = model.convert()
        headerView.titleLabel.text = event.task.title
        headerView.detailLabel.text = event.scheduleEvent.element.text ?? scheduleFormatter.scheduleLabel(for: model)
        instructionsLabel.text = event.task.instructions
        
        // Sort values by date value
        let values = event.outcome?.values ?? []
        let sortedValues = values.sorted {
            guard let date1 = $0.createdAt, let date2 = $1.createdAt else { return true }
            return date1 < date2
        }
        
        // update the values stack
        if values.isEmpty {
            clearItems(animated: animated)
        } else {
            for (i, value) in sortedValues.enumerated() {
                guard let date = value.createdAt else { break }
                let dateString = timeFormatter.string(from: date).description
                
                if i < items.count {
                    updateItem(at: i, withTitle: OCKStyle.strings.valueLogged, detail: dateString)
                } else {
                    appendItem(withTitle: OCKStyle.strings.valueLogged, detail: dateString, animated: animated)
                }
            }
        }
        
        // delete any extra button
        var counter = values.count
        while counter < items.count {
            removeItem(at: counter, animated: true)
            counter += 1
        }
    }
    
    private func clear(animated: Bool) {
        [headerView.titleLabel, headerView.detailLabel, instructionsLabel].forEach { $0.text = nil }
        clearItems(animated: animated)
    }
}

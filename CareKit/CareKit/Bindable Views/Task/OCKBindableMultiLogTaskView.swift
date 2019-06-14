//
//  OCKBindableMultiLogTaskView.swift
//
//  Created by Pablo Gallastegui on 6/12/19.
//  Copyright © 2019 Red Pixel Studios. All rights reserved.
//

import UIKit
import CareKitUI
import CareKitStore

internal class OCKBindableMultiLogTaskView<Task: Equatable & OCKTaskConvertible, Outcome: Equatable & OCKOutcomeConvertible>:
OCKMultiLogTaskView, OCKBindable {
    
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
                let title = value.stringValue
                
                guard let date = value.createdAt else { break }
                let dateString = timeFormatter.string(from: date).description
                
                if i < items.count {
                    updateItem(at: i, withTitle: title ?? OCKStyle.strings.valueLogged, detail: dateString)
                } else {
                    appendItem(withTitle: title ?? OCKStyle.strings.valueLogged, detail: dateString, animated: animated)
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

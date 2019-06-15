//
//  OCKLogTaskViewController.swift
//
//  Created by Pablo Gallastegui on 6/12/19.
//  Copyright © 2019 Red Pixel Studios. All rights reserved.
//
import UIKit
import CareKitUI
import CareKitStore

/// An abstract superclass to log synchronized view controllers that display an event and its outcomes.
///
/// - Note: `OCKEventViewController`s are created by specifying a task and an event query. If the event query
/// returns more than one event, only the first event will be displayed.
open class OCKLogTaskViewController<Store: OCKStoreProtocol, TaskView: OCKLogTaskView>: OCKEventViewController<Store>, OCKSimpleLogTaskViewDelegate {
    
    /// The custom view to display the task.
    public var taskView: TaskView {
        guard let view = view as? TaskView else { fatalError("Unexpected type") }
        return view
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        taskView.delegate = self
    }
    
    // MARK: OCKSimpleLogTaskViewDelegate
    
    /// This method will be called each time the taps on a logged record. Override this method in a subclass to change the behavior.
    ///
    /// - Parameters:
    ///   - simpleLogView: The view whose button was tapped.
    ///   - button: The button that was tapped.
    ///   - index: The index of the button that was tapped.
    open func logTaskView(_ logTaskView: OCKLogTaskView, didSelectItem button: OCKButton, at index: Int) {
        let logInfo = [button.titleLabel?.text, button.detailLabel?.text]
            .compactMap { $0 }
            .joined(separator: " - ")

        let actionSheet = UIAlertController(title: "Log Entry", message: logInfo, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: OCKStyle.strings.cancel, style: .default, handler: nil)
        
        let delete = UIAlertAction(title: OCKStyle.strings.delete, style: .destructive) { [weak self] (action) in
            guard let self = self else { return }
            
            // Sort values by date value
            let values = self.event?.convert().outcome?.values ?? []
            let sortedValues = values.sorted {
                guard let date1 = $0.createdAt, let date2 = $1.createdAt else { return true }
                return date1 < date2
            }
            
            guard index < sortedValues.count else { return }
            let intValue = sortedValues[index].integerValue
            self.deleteOutcomeValue(intValue)
        }

        [delete, cancel].forEach { actionSheet.addAction($0) }
        present(actionSheet, animated: true, completion: nil)
    }
}

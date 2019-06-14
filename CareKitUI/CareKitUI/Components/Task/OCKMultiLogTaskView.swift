//
//  OCKMultiLogTaskView.swift
//
//  Created by Pablo Gallastegui on 6/12/19.
//  Copyright © 2019 Red Pixel Studios. All rights reserved.
//


import UIKit

/// Protocol for interactions with an `OCKSimpleLogTaskView`.
public protocol OCKMultiLogTaskViewDelegate: OCKLogTaskViewDelegate {
    
    /// Called when a log button was selected.
    ///
    /// - Parameters:
    ///   - multiLogTaskView: The view containing the log item.
    ///   - logButton: The item in the log that was selected.
    ///   - index: The index of the item in the log.
    func multiLogTaskView(_ multiLogTaskView: OCKMultiLogTaskView, didSelectLog logButton: OCKButton, at index: Int)
}

/// A card that displays a header, multi-line label, a log button, and a dynamic vertical stack of logged items.
/// In CareKit, this view is intended to display a particular event for a task. When the log button is presses,
/// a new outcome is created for the event.
///
/// To insert custom views vertically the view, see `contentStack`. To modify the logged items, see
/// `updateItem`, `appendItem`, `insertItem`, `removeItem` and `clearItems`.
///
///     +-------------------------------------------------------+
///     |                                                       |
///     | [title]                                [detail        |
///     | [detail]                               disclosure]    |
///     |                                                       |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     |   [instructions]                                      |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  | [img]  [detail]  [title]                        |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     +-------------------------------------------------------+
///
open class OCKMultiLogTaskView: OCKLogTaskView {
    
    // MARK: Properties
    
    /// Delegate that gets notified of interactions with the `OCKSimpleLogTaskView`.
    public weak var multiLogDelegate: OCKMultiLogTaskViewDelegate?
    
    private let logButtonsStackView: OCKStackView = {
        var stackView = OCKStackView(style: .plain)
        stackView.showsOuterSeparators = false
        return stackView
    }()
    
    /// The button that can be hooked up to modify the list of logged items.
    private var logButtons = [OCKButton]()
    
    // MARK: Life cycle
    
    // MARK: Methods
    
    public func addOptions(_ options: [String]) {
        for option in options {
            let button = OCKLabeledButton()
            button.animatesStateChanges = false
            button.setTitle(option, for: .normal)
            button.handlesSelectionStateAutomatically = false
            button.addTarget(self, action: #selector(logButtonTapped(_:)), for: .touchUpInside)
            
            self.logButtons.append(button)
            logButtonsStackView.addArrangedSubview(button)
        }
    }
    
    override internal func styleSubviews() {
        super.styleSubviews()
        
        logButtonsStackView.distribution = .fillEqually
        logButtonsStackView.spacing = directionalLayoutMargins.leading + directionalLayoutMargins.trailing
    }
    
    override internal func addSubviews() {
        super.addSubviews()
        [headerView, instructionsLabel, logButtonsStackView, logItemsStackView].forEach { contentStackView.addArrangedSubview($0) }
    }
    
    @objc
    private func logButtonTapped(_ sender: OCKButton) {
        guard let index = logButtonsStackView.arrangedSubviews.firstIndex(of: sender) else {
            fatalError("Target was not set up properly.")
        }
        multiLogDelegate?.multiLogTaskView(self, didSelectLog: sender, at: index)
    }
}

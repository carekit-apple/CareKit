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

/// A card that displays a header, multi-line label, multiple log buttons, and a dynamic vertical stack of logged items.
/// In CareKit, this view is intended to display a particular event for a task. When one of the log buttons is pressed,
/// a new outcome is created for the event.
///
/// To insert custom views vertically the view, see `contentStack`. To modify the logged items, see
/// `updateItem`, `appendItem`, `insertItem`, `removeItem` and `clearItems`.
///
///     +---------------------------------------------------------------+
///     |                                                               |
///     | [title]                                        [detail        |
///     | [detail]                                       disclosure]    |
///     |                                                               |
///     |                                                               |
///     |  ----------------------------------------------------------   |
///     |                                                               |
///     |   [instructions]                                              |
///     |                                                               |
///     |  +--------------------------+  +---------------------------+  |
///     |  | [img]  [detail]  [title] |  | [img]  [detail]  [title]  |  |
///     |  +--------------------------+  +---------------------------+  |
///     |                                                               |
///     +---------------------------------------------------------------+
///
open class OCKMultiLogTaskView: OCKLogTaskView {
    
    // MARK: Properties
    
    /// Delegate that gets notified of interactions with the `OCKSimpleLogTaskView`.
    public weak var multiLogDelegate: OCKMultiLogTaskViewDelegate?
    
    /// The horizontal stack view that holds the log buttons.
    private let logButtonsStackView: OCKStackView = {
        var stackView = OCKStackView(style: .plain)
        stackView.showsOuterSeparators = false
        return stackView
    }()
    
    /// The button that can be hooked up to modify the list of logged items.
    private var logButtons = [OCKButton]()
        
    // MARK: Methods
    
    /// Sets the list of Log options to be displayed.
    ///
    /// - Parameters:
    ///   - options: A list of options to be displayed.
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

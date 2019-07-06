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

/// A card that displays an `OCKHeaderView` and a circular checkmark button `completionButton`.
/// In CareKit, this view is intended to display a particular event for a task. The state of the `completionButton`
/// indicates the completion state of the event.
///
/// To insert custom views vertically the view, see `contentStack`
///
///     +-------------------------------------------------------+
///     |                                                       |
///     | [title]                                 [completion   |
///     | [detail]                                 button]      |
///     |                                                       |
///     +-------------------------------------------------------+
///
open class OCKSimpleTaskView: UIView, OCKCardable, OCKCollapsible {
    
    // MARK: Properties
    
    /// The button in the trailing end of the card. Has an image that is defaulted to a checkmark when selected.
    public let completionButton: OCKButton = OCKCircleButton()
    
    /// A default version of an `OCKHeaderView`.
    public let headerView = OCKHeaderView()
    
    internal var shouldCollapse: Bool = true
    
    // MARK: Life cycle
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: Methods
    
    private func setup() {
        addSubviews()
        styleSubviews()
        constrainSubviews()
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        enableCardStyling(true)
    }
    
    private func addSubviews() {
        [headerView, completionButton].forEach { addSubview($0) }
    }
    
    private func constrainSubviews() {
        [headerView, completionButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: directionalLayoutMargins.top * 2),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            headerView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -directionalLayoutMargins.bottom * 2),
            headerView.centerYAnchor.constraint(equalTo: centerYAnchor),

            completionButton.leadingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: directionalLayoutMargins.leading * 2),
            completionButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: directionalLayoutMargins.top * 2),
            completionButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -directionalLayoutMargins.bottom * 2),
            completionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            completionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            completionButton.heightAnchor.constraint(equalToConstant: OCKStyle.dimension.buttonHeight2),
            completionButton.widthAnchor.constraint(equalTo: completionButton.heightAnchor)
        ])
    }

    // MARK: OCKCollapsible
    
    internal func setCollapsedState(_ state: OCKCollapsibleState, animated: Bool) {
        guard shouldCollapse else { return }
        UIView.animate(withDuration: OCKStyle.animation.stateChangeDuration) { [weak self] in
            self?.alpha = state == .expanded ? 1 : OCKStyle.appearance.opacity1
        }
    }
}

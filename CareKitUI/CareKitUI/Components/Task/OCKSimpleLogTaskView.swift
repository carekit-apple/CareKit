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

/// Protocol for interactions with an `OCKSimpleLogTaskView`.
public protocol OCKSimpleLogTaskViewDelegate: OCKLogTaskViewDelegate {
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
open class OCKSimpleLogTaskView: OCKLogTaskView {
    
    // MARK: Properties
    
    /// The button that can be hooked up to modify the list of logged items.
    public let logButton: OCKButton = {
        let button = OCKLabeledButton()
        button.animatesStateChanges = false
        button.setTitle(OCKStyle.strings.log, for: .normal)
        button.handlesSelectionStateAutomatically = false
        return button
    }()
    
    // MARK: Life cycle
    
    // MARK: Methods
    
    override func addSubviews() {
        super.addSubviews()
        [headerView, instructionsLabel, logButton, logItemsStackView].forEach { contentStackView.addArrangedSubview($0) }
    }
}

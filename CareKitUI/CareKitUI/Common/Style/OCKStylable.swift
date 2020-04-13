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

// An object that can be styled.
public protocol OCKStylable {

    /// Used to override the style.
    var customStyle: OCKStyler? { get set }

    /// Returns in order of existence: This object's custom style, the first parent with a custom style, or the default style.
    func style() -> OCKStyler

    /// Called when the style changes.
    func styleDidChange()
}

/// In order to propogate style through the view hierearchy:
/// 1. Call `styleChildren()` from a `didSet` observer on `customStyle`.
/// 2. Call `styleChildren()` from `removeFromSuperView()`.
/// 3. Call `styleDidChange()` from `didMoveToSuperview()`.
public extension OCKStylable where Self: UIView {
    /// Returns in order of existence: This object's custom style, the first parent with a custom style, or the default style.
    func style() -> OCKStyler {
        return customStyle ?? getParentCustomStyle() ?? OCKStyle()
    }

    /// Notify this view and subviews that the style has changed. Guarantees that the outermost view's `styleDidChange` method will be called after
    /// that of inner views.
    func styleChildren() {
        recursiveStyleChildren()
        styleDidChange()
    }
}

private extension UIView {
    // Find the first custom style in the superview hierarchy.
    func getParentCustomStyle() -> OCKStyler? {
        guard let superview = superview else { return nil }

        // if the view has a custom style, return it
        if let typedSuperview = superview as? OCKStylable, let customStyle = typedSuperview.customStyle {
            return customStyle
        }

        // else check if the superview has a custom style
        return superview.getParentCustomStyle()
    }

    // Recursively notify subviews that the style has changed.
    func recursiveStyleChildren() {
        for view in subviews {
            // Propogate style through any `UIView`s
            guard let typedView = view as? OCKStylable & UIView else {
                view.recursiveStyleChildren()
                continue
            }

            // Propogate style to subviews that are not the child of a view that has set a custom style
            if typedView.customStyle == nil {
                typedView.recursiveStyleChildren()
                typedView.styleDidChange()
            }
        }
    }
}

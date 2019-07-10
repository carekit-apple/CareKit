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

/// A checkmark drawing.
internal class OCKCheckmarkImageView: UIImageView {
    // MARK: Properties

    enum PointSize {
        case small, medium, large

        var value: CGFloat {
            switch self {
            case .small: return OCKStyle.dimension.pointSize3
            case .medium: return OCKStyle.dimension.pointSize2
            case .large: return OCKStyle.dimension.pointSize1
            }
        }
    }

    internal enum State {
        case checked, unchecked
    }

    /// The point size of the checkmark image
    internal var pointSize: PointSize {
        didSet { updateSymbolConfiguration() }
    }

    /// Checked status of the checkmark.
    internal private (set) var state: State = .checked

    /// Duration of the animation used to present the checkmark.
    internal var duration: TimeInterval = 1.0

    // MARK: Life Cycle

    /// Create an instance of a checkmark view. The checkmark is checked by default.
    internal init(pointSize: PointSize) {
        self.pointSize = pointSize
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        self.pointSize = .medium
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: Methods

    private func setup() {
        image = UIImage(systemName: "checkmark")
        updateSymbolConfiguration()
    }

    private func updateSymbolConfiguration() {
        image = image?.applyingSymbolConfiguration(.init(pointSize: pointSize.value, weight: .bold))
    }

    /// Set the checked status of the checkmark.
    ///
    /// - Parameters:
    ///   - checked: True if the checkmark is checked and should display. False if it should be hidden.
    ///   - animated: Flag to animate showing/hiding the checkmark.
    internal func setState(_ state: State, animated: Bool) {
        guard state != self.state else { return }
        self.state = state

        let appearanceUpdater = { [weak self] in
            guard let self = self else { return }
            let scale: CGFloat = state == .checked ? 1 : 0.1
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.alpha = state == .checked ? 1 : 0
        }

        guard animated else {
            appearanceUpdater()
            return
        }

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
            appearanceUpdater()
        }, completion: nil)
    }
}

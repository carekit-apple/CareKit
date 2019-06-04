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
internal class OCKCheckmarkView: UIView {
    
    // MARK: Properties
    
    internal enum State {
        case checked, unchecked
    }
    
    /// Line width of the checkmark.
    internal var lineWidth: CGFloat = 10 {
        didSet { checkLayer.lineWidth = lineWidth }
    }
    
    /// Stroke color of the checkmark.
    internal var strokeColor: UIColor = .blue {
        didSet { checkLayer.strokeColor = strokeColor.cgColor }
    }
    
    /// Checked status of the checkmark.
    internal private (set) var state: State = .checked
    
    /// Duration of the animation used to present the checkmark.
    internal var duration: TimeInterval = 1.0
    
    private let checkLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = nil
        layer.lineCap = .round
        layer.lineJoin = .round
        return layer
    }()
    
    // MARK: Life Cycle
    
    /// Create an instance of a checkmark view. The checkmark is checked by default.
    internal init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    internal override func layoutSubviews() {
        super.layoutSubviews()
        checkLayer.frame = bounds
        configureCheck()
    }
    
    // MARK: Methods
    
    private func setup() {
        layer.addSublayer(checkLayer)
        styleCheckLayer()
    }
    
    private func styleCheckLayer() {
        checkLayer.lineWidth = 0
        checkLayer.strokeColor = strokeColor.cgColor
    }
        
    /// Set the checked status of the checkmark.
    ///
    /// - Parameters:
    ///   - checked: True if the checkmark is checked and should display. False if it should be hidden.
    ///   - animated: Flag to animate showing/hiding the checkmark.
    internal func setState(_ state: State, animated: Bool) {
        let oldState = self.state
        self.state = state
        checkLayer.path = state == .checked ? checkPath(in: bounds) : UIBezierPath().cgPath
        
        guard animated else { return }
    
        let shrink = CASpringAnimation(keyPath: #keyPath(CAShapeLayer.path))
        shrink.fromValue = checkLayer.presentation()?.path ?? (oldState == .checked ? checkPath(in: bounds) : checkPath(in: .zero))
        shrink.toValue = checkLayer.path
        shrink.duration = duration
        shrink.isRemovedOnCompletion = true
        shrink.fillMode = .forwards
        
        let thin = CASpringAnimation(keyPath: #keyPath(CAShapeLayer.lineWidth))
        thin.fromValue = checkLayer.presentation()?.lineWidth ?? (oldState == .checked ? lineWidth : 0)
        thin.toValue = state == .checked ? lineWidth : 0
        thin.duration = duration
        thin.isRemovedOnCompletion = true
        thin.fillMode = .forwards
        
        checkLayer.add(shrink, forKey: "shrink")
        checkLayer.add(thin, forKey: "thin")
    }
  
    private func configureCheck() {
        checkLayer.path = state == .checked ? checkPath(in: bounds) : nil
    }
    
    private func checkPath(in frame: CGRect) -> CGPath {
        let dimension = max(0, min(frame.width, frame.height) - lineWidth)
        let xOffset = frame.origin.x + max(0, bounds.width - dimension) / 2
        let yOffset = frame.origin.y + max(0, bounds.height - dimension) / 2
        let bezier = UIBezierPath()
        bezier.move(to: CGPoint(x: xOffset, y: yOffset + dimension / 2))
        bezier.addLine(to: CGPoint(x: xOffset + dimension / 3, y: yOffset + dimension * 0.8))
        bezier.addLine(to: CGPoint(x: xOffset + dimension, y: yOffset + dimension / 8))
        bezier.apply(.init(translationX: 0, y: dimension / 16))
        return bezier.cgPath
    }
}

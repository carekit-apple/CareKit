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

internal class OCKCollapserButton: OCKButton {
    
    // MARK: Properties
    
    internal enum Direction {
        case up, down
    }
    
    private enum Const {
        static let bundle = Bundle(for: OCKCollapserButton.self)
    }
    
    private var direction: Direction = .up
    private let seperatorView = OCKSeparatorView()
    
    override var imageButton: OCKButton? {
        return _imageButton
    }
    
    private let _imageButton: OCKButton = {
        let imageButton = OCKButton()
        imageButton.isUserInteractionEnabled = false
        imageButton.imageView?.contentMode = .scaleAspectFit
        let image = UIImage(named: OCKStyle.assets.arrow, in: Const.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        imageButton.setImage(image, for: .normal)
        imageButton.imageView?.transform = CGAffineTransform.identity.rotated(by: CGFloat.pi)
        imageButton.imageView?.tintColor = .gray
        return imageButton
    }()
    
    // MARK: Life cycle
    
    override internal init() {
        super.init()
        setup()
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Methods
    
    private func setup() {
        styleSubviews()
        addSubviews()
        constrainSubviews()
        setDirection(.up, animated: false)
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
    }
    
    private func addSubviews() {
        [_imageButton, seperatorView].forEach { addSubview($0) }
    }
    
    private func constrainSubviews() {
        [self, _imageButton, seperatorView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: OCKStyle.dimension.buttonHeight2),
            
            _imageButton.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.25),
            _imageButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            _imageButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            seperatorView.topAnchor.constraint(equalTo: topAnchor),
            seperatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    internal func setDirection(_ direction: Direction, animated: Bool) {
        guard self.direction != direction else { return }
        self.direction = direction
        
        let rotationBlock = { [weak self] in
            let angle = direction == .up ? 0 : CGFloat.pi
            self?._imageButton.transform = CGAffineTransform(rotationAngle: angle)
        }
        
        guard animated else {
            rotationBlock()
            return
        }
        
        UIView.animate(withDuration: OCKStyle.animation.stateChangeDuration, animations: rotationBlock)
    }
    
    internal func setDirectionFromState(_ state: OCKCollapsibleState, animated: Bool) {
        guard state != .expanded else { return }
        let direction: Direction = state == .complete ? .down : .up
        setDirection(direction, animated: animated)
    }
}

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

/// A fillable ring with an inner checkmark.
open class OCKCompletionRingView: UIView {
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: OCKStyle.dimension.iconHeight1, height: OCKStyle.dimension.iconHeight1)
    }
    
    /// The fillable ring view.
    internal let ringView = OCKRingView()

    /// The groove in which the fillable ring resides.
    internal let grooveView = OCKRingView()
    
    /// The check view inside of the ring view.
    internal let checkView = OCKCheckmarkView()
    
    private var checkHeightConstraint: NSLayoutConstraint?
    
    /// The progress value of the ring view.
    public var progress: CGFloat {
        return ringView.progress
    }
    
    /// The duration for the ring and check view animations.
    public var duration: TimeInterval {
        get { return ringView.duration }
        set {
            ringView.duration = newValue
            checkView.duration = newValue
        }
    }
    
    /// The line width of the ring and check views.
    public var lineWidth: CGFloat {
        get { return  ringView.lineWidth }
        set {
            grooveView.lineWidth = newValue
            ringView.lineWidth = newValue
            checkView.lineWidth = newValue
        }
    }
    
    /// The stroke clor of the ring and check views.
    public var strokeColor: UIColor = .blue {
        didSet {
            ringView.strokeColor = strokeColor
            checkView.strokeColor = strokeColor
        }
    }
    
    /// Set the progress value for the ring view. The ring will fill accordingly, and if full
    /// the checkmark will display.
    ///
    /// - Parameters:
    ///   - value: The progress value.
    ///   - animated: Flag for the ring and check view animations.
    public func setProgress(_ value: CGFloat, animated: Bool = true) {
        ringView.setProgress(value, animated: animated)
        checkView.setState(value >= 1.0 ? .checked : .unchecked, animated: animated)
    }
    
    /// Create an instance of a completion ring view.
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        checkHeightConstraint?.constant = min(ringView.frame.height, ringView.frame.width) * 0.35
    }
    
    private func setup() {
        grooveView.strokeColor = .lightGray
        grooveView.alpha = 0.25
        grooveView.setProgress(1.0, animated: false)
        
        checkView.strokeColor = strokeColor
        checkView.setState(.unchecked, animated: false)
        
        ringView.strokeColor = strokeColor
        
        addSubview(grooveView)
        addSubview(ringView)
        addSubview(checkView)
        
        grooveView.translatesAutoresizingMaskIntoConstraints = false
        ringView.translatesAutoresizingMaskIntoConstraints = false
        checkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grooveView.leadingAnchor.constraint(equalTo: leadingAnchor),
            grooveView.trailingAnchor.constraint(equalTo: trailingAnchor),
            grooveView.bottomAnchor.constraint(equalTo: bottomAnchor),
            grooveView.topAnchor.constraint(equalTo: topAnchor),
            
            ringView.leadingAnchor.constraint(equalTo: leadingAnchor),
            ringView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ringView.topAnchor.constraint(equalTo: topAnchor),
            ringView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            checkView.centerXAnchor.constraint(equalTo: centerXAnchor),
            checkView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkView.widthAnchor.constraint(equalTo: checkView.heightAnchor)
        ])
        
        checkHeightConstraint = checkView.heightAnchor.constraint(equalToConstant: 0)
        checkHeightConstraint?.isActive = true
    }
}

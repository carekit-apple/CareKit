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

/// Has the ability to display one's self as a card. A card has a particular corner
/// radius and shadow.
public protocol OCKCardable where Self: UIView {}

public extension OCKCardable {
    
    /// Turn the card styling on/off. Note that shadow rastering is set on by default, and
    /// and consequently a shadow cannot be set over a clear background.
    /// - Parameter enabled: true to turn the card styling on.
    func enableCardStyling(_ enabled: Bool) {
        backgroundColor = .white
        layer.masksToBounds = false
        layer.cornerRadius = enabled ? OCKStyle.appearance.cornerRadius2 : 0
        layer.shadowColor = enabled ? OCKStyle.color.cardShadow : UIColor.clear.cgColor
        layer.shadowOffset = OCKStyle.appearance.shadowOffset1
        layer.shadowRadius = enabled ? OCKStyle.appearance.shadowRadius1 : 0
        layer.shadowOpacity = enabled ? OCKStyle.appearance.shadowOpacity1 : 0
        layer.rasterizationScale = enabled ? UIScreen.main.scale : 0
        layer.shouldRasterize = enabled
    }
}

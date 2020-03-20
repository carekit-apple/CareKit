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

/// Defines constants for view appearance styling.
public protocol OCKAppearanceStyler {
    var shadowOpacity1: Float { get }
    var shadowRadius1: CGFloat { get }
    var shadowOffset1: CGSize { get }
    var opacity1: CGFloat { get }
    var lineWidth1: CGFloat { get }

    var cornerRadius1: CGFloat { get }
    var cornerRadius2: CGFloat { get }

    var borderWidth1: CGFloat { get }
    var borderWidth2: CGFloat { get }
}

/// Default appearance values.
public extension OCKAppearanceStyler {
    var shadowOpacity1: Float { 0.15 }
    var shadowRadius1: CGFloat { 8 }
    var shadowOffset1: CGSize { CGSize(width: 0, height: 2) }
    var opacity1: CGFloat { 0.45 }
    var lineWidth1: CGFloat { 4 }

    var cornerRadius1: CGFloat { 15 }
    var cornerRadius2: CGFloat { 12 }

    var borderWidth1: CGFloat { 2 }
    var borderWidth2: CGFloat { 1 }
}

/// Concrete object for appearance constants.
public struct OCKAppearanceStyle: OCKAppearanceStyler {
    public init() {}
}

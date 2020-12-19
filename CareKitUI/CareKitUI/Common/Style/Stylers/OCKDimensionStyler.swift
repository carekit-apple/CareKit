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

/// A configurator that defines constants view sizes.
public protocol OCKDimensionStyler {
    var separatorHeight: CGFloat { get }

    var lineWidth1: CGFloat { get }
    var stackSpacing1: CGFloat { get }

    var imageHeight2: CGFloat { get }
    var imageHeight1: CGFloat { get }

    var pointSize3: CGFloat { get }
    var pointSize2: CGFloat { get }
    var pointSize1: CGFloat { get }

    var buttonHeight3: CGFloat { get }
    var buttonHeight2: CGFloat { get }
    var buttonHeight1: CGFloat { get }

    var symbolPointSize5: CGFloat { get }
    var symbolPointSize4: CGFloat { get }
    var symbolPointSize3: CGFloat { get }
    var symbolPointSize2: CGFloat { get }
    var symbolPointSize1: CGFloat { get }

    var directionalInsets2: NSDirectionalEdgeInsets { get }
    var directionalInsets1: NSDirectionalEdgeInsets { get }
}

/// Default dimension values.
public extension OCKDimensionStyler {
    var separatorHeight: CGFloat { 1.0 / UIScreen.main.scale }

    var lineWidth1: CGFloat { 4 }
    var stackSpacing1: CGFloat { 8 }

    var imageHeight2: CGFloat { 40 }
    var imageHeight1: CGFloat { 150 }

    var pointSize3: CGFloat { 11 }
    var pointSize2: CGFloat { 14 }
    var pointSize1: CGFloat { 17 }

    var buttonHeight3: CGFloat { 20 }
    var buttonHeight2: CGFloat { 50 }
    var buttonHeight1: CGFloat { 60 }

    var symbolPointSize5: CGFloat { 8 }
    var symbolPointSize4: CGFloat { 12 }
    var symbolPointSize3: CGFloat { 16 }
    var symbolPointSize2: CGFloat { 20 }
    var symbolPointSize1: CGFloat { 30 }

    var directionalInsets2: NSDirectionalEdgeInsets { .init(top: 8, leading: 9, bottom: 8, trailing: 8) }
    var directionalInsets1: NSDirectionalEdgeInsets { .init(top: 16, leading: 16, bottom: 16, trailing: 16) }
}

/// Concrete object for cdimesnion constants.
public struct OCKDimensionStyle: OCKDimensionStyler {
    public init() {}
}

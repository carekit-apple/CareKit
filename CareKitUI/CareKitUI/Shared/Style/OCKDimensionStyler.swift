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

/// Defines constants for view dimension styling.
public protocol OCKDimensionStyler {

    #if os(iOS)

    var separatorHeight: CGFloat { get }

    #endif

    var lineWidth1: CGFloat { get }
    var stackSpacing1: CGFloat { get }

    var imageHeight2: CGFloat { get }
    var imageHeight1: CGFloat { get }

    var pointSize3: CGFloat { get }
    var pointSize2: CGFloat { get }
    var pointSize1: CGFloat { get }

    var symbolPointSize5: CGFloat { get }
    var symbolPointSize4: CGFloat { get }
    var symbolPointSize3: CGFloat { get }
    var symbolPointSize2: CGFloat { get }
    var symbolPointSize1: CGFloat { get }

    var directionalInsets2: NSDirectionalEdgeInsets { get }
    var directionalInsets1: NSDirectionalEdgeInsets { get }

    var buttonHeight4: CGFloat { get }
    var buttonHeight3: CGFloat { get }
    var buttonHeight2: CGFloat { get }
    var buttonHeight1: CGFloat { get }
}

/// Default dimension values.
public extension OCKDimensionStyler {

    #if os(iOS)

    var separatorHeight: CGFloat { 1.0 / UIScreen.main.scale }

    #endif

    var lineWidth1: CGFloat { 4 }
    var stackSpacing1: CGFloat { 8 }

    var imageHeight2: CGFloat { 40 }
    var imageHeight1: CGFloat { 150 }

    var pointSize3: CGFloat { 11 }
    var pointSize2: CGFloat { 14 }
    var pointSize1: CGFloat { 17 }

    var symbolPointSize5: CGFloat { 8 }
    var symbolPointSize4: CGFloat { 12 }
    var symbolPointSize3: CGFloat { 16 }
    var symbolPointSize2: CGFloat { 20 }
    var symbolPointSize1: CGFloat { 30 }

    var directionalInsets2: NSDirectionalEdgeInsets {
        OSValue<NSDirectionalEdgeInsets>(values: [.watchOS: .init(value: 4)], defaultValue: .init(value: 8)).wrappedValue
    }

    var directionalInsets1: NSDirectionalEdgeInsets {
        OSValue<NSDirectionalEdgeInsets>(values: [.watchOS: .init(value: 8)], defaultValue: .init(value: 16)).wrappedValue
    }

    var buttonHeight4: CGFloat {
        OSValue<CGFloat>(values: [.watchOS: 10], defaultValue: 20).wrappedValue
    }

    var buttonHeight3: CGFloat {
        OSValue<CGFloat>(values: [.watchOS: 15], defaultValue: 35).wrappedValue
    }

    var buttonHeight2: CGFloat {
        OSValue<CGFloat>(values: [.watchOS: 20], defaultValue: 50).wrappedValue
    }

    var buttonHeight1: CGFloat {
        OSValue<CGFloat>(values: [.watchOS: 30], defaultValue: 60).wrappedValue
    }
}

/// Concrete object for dimension constants.
public struct OCKDimensionStyle: OCKDimensionStyler {
    public init() {}
}

private extension NSDirectionalEdgeInsets {
    init(value: CGFloat) {
        self.init(top: value, leading: value, bottom: value, trailing: value)
    }
}

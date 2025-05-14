/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
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

import Foundation
import SwiftUI

extension ContentSizeCategory {

    var comparable: some Comparable {
        ComparableContentSizeCategory(value: self)
    }
}

/// A wrapper around `ContentSizeCategory` that conforms to `Comparable`. `ContentSizeCategory` conforms
/// to `Comparable` in iOS 14 and above. In order to extend the conformance to iOS 13, we can write custom comparison logic.
/// Note, we choose not to fall back to the iOS 14 `Comparable` implementation so that the logic is consistent across
/// iOS versions.
private struct ComparableContentSizeCategory: Comparable {

    let value: ContentSizeCategory

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.value.sortOrder < rhs.value.sortOrder
    }

    static func > (lhs: Self, rhs: Self) -> Bool {
        return lhs.value.sortOrder > rhs.value.sortOrder
    }

    static func >= (lhs: Self, rhs: Self) -> Bool {
        return lhs.value.sortOrder >= rhs.value.sortOrder
    }

    static func <= (lhs: Self, rhs: Self) -> Bool {
        return lhs.value.sortOrder <= rhs.value.sortOrder
    }
}

private extension ContentSizeCategory {

    var sortOrder: Int {
        switch self {

        case .accessibilityExtraExtraExtraLarge: return 12
        case .accessibilityExtraExtraLarge: return 11
        case .accessibilityExtraLarge: return 10
        case .accessibilityLarge: return 9
        case .accessibilityMedium: return 8

        case .extraExtraExtraLarge: return 7
        case .extraExtraLarge: return 6
        case .extraLarge: return 5
        case .large: return 4
        case .medium: return 3
        case .small: return 2
        case .extraSmall: return 1
            
        @unknown default: return 0
        }
    }
}

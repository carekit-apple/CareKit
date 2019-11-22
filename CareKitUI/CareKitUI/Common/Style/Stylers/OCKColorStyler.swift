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

/// Defines color constants.
public protocol OCKColorStyler {
    var label: UIColor { get }
    var secondaryLabel: UIColor { get }
    var tertiaryLabel: UIColor { get }

    var customBackground: UIColor { get }
    var secondaryCustomBackground: UIColor { get }

    var customGroupedBackground: UIColor { get }
    var secondaryCustomGroupedBackground: UIColor { get }
    var tertiaryCustomGroupedBackground: UIColor { get }

    var separator: UIColor { get }

    var customFill: UIColor { get }
    var secondaryCustomFill: UIColor { get }
    var tertiaryCustomFill: UIColor { get }
    var quaternaryCustomFill: UIColor { get }

    var customBlue: UIColor { get }

    var customGray: UIColor { get }
    var customGray2: UIColor { get }
    var customGray3: UIColor { get }
    var customGray4: UIColor { get }
    var customGray5: UIColor { get }

    var black: UIColor { get }
    var white: UIColor { get }
    var clear: UIColor { get }
}

/// Defines default values for color constants.
public extension OCKColorStyler {
    var label: UIColor { .label }
    var secondaryLabel: UIColor { .secondaryLabel }
    var tertiaryLabel: UIColor { .tertiaryLabel }

    var customBackground: UIColor { .systemBackground }
    var secondaryCustomBackground: UIColor { .secondarySystemBackground }

    var customGroupedBackground: UIColor { .systemGroupedBackground }
    var secondaryCustomGroupedBackground: UIColor { .secondarySystemGroupedBackground }
    var tertiaryCustomGroupedBackground: UIColor { .tertiarySystemGroupedBackground }

    var separator: UIColor { .separator }

    var customFill: UIColor { .tertiarySystemFill }
    var secondaryCustomFill: UIColor { .secondarySystemFill }
    var tertiaryCustomFill: UIColor { .tertiarySystemFill }
    var quaternaryCustomFill: UIColor { .quaternarySystemFill }

    var customBlue: UIColor { .systemBlue }

    var customGray: UIColor { .systemGray }
    var customGray2: UIColor { .systemGray2 }
    var customGray3: UIColor { .systemGray3 }
    var customGray4: UIColor { .systemGray4 }
    var customGray5: UIColor { .systemGray5 }

    var white: UIColor { .white }
    var black: UIColor { .black }
    var clear: UIColor { .clear }
}

/// Concrete object for color constants.
public struct OCKColorStyle: OCKColorStyler {
    public init() {}
}

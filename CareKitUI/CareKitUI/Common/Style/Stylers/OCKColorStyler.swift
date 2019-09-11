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

    var systemBackground: UIColor { get }
    var secondarySystemBackground: UIColor { get }

    var systemGroupedBackground: UIColor { get }
    var secondarySystemGroupedBackground: UIColor { get }
    var tertiarySystemGroupedBackground: UIColor { get }

    var separator: UIColor { get }

    var systemFill: UIColor { get }
    var secondarySystemFill: UIColor { get }
    var tertiarySystemFill: UIColor { get }
    var quaternarySystemFill: UIColor { get }

    var systemBlue: UIColor { get }

    var systemGray: UIColor { get }
    var systemGray2: UIColor { get }
    var systemGray3: UIColor { get }
    var systemGray5: UIColor { get }

    var black: UIColor { get }
    var white: UIColor { get }
    var clear: UIColor { get }
}

/// Defines default values for color constants.
public extension OCKColorStyler {
    var label: UIColor { .label }
    var secondaryLabel: UIColor { .secondaryLabel }
    var tertiaryLabel: UIColor { .tertiaryLabel }

    var systemBackground: UIColor { .systemBackground }
    var secondarySystemBackground: UIColor { .secondarySystemBackground }

    var systemGroupedBackground: UIColor { .systemGroupedBackground }
    var secondarySystemGroupedBackground: UIColor { .secondarySystemGroupedBackground }
    var tertiarySystemGroupedBackground: UIColor { .tertiarySystemGroupedBackground }

    var separator: UIColor { .separator }

    var systemFill: UIColor { .tertiarySystemFill }
    var secondarySystemFill: UIColor { .secondarySystemFill }
    var tertiarySystemFill: UIColor { .tertiarySystemFill }
    var quaternarySystemFill: UIColor { .quaternarySystemFill }

    var systemBlue: UIColor { .systemBlue }

    var systemGray: UIColor { .systemGray }
    var systemGray2: UIColor { .systemGray2 }
    var systemGray3: UIColor { .systemGray3 }
    var systemGray5: UIColor { .systemGray5 }

    var white: UIColor { .white }
    var black: UIColor { .black }
    var clear: UIColor { .clear }
}

/// Concrete object for color constants.
public struct OCKColorStyle: OCKColorStyler {
    public init() {}
}

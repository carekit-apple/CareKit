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
 
 THIS SOFTWARE IS PROVIDED BY THE COP
 YRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
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

/// A hook for the free function `loc` to access the framework bundle for localizations
public class OCKLocalization {

    /// An `NSLocalizedString` wrapper that searches for overrides in a main bundle before falling back to the framework provided strings
    public static func localized(
        _ key: String,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        value: String = "",
        comment: String = ""
    ) -> String {

        // Find a specified or main bundle override for the given `key`
        let str: String = {
            switch bundle {
            case .some(let bundle):
                return NSLocalizedString(
                    key,
                    tableName: tableName,
                    bundle: bundle,
                    value: value,
                    comment: comment
                )
            case .none:
                return NSLocalizedString(
                    key,
                    tableName: tableName,
                    value: value,
                    comment: comment
                )
            }
        }()

        // If the string does not equal the key, there was an override in the main bundle
        guard str == key else { return str }

        // Use this framework's localizable strings if an override is not found
        return NSLocalizedString(
            key,
            tableName: tableName,
            bundle: Bundle(for: OCKLocalization.self),
            value: value,
            comment: comment
        )

    }

}

/// A localization string wrapper to access framework specific strings
/// - Parameter key: The `NSLocalizedString` key
/// - Parameter comment: The `NSLocalizedString` comment
///
/// This is a free function for developer convenience.
public func loc(_ key: String, _ comment: String = "") -> String {

    return OCKLocalization.localized(
        key,
        tableName: nil,
        bundle: nil,
        value: "",
        comment: comment
    )

}

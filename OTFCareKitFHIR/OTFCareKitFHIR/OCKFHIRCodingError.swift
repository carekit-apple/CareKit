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

import Foundation

/// A conversion error represents a problem converting one data format to another.
public enum OCKFHIRCodingError: Error, Equatable {

    /// Indicates that data is corrupt and cannot be read. Malformed JSON is one example.
    case corruptData(String)

    /// Indicates that conversion could not be completed because a required field was missing.
    case missingRequiredField(String)

    /// Indicates that the content encoding is not supported.
    case unsupportedEncoding(String)

    /// Indicates that the content of the source data format type could not be expressed in the target data format.
    case unrepresentableContent(String)

    /// Any other error encountered during conversion between two data formats.
    case unknownError(String)

    func prependMessage(_ message: String) -> OCKFHIRCodingError {
        switch self {
        case .corruptData: return .corruptData(message + " \(localizedDescription)")
        case .missingRequiredField: return .missingRequiredField(message + " \(localizedDescription)")
        case .unsupportedEncoding: return .unsupportedEncoding(message + " \(localizedDescription)")
        case .unrepresentableContent: return .unrepresentableContent(message + " \(localizedDescription)")
        case .unknownError: return .unknownError(message + " \(localizedDescription)")
        }
    }

    public var localizedDescription: String {
        switch self {
        case .corruptData(let problem): return "Corrupt Data: \(problem)"
        case .missingRequiredField(let field): return "Missing required field: \(field)"
        case .unsupportedEncoding(let problem): return "Unsupported encoding: \(problem)"
        case .unrepresentableContent(let problem): return "Unrepresentable content: \(problem)"
        case .unknownError(let problem): return "Uknown error: \(problem)"
        }
    }
}

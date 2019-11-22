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

/// A semantic version with major, minor, and patch version numbers. Semantic versions parsed from strings and compared.
public struct OCKSemanticVersion: Codable, Equatable, Comparable, LosslessStringConvertible {

    /// The major version number, i.e. the *3* in 3.11.2.
    public let majorVersion: Int

    /// The minor version number, i.e. the *11* in 3.11.2.
    public let minorVersion: Int

    /// The patch number, i.e. the *2* in 3.11.2.
    public let patchNumber: Int

    /// The errors that could occur while atttempting to parse a string into an `OCKSemanticVersion`.
    public enum ParsingError: Error {
        case emptyString
        case tooManySeparators
        case invalidMajorVersion
        case invalidMinorVersion
        case invalidPatchVersion
    }

    /// Initialize by specifying the major, minor, and patch versions.
    public init(majorVersion: Int, minorVersion: Int = 0, patchNumber: Int = 0) {
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.patchNumber = patchNumber
    }

    /// Initialize from a string description of the semantic version. This init will fail and return nil if the provided string is
    /// not a valid semantic version.
    public init?(_ description: String) {
        do {
            self = try OCKSemanticVersion.parse(description)
        } catch {
            return nil
        }
    }

    public var description: String { "\(majorVersion).\(minorVersion).\(patchNumber)" }

    public static func < (lhs: OCKSemanticVersion, rhs: OCKSemanticVersion) -> Bool {
        // Major versions are unequal
        if lhs.majorVersion < rhs.majorVersion { return true }
        if lhs.majorVersion > rhs.majorVersion { return false }

        // Major versions are equal, minor versions are unequal
        if lhs.minorVersion < rhs.minorVersion { return true }
        if lhs.minorVersion > rhs.minorVersion { return false }

        // Major and minor versions are equal, patch numbers are unequal
        if lhs.patchNumber < rhs.patchNumber { return true }
        if lhs.patchNumber > rhs.patchNumber { return false }

        // Major, minor, and patch numbers all match
        return false
    }

    /// Parses a string into an `OCKSemanticVersion`. Throws if an error occurs.
    /// - Parameter versionString: A string representing the semantic version, e.g. "3.11.2"
    public static func parse(_ versionString: String) throws -> OCKSemanticVersion {
        guard !versionString.isEmpty else { throw ParsingError.emptyString }
        let parts = versionString.split(separator: ".").map { Int($0) }
        guard parts.count <= 3 else { throw ParsingError.tooManySeparators }

        guard let major = parts[0] else { throw ParsingError.invalidMajorVersion }

        let minor: Int = try {
            guard parts.count > 1 else { return 0 }
            guard let minor = parts[1] else { throw ParsingError.invalidMinorVersion }
            return minor
        }()

        let patch: Int = try {
            guard parts.count > 2 else { return 0 }
            guard let patch = parts[2] else { throw ParsingError.invalidPatchVersion }
            return patch
        }()

        return OCKSemanticVersion(majorVersion: major, minorVersion: minor, patchNumber: patch)
    }
}

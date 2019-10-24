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

import CareKitStore
import Foundation
import XCTest

class TestSemanticVersion: XCTestCase {
    func testCorrectlyParsesMajorVersion() throws {
        let version = try OCKSemanticVersion.parse("3.0.1")
        XCTAssert(version.majorVersion == 3)
    }

    func testCorrectlyParsesMinorVersion() throws {
        let version = try OCKSemanticVersion.parse("3.0.1")
        XCTAssert(version.minorVersion == 0)
    }

    func testCorrectlyParsesPatchVersion() throws {
        let version = try OCKSemanticVersion.parse("3.0.1")
        XCTAssert(version.patchNumber == 1)
    }

    func testCorrectlyParsesImpliedMinorVersion() throws {
        let version = try OCKSemanticVersion.parse("4")
        XCTAssert(version.majorVersion == 4)
        XCTAssert(version.minorVersion == 0)
        XCTAssert(version.patchNumber == 0)
    }

    func testCorrectlyParsesImpliedPatchNumber() throws {
        let version = try OCKSemanticVersion.parse("4.3")
        XCTAssert(version.majorVersion == 4)
        XCTAssert(version.minorVersion == 3)
        XCTAssert(version.patchNumber == 0)
    }

    func testEquatability() {
        let versionA = OCKSemanticVersion(majorVersion: 1, minorVersion: 0, patchNumber: 0)
        let versionB = OCKSemanticVersion(majorVersion: 1, minorVersion: 0, patchNumber: 0)
        let versionC = OCKSemanticVersion(majorVersion: 1, minorVersion: 0, patchNumber: 1)
        XCTAssert(versionA == versionB)
        XCTAssert(versionA != versionC)
    }

    func testComparability() {
        let versionA = OCKSemanticVersion(majorVersion: 1, minorVersion: 1, patchNumber: 1)
        let versionB = OCKSemanticVersion(majorVersion: 1, minorVersion: 1, patchNumber: 1)
        let versionC = OCKSemanticVersion(majorVersion: 1, minorVersion: 10, patchNumber: 1)
        let versionD = OCKSemanticVersion(majorVersion: 2, minorVersion: 1, patchNumber: 1)
        let versionE = OCKSemanticVersion(majorVersion: 2, minorVersion: 1, patchNumber: 2)

        XCTAssertFalse(versionA > versionB)
        XCTAssertFalse(versionA < versionB)

        XCTAssertTrue(versionA >= versionB)
        XCTAssertTrue(versionA <= versionB)

        XCTAssertTrue(versionA < versionC)
        XCTAssertTrue(versionA <= versionC)

        XCTAssertTrue(versionA < versionD)
        XCTAssertTrue(versionA <= versionD)

        XCTAssertTrue(versionD < versionE)
        XCTAssertTrue(versionD <= versionE)
    }

    func testParseThrowsWhenStringIsEmpty() {
        XCTAssertThrowsError(try OCKSemanticVersion.parse(""), "Failed to throw when string is empty") { error in
            XCTAssert(error as? OCKSemanticVersion.ParsingError == .emptyString)
        }
    }
    func testParseThrowsWhenMissingSeparator() {
        XCTAssertThrowsError(try OCKSemanticVersion.parse("puppy"), "Failed to throw when missing separator") { error in
            XCTAssert(error as? OCKSemanticVersion.ParsingError == .invalidMajorVersion)
        }
    }

    func testParseThrowsWhenMajorVersionIsNotAnInt() {
        XCTAssertThrowsError(try OCKSemanticVersion.parse("S.0.1"), "Failed to throw when major version is invalid") { error in
            XCTAssert(error as? OCKSemanticVersion.ParsingError == .invalidMajorVersion)
        }
    }

    func testParseThrowsWhenMinorVersionIsNotAnInt() {
        XCTAssertThrowsError(try OCKSemanticVersion.parse("1.S.1"), "Failed to throw when minor version is invalid") { error in
            XCTAssert(error as? OCKSemanticVersion.ParsingError == .invalidMinorVersion)
        }
    }

    func testParseThrowsWhenPatchVersionIsNotAnInt() {
        XCTAssertThrowsError(try OCKSemanticVersion.parse("1.1.S"), "Failed to throw when patch version is invalid") { error in
            XCTAssert(error as? OCKSemanticVersion.ParsingError == .invalidPatchVersion)
        }
    }

    func testParseThrowsWhenThereAreToManyValues() {
        XCTAssertThrowsError(try OCKSemanticVersion.parse("1.1.1.1"), "Failed to throw when there are too many separators") { error in
            XCTAssert(error as? OCKSemanticVersion.ParsingError == .tooManySeparators)
        }
    }
}

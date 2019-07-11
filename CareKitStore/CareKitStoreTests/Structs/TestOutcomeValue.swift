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

@testable import CareKitStore
import XCTest

class TestOutcomeValue: XCTestCase {
    func testValueInitializer() {
        var value = OCKOutcomeValue(37, units: "˚C")
        XCTAssert(value.type == .integer)
        XCTAssert(value.integerValue == 37)

        value.value = 98.3
        value.units = "˚F"
        XCTAssert(value.type == .double)
        XCTAssert(value.doubleValue == 98.3)
    }

    func testValueEqualityUnique() {
        let beforeAfterValuePairs: [(OCKOutcomeValueUnderlyingType, OCKOutcomeValueUnderlyingType)] = [
            (37, 29),
            (22.3, 24.5),
            (true, false),
            ("dog", "cat"),
            ("old".data(using: .utf8)!, "new".data(using: .utf8)!),
            (Date(), Date().addingTimeInterval(10))
        ]

        for (before, after) in beforeAfterValuePairs {
            let value1 = OCKOutcomeValue(before)
            let value2 = OCKOutcomeValue(after)
            XCTAssert(value1 != value2)
        }
    }

    func testValueEqualityForIdenticalEntries() {
        let date = Date()
        let beforeAfterValuePairs: [(OCKOutcomeValueUnderlyingType, OCKOutcomeValueUnderlyingType)] = [
            (37, 37),
            (22.3, 22.3),
            (true, true),
            ("dog", "dog"),
            ("test".data(using: .utf8)!, "test".data(using: .utf8)!),
            (date, date)
        ]

        for (left, right) in beforeAfterValuePairs {
            let value1 = OCKOutcomeValue(left)
            let value2 = OCKOutcomeValue(right)
            XCTAssert(value1 == value2)
        }
    }

    func testCodingForSingleEntry() {
        let beforeAfterValuePairs: [(OCKOutcomeValueUnderlyingType, OCKOutcomeValueUnderlyingType)] = [
            (37, 29),
            (22.3, 24.5),
            (true, false),
            ("dog", "cat"),
            ("old".data(using: .utf8)!, "new".data(using: .utf8)!),
            (Date(), Date().addingTimeInterval(10))
        ]

        for (before, after) in beforeAfterValuePairs {
            let value1 = OCKOutcomeValue(before)
            let value2 = OCKOutcomeValue(after)
            testPreservationOfCodingHelper(outcome: value1)
            testPreservationOfCodingHelper(outcome: value2)

            testEqualityOfEncodings(outcome1: value1, outcome2: value1)
            testEqualityOfEncodings(outcome1: value2, outcome2: value2)
        }
    }

    func testCodingForIdenticalEntries() {
        let date = Date()
        let beforeAfterValuePairs: [(OCKOutcomeValueUnderlyingType, OCKOutcomeValueUnderlyingType)] = [
            (37, 37),
            (22.3, 22.3),
            (true, true),
            ("dog", "dog"),
            ("test".data(using: .utf8)!, "test".data(using: .utf8)!),
            (date, date)
        ]

        for (left, right) in beforeAfterValuePairs {
            let value1 = OCKOutcomeValue(left)
            let value2 = OCKOutcomeValue(right)
            testEqualityOfEncodings(outcome1: value1, outcome2: value2)
        }
    }

    func testOutcomeValuesThatArentPersistedAreNotAssociatedEvenIfTheyAreEqual() {
        let valueA = OCKOutcomeValue(10.0)
        let valueB = OCKOutcomeValue(10.0)
        XCTAssert(valueA == valueB)
        XCTAssert(!valueA.isAssociated(with: valueB))
    }

    func testOutcomeValuesThatHaveTheSameVersionAreAssociated() {
        var valueA = OCKOutcomeValue(33.0)
        valueA.localDatabaseID = OCKLocalVersionID("abc123")

        var valueB = OCKOutcomeValue(55.0)
        valueB.localDatabaseID = OCKLocalVersionID("abc123")

        XCTAssert(valueA.isAssociated(with: valueB))
    }

    func testEvolvingValue() {
        var value = OCKOutcomeValue("abc")
        let oldType = value.type
        value.value = false
        XCTAssert(oldType != value.type)
        XCTAssert(oldType == .text)
        XCTAssert(value.type == .boolean)

        value.value = Date()
        XCTAssert(value.type == .date)

        value.value = 10.0
        XCTAssert(value.type == .double)

        value.value = Int(10)
        XCTAssert(value.type == .integer)
    }

    func testEqualityOfEncodings(outcome1: OCKOutcomeValue, outcome2: OCKOutcomeValue) {
        let encoder = JSONEncoder()
        do {
            let encoded1 = try encoder.encode(outcome1)
            let encoded2 = try encoder.encode(outcome2)
            XCTAssert(encoded1 == encoded2, "OCKOutcomeValue encoding inequality")
        } catch {
            XCTFail("unable to encoder or decode OCKOutcomeValue")
        }
    }

    func testPreservationOfCodingHelper(outcome: OCKOutcomeValue) {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        do {
            let encoded = try encoder.encode(outcome)
            let decoded = try decoder.decode(OCKOutcomeValue.self, from: encoded)
            XCTAssert(decoded == outcome, "OCKOutcomeValue not preserved in coding")
            testEqualityOfEncodings(outcome1: outcome, outcome2: decoded)
        } catch {
            XCTFail("unable to encode or decode OCKOutcomeValue")
        }
    }
}

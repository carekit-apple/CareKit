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

@testable import CareKitStore
import XCTest

class TestOutcomeValue: XCTestCase {

    func testValueInitializer() {
        var value = OCKOutcomeValue(37, units: "˚C")
        XCTAssertEqual(value.type, .integer)
        XCTAssertEqual(value.integerValue, 37)

        value.value = 98.3
        value.units = "˚F"
        XCTAssertEqual(value.type, .double)
        XCTAssertEqual(value.doubleValue, 98.3)
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
            var value2 = OCKOutcomeValue(after)
            value2.createdDate = value1.createdDate
            XCTAssertNotEqual(value1, value2)
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
            var value2 = OCKOutcomeValue(right)
            value2.createdDate = value1.createdDate
            XCTAssertEqual(value1, value2)
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
            var value2 = OCKOutcomeValue(after)
            value2.createdDate = value1.createdDate

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
            var value2 = OCKOutcomeValue(right)
            value2.createdDate = value1.createdDate
            testEqualityOfEncodings(outcome1: value1, outcome2: value2)
        }
    }

    func testValuesAreEqual() {

        var value1 = OCKOutcomeValue(1, units: "m")
        value1.kind = "length"

        var value2 = OCKOutcomeValue(1, units: "m")
        value2.kind = "length"
        value2.createdDate = value1.createdDate

        XCTAssertEqual(value1, value2)
    }

    func testValuesAreNotEqual() {

        var value1 = OCKOutcomeValue(1, units: "m")
        value1.kind = "length"
        value1.createdDate = Date(timeIntervalSinceReferenceDate: 0)

        var value2 = OCKOutcomeValue(2, units: "in")
        value2.createdDate = Date(timeIntervalSinceReferenceDate: 1)
        XCTAssertNotEqual(value1, value2)

        value2.value = 1
        XCTAssertNotEqual(value1, value2)

        value2.units = "m"
        XCTAssertNotEqual(value1, value2)

        value2.kind = "length"
        XCTAssertNotEqual(value1, value2)

        value2.createdDate = value1.createdDate
        XCTAssertEqual(value1, value2)
    }
    
    func testValuesHashesAreEqual() {
        var value1 = OCKOutcomeValue(1.012, units: "m")
        value1.kind = "length"

        var value2 = OCKOutcomeValue(1.012, units: "m")
        value2.kind = "length"
        value2.createdDate = value1.createdDate

        XCTAssertEqual(value1.hashValue, value2.hashValue)
    }
    
    func testValuesHashesAreUnique() {
        let referenceValue = OCKOutcomeValue(1, units: "m")
        var set: Set<OCKOutcomeValue> = []
        var uniqueElements: Int = 0
        
        var mutableValue = referenceValue
        set.insert(mutableValue)
        uniqueElements += 1
        
        mutableValue.kind = "length"
        set.insert(mutableValue)
        uniqueElements += 1
        
        mutableValue.createdDate = Date(timeIntervalSinceReferenceDate: 0)
        set.insert(mutableValue)
        uniqueElements += 1
     
        mutableValue.value = 2.03
        set.insert(mutableValue)
        uniqueElements += 1
        
        mutableValue.units = "in"
        set.insert(mutableValue)
        uniqueElements += 1
        
        mutableValue.value = Date(timeIntervalSinceReferenceDate: 1)
        set.insert(mutableValue)
        uniqueElements += 1
        
        mutableValue.units = nil
        mutableValue.value = true
        set.insert(mutableValue)
        uniqueElements += 1
        
        mutableValue.value = "some"
        set.insert(mutableValue)
        uniqueElements += 1
        
        mutableValue.value = "some".data(using: .utf8) ?? .init()
        set.insert(mutableValue)
        uniqueElements += 1
        
        XCTAssertEqual(uniqueElements, set.count)
    }

    func testProperDecodingWhenMissingValues() throws {
        let valueToDecode = "{\"value\": 10,\"type\": \"\(OCKOutcomeValueType.integer.rawValue)\",\"createdDate\": 0}"

        guard let data = valueToDecode.data(using: .utf8) else {
            throw OCKStoreError.invalidValue(reason: "Error: Couldn't get data as utf8")
        }

        let decoded = try JSONDecoder().decode(OCKOutcomeValue.self, from: data)

        if let decodedUnderValue = decoded.value as? Int {
            XCTAssertEqual(decodedUnderValue, 10)
        } else {
            XCTFail("Should have underlying value")
        }
    }

    func testCodingAllEntries() throws {
        var value = OCKOutcomeValue(10)

        // Value
        value.kind = "whale"
        value.units = "m/s"
        value.createdDate = Date().addingTimeInterval(-200)

        let encoded = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(OCKOutcomeValue.self, from: encoded)

        XCTAssertEqual(decoded.kind, value.kind)
        XCTAssertEqual(decoded.units, value.units)
        XCTAssertEqual(decoded.createdDate, value.createdDate)

        if let decodedUnderValue = decoded.value as? Int,
            let currentUnderValue = value.value as? Int {
            XCTAssertEqual(decodedUnderValue, currentUnderValue)
        } else {
            XCTFail("Should have underlying value")
        }
    }

    func testEvolvingValue() {
        var value = OCKOutcomeValue("abc")
        let oldType = value.type
        value.value = false
        XCTAssertNotEqual(oldType, value.type)
        XCTAssertEqual(oldType, .text)
        XCTAssertEqual(value.type, .boolean)

        value.value = Date()
        XCTAssertEqual(value.type, .date)

        value.value = 10.0
        XCTAssertEqual(value.type, .double)

        value.value = Int(10)
        XCTAssertEqual(value.type, .integer)
    }

    func testEqualityOfEncodings(outcome1: OCKOutcomeValue, outcome2: OCKOutcomeValue) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        do {
            let encoded1 = try encoder.encode(outcome1)
            let encoded2 = try encoder.encode(outcome2)
            let decoded1 = try XCTUnwrap(String(data: encoded1, encoding: .utf8))
            let decoded2 = try XCTUnwrap(String(data: encoded2, encoding: .utf8))
            XCTAssertEqual(decoded1, decoded2, "OCKOutcomeValue encoding inequality")
        } catch {
            XCTFail("unable to encode or decode OCKOutcomeValue")
        }
    }

    func testPreservationOfCodingHelper(outcome: OCKOutcomeValue) {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        do {
            let encoded = try encoder.encode(outcome)
            let decoded = try decoder.decode(OCKOutcomeValue.self, from: encoded)
            XCTAssertEqual(decoded, outcome, "OCKOutcomeValue not preserved in coding")
            testEqualityOfEncodings(outcome1: outcome, outcome2: decoded)
        } catch {
            XCTFail("unable to encode or decode OCKOutcomeValue")
        }
    }
}

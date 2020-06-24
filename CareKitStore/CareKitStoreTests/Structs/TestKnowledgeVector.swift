/*
 Copyright (c) 2020, Apple Inc. All rights reserved.

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
import Foundation
import XCTest

class TestKnowledgeVector: XCTestCase {

    func testEncoding() throws {
        let id = UIDevice.current.identifierForVendor!
        let vector = OCKRevisionRecord.KnowledgeVector([id: 0])
        let json = try JSONEncoder().encode(vector)
        let string = String(data: json, encoding: .utf8)!
        let expected = "{\"processes\":[{\"id\":\"\(id)\",\"clock\":0}]}"
        XCTAssert(string == expected)
    }

    func testDecoding() throws {
        let id = UIDevice.current.identifierForVendor!
        let json = "{\"processes\":[{\"id\":\"\(id)\",\"clock\":0}]}"
        let data = json.data(using: .utf8)!
        let vector = try JSONDecoder().decode(OCKRevisionRecord.KnowledgeVector.self, from: data)
        XCTAssert(vector == .init([id: 0]))
    }

    func testInitialLogicalTimeForOwnProcess() throws {
        let vect = OCKRevisionRecord.KnowledgeVector()
        let uuid = UIDevice.current.identifierForVendor!
        let time = vect.clock(for: uuid)
        XCTAssert(time == 0)
    }

    func testIncrementProcess() throws {
        let uuid = UUID()
        var vect = OCKRevisionRecord.KnowledgeVector()
        vect.increment(clockFor: uuid)
        vect.increment(clockFor: uuid)
        let time = vect.clock(for: uuid)
        XCTAssert(time == 2)
    }

    func testMergeWithOtherVector() throws {
        let uuid1 = UIDevice.current.identifierForVendor!
        let uuid2 = UUID()
        let uuid3 = UUID()

        var vectorA = OCKRevisionRecord.KnowledgeVector([
            uuid1: 2,
            uuid2: 5,
            uuid3: 0
        ])

        let vectorB = OCKRevisionRecord.KnowledgeVector([
            uuid1: 4,
            uuid2: 3,
            uuid3: 1
        ])

        vectorA.merge(with: vectorB)

        let expected = OCKRevisionRecord.KnowledgeVector([
            uuid1: 4,
            uuid2: 5,
            uuid3: 1
        ])

        XCTAssert(vectorA == expected)
    }

    func testEqualVectorsAreNotLessThan() {
        let vectorA = OCKRevisionRecord.KnowledgeVector([
            UUID(): 2,
            UUID(): 5,
            UUID(): 0
        ])

        let vectorB = vectorA

        XCTAssertFalse(vectorA < vectorB)
        XCTAssertFalse(vectorB < vectorA)
    }

    func testVectorWithJustOneLowerClockIsLessThan() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuid3 = UUID()

        let vectorA = OCKRevisionRecord.KnowledgeVector([
            uuid1: 0,
            uuid2: 2,
            uuid3: 3
        ])

        let vectorB = OCKRevisionRecord.KnowledgeVector([
            uuid1: 1,
            uuid2: 2,
            uuid3: 3
        ])

        XCTAssertTrue(vectorA < vectorB)
        XCTAssertFalse(vectorB < vectorA)
    }
}

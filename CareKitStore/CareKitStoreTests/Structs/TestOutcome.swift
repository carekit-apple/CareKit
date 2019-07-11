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

class TestOutcome: XCTestCase {
    func testMakeOutcome() {
        let index = 0
        let outcome = OCKOutcome(taskID: OCKLocalVersionID(UUID().uuidString), taskOccurenceIndex: index, values: [])
        XCTAssert(outcome.convert() == outcome)
    }

    func testUnpersistedOutcomesAreNotAssociatedEvenIfTheyAreEqual() {
        let outcomeA = OCKOutcome(taskID: OCKLocalVersionID("abc123"), taskOccurenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskID: OCKLocalVersionID("abc123"), taskOccurenceIndex: 0, values: [])
        XCTAssert(outcomeA == outcomeB)
        XCTAssert(!outcomeA.isAssociated(with: outcomeB))
    }

    func testOutcomeWithTheSameTaskVersionAndIndexAreAssociated() {
        var outcomeA = OCKOutcome(taskID: OCKLocalVersionID("abc123"), taskOccurenceIndex: 4, values: [])
        outcomeA.localDatabaseID = OCKLocalVersionID("qwerty")

        var outcomeB = OCKOutcome(taskID: OCKLocalVersionID("abc123"), taskOccurenceIndex: 4, values: [OCKOutcomeValue(10.0)])
        outcomeB.localDatabaseID = OCKLocalVersionID("dvorak")
        XCTAssert(outcomeA.isAssociated(with: outcomeB))
    }

    func testOutcomesWithTheSameLocalDatabaseIDAreAssociated() {
        var outcomeA = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        outcomeA.localDatabaseID = OCKLocalVersionID("abc123")

        var outcomeB = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        outcomeB.localDatabaseID = OCKLocalVersionID("abc123")

        XCTAssert(outcomeA.isAssociated(with: outcomeB))
    }
}

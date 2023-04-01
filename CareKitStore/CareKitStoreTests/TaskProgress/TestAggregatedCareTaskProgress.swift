/*
 Copyright (c) 2023, Apple Inc. All rights reserved.
 
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

final class TestAggregatedCareTaskProgress: XCTestCase {

    private typealias Utils = CareTaskProgressTestUtils

    func testIsCompleted() {

        let p1 = BinaryCareTaskProgress(isCompleted: true)
        let p2 = BinaryCareTaskProgress(isCompleted: true)
        let p3 = LinearCareTaskProgress(value: 1, goal: 1)

        let progress = AggregatedCareTaskProgress(combining: [p1, p2, p3])

        XCTAssertEqual(progress.fractionCompleted, 1, accuracy: .ulpOfOne)
        XCTAssertTrue(progress.isCompleted)
    }

    func testInProgress() {

        let p1 = BinaryCareTaskProgress(isCompleted: false)
        let p2 = BinaryCareTaskProgress(isCompleted: false)
        let p3 = LinearCareTaskProgress(value: 1, goal: 2)

        let progress = AggregatedCareTaskProgress(combining: [p1, p2, p3])

        XCTAssertEqual(progress.fractionCompleted, 1.0 / 6, accuracy: .ulpOfOne)
        XCTAssertFalse(progress.isCompleted)
    }

    func testSubtasks() {

        let p1A = LinearCareTaskProgress(value: 1, goal: 2)
        let p1B = BinaryCareTaskProgress(isCompleted: true)
        let p1 = AggregatedCareTaskProgress(combining: [p1A, p1B])

        let p2 = BinaryCareTaskProgress(isCompleted: true)

        let progress = AggregatedCareTaskProgress(combining: [p1, p2])

        XCTAssertEqual(progress.fractionCompleted, 0.875, accuracy: .ulpOfOne)
        XCTAssertFalse(progress.isCompleted)
    }
}

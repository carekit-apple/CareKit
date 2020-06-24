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

@testable import CareKit
import Combine
import XCTest

class TestSynchronizedContext: XCTestCase {

    var subscription: AnyCancellable?
    var subject: CurrentValueSubject<Int?, Never>!

    override func setUp() {
        super.setUp()
        subject = CurrentValueSubject<Int?, Never>(nil)
    }

    // Old value should be nil, current value should be nil
    func testInitialState() {
        let initialState = XCTestExpectation(description: "Initial state is valid")
        subscription = subject
            .context(currentValue: subject.value, animateIf: { _, _ in false })
            .sink { context in
                XCTAssertNil(context.viewModel)
                XCTAssertNil(context.oldViewModel)
                XCTAssertFalse(context.animated)
                initialState.fulfill()
            }
        wait(for: [initialState], timeout: 2)
    }

    // Old value should be nil, current value should be set
    func testUpdatedOnce() {
        let updatedState = XCTestExpectation(description: "Updated state is valid")
        subscription = subject
            .context(currentValue: subject.value, animateIf: { _, _ in false })
            .dropFirst()
            .sink { context in
                XCTAssertEqual(context.viewModel, 3)
                XCTAssertNil(context.oldViewModel)
                XCTAssertFalse(context.animated)
                updatedState.fulfill()
            }
        subject.value = 3
        wait(for: [updatedState], timeout: 2)
    }

    // Old value should be set, current value should be set
    func testUpdatedTwice() {
        let updatedState = XCTestExpectation(description: "Updated state is valid")
        subscription = subject
            .context(currentValue: subject.value, animateIf: { _, _ in true })
            .dropFirst(2)
            .sink { context in
                XCTAssertEqual(context.viewModel, 4)
                XCTAssertEqual(context.oldViewModel, 3)
                XCTAssertTrue(context.animated)
                updatedState.fulfill()

            }
        subject.value = 3
        subject.value = 4
        wait(for: [updatedState], timeout: 2)
    }
}

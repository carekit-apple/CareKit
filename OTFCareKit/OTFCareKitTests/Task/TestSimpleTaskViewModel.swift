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

@testable import OTFCareKit
import OTFCareKitStore
import OTFCareKitUI
import Combine
import Foundation
import SwiftUI
import XCTest

class TestSimpleTaskViewModel: XCTestCase {

    var controller: OCKSimpleTaskController!
    var cancellable: AnyCancellable?

    override func setUp() {
        super.setUp()
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        controller = .init(storeManager: .init(wrapping: store))
    }

    func testViewModelCreation() {
        let taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        let event = taskEvents.first?.first
        controller.taskEvents = taskEvents

        let updated = expectation(description: "view model updated")
        cancellable = controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertEqual(event?.task.title, viewModel.title)
                XCTAssertEqual(OCKScheduleUtility.scheduleLabel(for: event), viewModel.detail)
                XCTAssertEqual(event?.outcome != nil, viewModel.isComplete)
                updated.fulfill()
            }

        wait(for: [updated], timeout: 1)
    }
}
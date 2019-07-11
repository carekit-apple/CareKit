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
import XCTest

class TestSynchronizedStoreManager: XCTestCase {
    var manager: OCKSynchronizedStoreManager<MockStore>!
    var store: MockStore!

    override func setUp() {
        super.setUp()
        store = MockStore()
        manager = OCKSynchronizedStoreManager(wrapping: store)
    }

    // MARK: Notification Publisher

    func testNotificationPublisherEmitsMultipleEvents() {
        let expect = expectation(description: "Three notifications are published")
        var numberOfNotificationsReceived = 0
        let cancellable = manager.notificationPublisher.sink { _ in
            numberOfNotificationsReceived += 1
            if numberOfNotificationsReceived == 3 {
                expect.fulfill()
            }
        }
        var task = MockTask()
        task.versionID = OCKLocalVersionID("abc123")
        let notification = OCKTaskNotification<MockStore>(storeManager: manager, task: task, category: .delete)
        manager.subject.send(notification)
        manager.subject.send(notification)
        manager.subject.send(notification)
        waitForExpectations(timeout: 1.0)
        cancellable.cancel()
    }
}

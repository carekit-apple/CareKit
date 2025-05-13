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

@testable import CareKit
@testable import CareKitStore
import Foundation
import XCTest

class TestContactExtension: XCTestCase {

    var contact: OCKContact!

    override func setUp() {
        super.setUp()
        contact = OCKContact(
            id: "c1",
            name: PersonNameComponents(),
            carePlanUUID: nil
        )
    }

    func testPhoneCallURL_hasOnlyNumbers() {
        contact.phoneNumbers = [
            OCKLabeledValue(label: "", value: "0000000000")
        ]

        XCTAssertEqual(
            contact.phoneCallURL(),
            URL(string: "tel://0000000000")
        )
    }

    func testPhoneCallURL_hasDashes() {
        contact.phoneNumbers = [
            OCKLabeledValue(label: "", value: "000-000-0000")
        ]

        XCTAssertEqual(
            contact.phoneCallURL(),
            URL(string: "tel://0000000000")
        )
    }

    func testPhoneCallURL_hasLetters() {
        contact.phoneNumbers = [
            OCKLabeledValue(label: "", value: "0000000000A")
        ]

        XCTAssertEqual(
            contact.phoneCallURL(),
            URL(string: "tel://0000000000")
        )
    }

    func testCleanedMessagingNumber_hasOnlyNumbers() {
        contact.messagingNumbers = [
            OCKLabeledValue(label: "", value: "0000000000")
        ]

        XCTAssertEqual(
            contact.cleanedMessagingNumber(),
            "0000000000"
        )
    }

    func testCleanedMessagingNumber_hasDashes() {
        contact.messagingNumbers = [
            OCKLabeledValue(label: "", value: "000-000-0000")
        ]

        XCTAssertEqual(
            contact.cleanedMessagingNumber(),
            "0000000000"
        )
    }

    func testCleanedMessagingNumber_hasLetters() {
        contact.messagingNumbers = [
            OCKLabeledValue(label: "", value: "0000000000A")
        ]

        XCTAssertEqual(
            contact.cleanedMessagingNumber(),
            "0000000000"
        )
    }

    func testGetAddressMapItemWhenAddressIsNil() {

        contact.address = nil

        let didReceiveResult = XCTestExpectation(description: "Received result")

        contact.getAddressMapItem { mapItem in
            XCTAssertNil(mapItem)
            didReceiveResult.fulfill()
        }

        wait(for: [didReceiveResult], timeout: 2)
    }
}

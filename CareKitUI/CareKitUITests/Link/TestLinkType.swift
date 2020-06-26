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

import Foundation

@testable import CareKitUI
import Combine
import Contacts
import CoreLocation
import XCTest

class TestLinkType: XCTestCase {

    private var cancellable: AnyCancellable?

    func testGenericURL() {
        let observed = LinkItem.url(URL(string: "generic-url")!, title: "", symbol: "").url?.absoluteString
        let expected = "generic-url"
        XCTAssertEqual(observed, expected)
    }

    func testWebsiteURL() {
        let observed = LinkItem.website("https://www.apple.com", title: "").url?.absoluteString
        let expected = "https://www.apple.com"
        XCTAssertEqual(observed, expected)
    }

    func testAppStoreURL() {
        let observed = LinkItem.appStore(id: "000", title: "").url?.absoluteString
        let expected = "itms://itunes.apple.com/app/id/000"
        XCTAssertEqual(observed, expected)
    }

    func testCallURL() {
        let observed = LinkItem.call(phoneNumber: "2135558479", title: "").url?.absoluteString
        let expected = "tel:2135558479"
        XCTAssertEqual(observed, expected)
    }

    func testMessageURL() {
        let observed = LinkItem.message(phoneNumber: "2135558479", title: "").url?.absoluteString
        let expected = "sms:2135558479"
        XCTAssertEqual(observed, expected)
    }

    func testEmailURL() {
        let observed = LinkItem.email(recipient: "matthewreiff@icloud.com", title: "").url?.absoluteString
        let expected = "mailto:matthewreiff@icloud.com"
        XCTAssertEqual(observed, expected)
    }

    func testAddressURL() {
        let observed = LinkItem.location("10", "20", title: "").url?.absoluteString
        let expected = "https://maps.apple.com/?ll=10,20"
        XCTAssertEqual(observed, expected)
    }

    func testURLFails() {
        let observed = LinkItem.website(" ", title: "").url
        XCTAssertNil(observed)
    }
}

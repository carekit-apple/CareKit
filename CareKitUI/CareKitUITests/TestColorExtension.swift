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

@testable import CareKitUI
import Foundation
import XCTest


class TestColorExtension: XCTestCase {

    func testLightenEqualChannels() {
        var start = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        var lightened = start.lightened(1)
        XCTAssertEqual(lightened, UIColor(red: 1, green: 1, blue: 1, alpha: 1))

        start = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        lightened = start.lightened(0.5)
        XCTAssertEqual(lightened, UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))

        start = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1)
        lightened = start.lightened(0.5)
        XCTAssertEqual(lightened, UIColor(red: 0.625, green: 0.625, blue: 0.625, alpha: 1))
    }

    func testLightenUnEqualChannels() {
        let start = UIColor(red: 0, green: 0.25, blue: 0.4, alpha: 1)
        let lightened = start.lightened(0.5)
        XCTAssertEqual(lightened, UIColor(red: 0.5, green: 0.625, blue: 0.7, alpha: 1))
    }

    func testClamping() {
          let start = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
          let lightened = start.lightened(10)
          XCTAssertEqual(lightened, UIColor(red: 1, green: 1, blue: 1, alpha: 1))
      }
}


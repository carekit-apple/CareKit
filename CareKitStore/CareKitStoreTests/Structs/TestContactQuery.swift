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
import Foundation
import XCTest

private struct MockQuery: OCKAnyContactQuery {
    var ids: [String] = []
    var remoteIDs: [String] = []
    var groupIdentifiers: [String] = []
    var dateInterval: DateInterval?
    var limit: Int?
    var offset: Int = 0

    var carePlanIDs: [String] = []
    var sortDescriptors: [OCKContactSortDescriptor] = []

    init() {}
}

class TestContactQuery: XCTestCase {

    func testSortOrderSetsExtendedSortOrder() {
        var query = OCKContactQuery()
        query.sortDescriptors = [.givenName(ascending: true)]
        XCTAssert(query.extendedSortDescriptors == [.givenName(ascending: true)])
    }

    func testExtendedSortOrderSetsSortOrder() {
        var query = OCKContactQuery()
        query.extendedSortDescriptors = [.givenName(ascending: true)]
        XCTAssert(query.sortDescriptors == [.givenName(ascending: true)])
    }

    func testInitializerCopiesOtherOCKContactQueryExactly() {
        var query1 = OCKContactQuery()
        query1.extendedSortDescriptors = [.effectiveDate(ascending: true)]
        let query2 = OCKContactQuery(query1)
        XCTAssert(query1 == query2)
    }

    func testInitializerCopiesIDsFromOtherPatientQuery() {
        let query1 = MockQuery(id: "A")
        let query2 = OCKContactQuery(query1)
        XCTAssert(query2.ids == ["A"])
    }

    func testInitializerCopiesSortOrderFromOtherPatientQuery() {
        var query1 = MockQuery()
        query1.sortDescriptors = [.givenName(ascending: true)]
        let query2 = OCKContactQuery(query1)
        XCTAssert(query2.sortDescriptors == [.givenName(ascending: true)])
    }
}

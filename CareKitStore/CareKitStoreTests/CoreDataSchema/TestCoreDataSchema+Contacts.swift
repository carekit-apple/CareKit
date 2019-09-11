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
import Contacts
import XCTest

class TestCoreDataSchemaWithContacts: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "test", type: .inMemory)
    }

    func testCanSaveContact() {
        let contact = OCKCDContact(context: store.context)
        contact.allowsMissingRelationships = true
        contact.identifier = "Katie Abeles"
        contact.title = "Dr. Abeles"
        contact.effectiveDate = Date()
        contact.name = OCKCDPersonName(context: store.context)
        contact.name.givenName = "Katie"
        contact.name.familyName = "Abeles"

        let address = OCKCDPostalAddress(context: store.context)
        address.country = "US"
        address.city = "IN"
        address.street = "311 Sharon Lane"
        address.postalCode = "46601"

        contact.address = address
        contact.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "+1 (574) 555-0164")]
        contact.emailAddresses = [OCKLabeledValue(label: CNLabelHome, value: "kabeles@icloud.com")]
        contact.otherContactInfo = [OCKLabeledValue(label: CNLabelOther, value: "https://en.wikipedia.org/wiki/Dr.Kabeles")]
        contact.organization = "FakeOrg"
        contact.role = "Doctor"
        contact.category = "Health Industry"

        XCTAssertNoThrow(try store.context.save())
        XCTAssert(contact.name.givenName == "Katie")
        XCTAssert(contact.name.familyName == "Abeles")
    }

    func testCannotSaveWithoutCarePlan() {
        let contact = OCKCDContact(context: store.context)
        contact.effectiveDate = Date()
        contact.allowsMissingRelationships = false
        XCTAssertThrowsError(try store.context.save())
    }
}

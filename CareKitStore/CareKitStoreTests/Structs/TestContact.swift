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

class TestContact: XCTestCase {

    func testBelongsToReturnsFalseWhenIDsDontMatch() {
        let plan = OCKCarePlan(id: "A", title: "Medication", patientUUID: nil)
        let contact = OCKContact(id: "B", givenName: "Mary", familyName: "Frost", carePlanUUID: nil)
        XCTAssertFalse(contact.belongs(to: plan))
    }

    func testBelongsToReturnsTrueWhenIDsDoMatach() {
        var plan = OCKCarePlan(id: "A", title: "Medication", patientUUID: nil)
        plan.uuid = UUID()
        let contact = OCKContact(id: "B", givenName: "Mary", familyName: "Frost", carePlanUUID: plan.uuid)
        XCTAssertTrue(contact.belongs(to: plan))
    }

    func testContactSerialzation() throws {
        var contact = OCKContact(id: "jane", givenName: "Jane", familyName: "Daniels", carePlanUUID: nil)
        contact.asset = "JaneDaniels"
        contact.title = "Family Practice Doctor"
        contact.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@icloud.com")]
        contact.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]

        contact.address = {
            let address = OCKPostalAddress()
            address.street = "2598 Reposa Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        XCTAssertNoThrow(try encoder.encode(contact))

        let data = try encoder.encode(contact)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertNoThrow(try JSONDecoder().decode(OCKContact.self, from: json.data(using: .utf8)!))

        let deserialized = try JSONDecoder().decode(OCKContact.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(deserialized, contact)
    }
}

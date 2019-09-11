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
import XCTest

// This test case is for the abstract class `OCKCDVersionedObject`. Since it is an abstract class,
// we test it using a concrete subclass, but the code we're trying to cover is the parent class.
class TestCoreDataSchemaWithVersioning: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "test", type: .inMemory)
    }

    func testVersioning() {
        let patient1 = OCKCDPatient(context: store.context)
        patient1.identifier = "my_id"
        patient1.name = OCKCDPersonName(context: store.context)
        patient1.name.familyName = "Frost1"
        patient1.name.givenName = "Amy"
        patient1.effectiveDate = Date()

        let patient2 = OCKCDPatient(context: store.context)
        patient2.identifier = "my_id"
        patient2.name = OCKCDPersonName(context: store.context)
        patient2.name.familyName = "Foss2"
        patient2.name.givenName = "Christopher"
        patient2.effectiveDate = Date()

        let patient3 = OCKCDPatient(context: store.context)
        patient3.identifier = "my_id"
        patient3.name = OCKCDPersonName(context: store.context)
        patient3.name.familyName = "Gosler3"
        patient3.name.givenName = "Jared"
        patient3.effectiveDate = Date()

        XCTAssert(patient1.previous == nil)
        XCTAssert(patient1.next == nil)

        XCTAssert(patient2.previous == nil)
        XCTAssert(patient2.next == nil)

        XCTAssert(patient3.previous == nil)
        XCTAssert(patient3.next == nil)

        patient3.previous = patient2
        patient2.previous = patient1
        XCTAssertNoThrow(try store.context.save())

        let head = OCKCDPatient.fetchHeads(identifiers: ["my_id"], in: store.context).first
        XCTAssert(head == patient3)
        XCTAssert(head?.next == nil)
        XCTAssert(head?.previous == patient2)
        XCTAssert(head?.previous?.previous == patient1)
        XCTAssert(head?.previous?.previous?.previous == nil)
    }

    func testAddVersionedObectsFailsIfIdentifersArentUnique() {
        let patient1 = OCKPatient(identifier: "my_id", givenName: "John", familyName: "Appleseed")
        let patient2 = OCKPatient(identifier: "my_id", givenName: "Jane", familyName: "Appleseed")
        store.addPatients([patient1, patient2]) { result in
            XCTAssertNil(try? result.get())
        }
    }

    func testUpdateVersionedObjectsFailsIfIdentifiersArentUnique() {
        let patient1 = OCKPatient(identifier: "my_id", givenName: "John", familyName: "Appleseed")
        let patient2 = OCKPatient(identifier: "my_id", givenName: "Jane", familyName: "Appleseed")
        store.updatePatients([patient1, patient2]) { result in
            XCTAssertNil(try? result.get())
        }
    }

    func testSavingUserInfo() throws {
        let patient = OCKCDPatient(context: store.context)
        patient.identifier = "my_id"
        patient.name = OCKCDPersonName(context: store.context)
        patient.name.nickname = "Wiggle Bogey"
        patient.userInfo = ["name": "Wiggle Bogey"]
        patient.effectiveDate = Date()
        XCTAssertNoThrow(try store.context.save())

        guard let fetchedPatient = try store.context.existingObject(with: patient.objectID) as? OCKCDPatient else { XCTFail("Bad type"); return }
        XCTAssert(fetchedPatient.userInfo?["name"] == "Wiggle Bogey")
    }

    func testSchemaVersionIsAutomaticallyAttached() {
        let patient = OCKCDPatient(context: store.context)
        patient.identifier = "my_id"
        patient.name = OCKCDPersonName(context: store.context)
        patient.name.familyName = "Frost1"
        patient.name.givenName = "Amy"
        patient.effectiveDate = Date()

        XCTAssertNoThrow(try store.context.save())
        XCTAssertNotNil(patient.schemaVersion)
    }
}

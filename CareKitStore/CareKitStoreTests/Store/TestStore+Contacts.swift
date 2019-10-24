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

class TestStoreContacts: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "TestDatabase", type: .inMemory)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    // MARK: Relationship Validation

    func testStoreAllowsMissingCarePlanRelationshipOnContacts() {
        let contact = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        XCTAssertNoThrow(try store.addContactAndWait(contact))
    }

    func testStorePreventsMissingCarePlanRelationshipOnContacts() {
        let contact = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        store.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addContactAndWait(contact))
    }

    // MARK: Insertion

    func testAddContact() throws {
        var contact = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        let address = OCKPostalAddress()
        address.state = "CO"
        address.country = "US"
        address.street = "4693 Sweetwood Drive"
        contact.address = address
        contact.messagingNumbers = [OCKLabeledValue(label: "iPhone", value: "303-555-0194")]
        contact.phoneNumbers = [OCKLabeledValue(label: "Home", value: "303-555-0108")]
        contact.emailAddresses = [OCKLabeledValue(label: "Email", value: "amy_frost44@icloud.com")]
        contact.otherContactInfo = [OCKLabeledValue(label: "Facetime", value: "303-555-0121")]
        contact.organization = "Apple Dumplings Corp."
        contact.title = "Manager of Apple Peeling"
        contact.role = "Official Taste Tester"

        contact = try store.addContactAndWait(contact)
        let fetchedConctacts = try store.fetchContactsAndWait()
        XCTAssert([contact] == fetchedConctacts)
        XCTAssert(contact.address?.state == "CO")
        XCTAssert(contact.address?.country == "US")
        XCTAssert(contact.address?.street == "4693 Sweetwood Drive")
        XCTAssert(contact.messagingNumbers == [OCKLabeledValue(label: "iPhone", value: "303-555-0194")])
        XCTAssert(contact.phoneNumbers == [OCKLabeledValue(label: "Home", value: "303-555-0108")])
        XCTAssert(contact.emailAddresses == [OCKLabeledValue(label: "Email", value: "amy_frost44@icloud.com")])
        XCTAssert(contact.otherContactInfo == [OCKLabeledValue(label: "Facetime", value: "303-555-0121")])
        XCTAssert(contact.organization == "Apple Dumplings Corp.")
        XCTAssert(contact.title == "Manager of Apple Peeling")
        XCTAssert(contact.role == "Official Taste Tester")
        XCTAssertNotNil(contact.schemaVersion)
    }

    func testAddContactFailsIfIdentifierAlreadyExists() throws {
        let contact1 = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        let contact2 = OCKContact(identifier: "contact", givenName: "Jared", familyName: "Gosler", carePlanID: nil)
        try store.addContactAndWait(contact1)
        XCTAssertThrowsError(try store.addContactAndWait(contact2))
    }

    // MARK: Querying

    func testQueryContactsByIdentifier() throws {
        let contact1 = try store.addContactAndWait(OCKContact(identifier: "contact1", givenName: "Amy", familyName: "Frost", carePlanID: nil))
        try store.addContactAndWait(OCKContact(identifier: "contact2", givenName: "Amy", familyName: "Frost", carePlanID: nil))
        let fetchedContacts = try store.fetchContactsAndWait(.contactIdentifier(["contact1"]))
        XCTAssert(fetchedContacts == [contact1])
    }

    func testQueryContactsByCarePlanID() throws {
        let carePlan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "cp", title: "Care Plan", patientID: nil))
        guard let carePlanVersionID = carePlan.versionID else { XCTFail("Care Plan was missing a version identifier"); return }
        try store.addContactAndWait(OCKContact(identifier: "care plan 1", givenName: "Mark", familyName: "Brown", carePlanID: nil))
        var contact = OCKContact(identifier: "care plan 2", givenName: "Amy", familyName: "Frost", carePlanID: carePlanVersionID)
        contact = try store.addContactAndWait(contact)
        let fetchedContacts = try store.fetchContactsAndWait(.contactIdentifier([contact.identifier]))
        XCTAssert(fetchedContacts == [contact])
    }

    func testContactsQueryGroupIdentifiers() throws {
        var contactA = OCKContact(identifier: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        contactA.groupIdentifier = "Alpha"
        var contactB = OCKContact(identifier: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        contactB.groupIdentifier = "Beta"
        try store.addContactsAndWait([contactA, contactB])
        var query = OCKContactQuery(for: Date())
        query.groupIdentifiers = ["Alpha"]
        let fetched = try store.fetchContactsAndWait(nil, query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.groupIdentifier == "Alpha")
    }

    func testContactQueryTags() throws {
        var contactA = OCKContact(identifier: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        contactA.tags = ["A"]
        var contactB = OCKContact(identifier: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        contactB.tags = ["B", "C"]
        var contactC = OCKContact(identifier: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        contactC.tags = ["C"]
        try store.addContactsAndWait([contactA, contactB, contactC])
        var query = OCKContactQuery(for: Date())
        query.tags = ["C"]
        let fetched = try store.fetchContactsAndWait(nil, query: query)
        XCTAssert(fetched.map { $0.identifier }.sorted() == ["B", "C"])
    }

    func testContactQueryLimited() throws {
        let contactA = OCKContact(identifier: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        let contactB = OCKContact(identifier: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        let contactC = OCKContact(identifier: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        try store.addContactsAndWait([contactA, contactB, contactC])
        var query = OCKContactQuery(for: Date())
        query.limit = 2
        let fetched = try store.fetchContactsAndWait(nil, query: query)
        XCTAssert(fetched.count == 2)
    }

    func testContactQueryOffset() throws {
        let contactA = OCKContact(identifier: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        let contactB = OCKContact(identifier: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        let contactC = OCKContact(identifier: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        try store.addContactsAndWait([contactA, contactB, contactC])
        var query = OCKContactQuery(for: Date())
        query.offset = 2
        let fetched = try store.fetchContactsAndWait(nil, query: query)
        XCTAssert(fetched.count == 1)
    }

    func testContactQuerySorted() throws {
        let contactA = OCKContact(identifier: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        let contactB = OCKContact(identifier: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        let contactC = OCKContact(identifier: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        try store.addContactsAndWait([contactA, contactB, contactC])
        var query = OCKContactQuery(for: Date())
        query.sortDescriptors = [.givenName(ascending: true)]
        let fetched = try store.fetchContactsAndWait(nil, query: query)
        XCTAssert(fetched.map { $0.name.givenName } == ["a", "b", "c"])
    }

    func testContactNilQueryReturnsAllContacts() throws {
        let contactA = OCKContact(identifier: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        let contactB = OCKContact(identifier: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        let contactC = OCKContact(identifier: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        try store.addContactsAndWait([contactA, contactB, contactC])
        let contacts = try store.fetchContactsAndWait(nil, query: nil)
        XCTAssertNotNil(contacts.count == 3)
    }

    func testQueryContactByRemoteID() throws {
        var contact = OCKContact(identifier: "A", givenName: "B", familyName: "C", carePlanID: nil)
        contact.remoteID = "abc"
        contact = try store.addContactAndWait(contact)

        let fetched = try store.fetchContactsAndWait(.contactRemoteIDs(["abc"]), query: .today).first
        XCTAssert(fetched == contact)
    }

    func testQueryContactByCarePlanRemoteID() throws {
        var plan = OCKCarePlan(identifier: "D", title: "", patientID: nil)
        plan.remoteID = "abc"
        plan = try store.addCarePlanAndWait(plan)

        var contact = OCKContact(identifier: "A", givenName: "B", familyName: "C", carePlanID: plan.versionID)
        contact = try store.addContactAndWait(contact)

        let fetched = try store.fetchContactsAndWait(.carePlanRemoteIDs(["abc"]), query: .today).first
        XCTAssert(fetched == contact)
    }

    func testQueryContactByCarePlanVersionID() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "A", title: "B", patientID: nil))
        guard let planID = plan.versionID else { XCTFail("Failed to save CarePlan"); return }
        let contact = try store.addContactAndWait(OCKContact(identifier: "C", givenName: "D", familyName: "E", carePlanID: planID))
        let fetched = try store.fetchContactsAndWait(.carePlanVersions([planID]), query: .today).first
        XCTAssert(fetched == contact)
    }

    // MARK: Versioning

    func testUpdateContactCreatesNewVersion() throws {
        let contact = try store.addContactAndWait(OCKContact(identifier: "contact", givenName: "John", familyName: "Appleseed", carePlanID: nil))
        let updated = try store.updateContactAndWait(OCKContact(identifier: "contact", givenName: "Jane", familyName: "Appleseed", carePlanID: nil))
        XCTAssert(updated.name.givenName == "Jane")
        XCTAssert(updated.versionID != contact.versionID)
        XCTAssert(updated.previousVersionID == contact.versionID)
    }

    func testUpdateContactsWithoutVersioning() throws {
        store.configuration.updatesCreateNewVersions = false
        var contact = try store.addContactAndWait(OCKContact(identifier: "contact", givenName: "John", familyName: "Appleseed", carePlanID: nil))
        contact.name.givenName = "Jane"
        let updated = try store.updateContactAndWait(contact)
        XCTAssert(updated.name.givenName == "Jane")
        XCTAssert(updated.versionID == contact.versionID)
    }

    func testUpdateFailsForUnsavedContacts() {
        let patient = OCKContact(identifier: "careplan", givenName: "John", familyName: "Appleseed", carePlanID: nil)
        XCTAssertThrowsError(try store.updateContactAndWait(patient))
    }

    func testContactQueryOnlyReturnsLatestVersionOfAContact() throws {
        let versionA = try store.addContactAndWait(OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil))
        let versionB = try store.updateContactAndWait(OCKContact(identifier: "contact", givenName: "Mariana", familyName: "Lin", carePlanID: nil))
        let fetched = try store.fetchContactAndWait(identifier: versionA.identifier)
        XCTAssert(fetched?.identifier == versionB.identifier)
        XCTAssert(fetched?.name == versionB.name)
    }

    func testContactQueryOnPastDateReturnsPastVersionOfAContact() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKContact(identifier: "A", givenName: "a", familyName: "b", carePlanID: nil)
        versionA.effectiveDate = dateA
        versionA = try store.addContactAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKContact(identifier: "A", givenName: "a", familyName: "c", carePlanID: nil)
        versionB.effectiveDate = dateB
        versionB = try store.updateContactAndWait(versionB)

        let query = OCKContactQuery(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let fetched = try store.fetchContactsAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.name == versionA.name)
    }

    func testContactQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKContact(identifier: "A", givenName: "a", familyName: "b", carePlanID: nil)
        versionA.effectiveDate = dateA
        versionA = try store.addContactAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKContact(identifier: "A", givenName: "a", familyName: "c", carePlanID: nil)
        versionB.effectiveDate = dateB
        versionB = try store.updateContactAndWait(versionB)

        let query = OCKContactQuery(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let fetched = try store.fetchContactsAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.name == versionB.name)
    }

    func testContactQueryBeforeContactWasCreatedReturnsNoResults() throws {
        let dateA = Date()
        try store.addContactAndWait(OCKContact(identifier: "A", givenName: "a", familyName: "b", carePlanID: nil))
        let query = OCKContactQuery(start: dateA.addingTimeInterval(-100), end: dateA)
        let fetched = try store.fetchContactsAndWait(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: Deletion

    func testDeleteContact() throws {
        let contact = try store.addContactAndWait(OCKContact(identifier: "contact", givenName: "Christopher", familyName: "Foss", carePlanID: nil))
        try store.deleteContactAndWait(contact)
        let fetched = try store.fetchContactsAndWait()
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteContactfailsIfContactDoesntExist() {
        let contact = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        XCTAssertThrowsError(try store.deleteContactAndWait(contact))
    }
}

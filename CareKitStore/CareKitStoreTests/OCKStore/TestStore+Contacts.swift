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

@testable import CareKitStore
import XCTest

class TestStoreContacts: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: UUID().uuidString, type: .inMemory)
    }
    
    // MARK: Insertion

    func testAddContact() async throws {

        var contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)

        contact.address = OCKPostalAddress(
            street: "4693 Sweetwood Drive",
            city: "San Francisco",
            state: "CO",
            postalCode: "",
            country: "US"
        )

        contact.messagingNumbers = [OCKLabeledValue(label: "iPhone", value: "303-555-0194")]
        contact.phoneNumbers = [OCKLabeledValue(label: "Home", value: "303-555-0108")]
        contact.emailAddresses = [OCKLabeledValue(label: "Email", value: "amy_frost44@icloud.com")]
        contact.otherContactInfo = [OCKLabeledValue(label: "Facetime", value: "303-555-0121")]
        contact.organization = "Apple Dumplings Corp."
        contact.title = "Manager of Apple Peeling"
        contact.role = "Official Taste Tester"

        contact = try await store.addContact(contact)
        let fetchedConctacts = try await store.fetchContacts(query: OCKContactQuery())
        XCTAssertEqual([contact], fetchedConctacts)
        XCTAssertEqual(contact.address?.state, "CO")
        XCTAssertEqual(contact.address?.country, "US")
        XCTAssertEqual(contact.address?.street, "4693 Sweetwood Drive")
        XCTAssertEqual(contact.messagingNumbers, [OCKLabeledValue(label: "iPhone", value: "303-555-0194")])
        XCTAssertEqual(contact.phoneNumbers, [OCKLabeledValue(label: "Home", value: "303-555-0108")])
        XCTAssertEqual(contact.emailAddresses, [OCKLabeledValue(label: "Email", value: "amy_frost44@icloud.com")])
        XCTAssertEqual(contact.otherContactInfo, [OCKLabeledValue(label: "Facetime", value: "303-555-0121")])
        XCTAssertEqual(contact.organization, "Apple Dumplings Corp.")
        XCTAssertEqual(contact.title, "Manager of Apple Peeling")
        XCTAssertEqual(contact.role, "Official Taste Tester")
        XCTAssertNotNil(contact.schemaVersion)
        XCTAssertNotNil(contact.uuid)
    }

    func testAddContactFailsIfIdentifierAlreadyExists() async throws {
        let contact1 = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        let contact2 = OCKContact(id: "contact", givenName: "Jared", familyName: "Gosler", carePlanUUID: nil)
        try await store.addContact(contact1)

        do {
            try await store.addContact(contact2)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    // MARK: Querying

    func testQueryContactsByIdentifier() async throws {
        let contact1 = try await store.addContact(OCKContact(id: "contact1", givenName: "Amy", familyName: "Frost", carePlanUUID: nil))
        try await store.addContact(OCKContact(id: "contact2", givenName: "Amy", familyName: "Frost", carePlanUUID: nil))
        let fetchedContacts = try await store.fetchContacts(query: OCKContactQuery(id: "contact1"))
        XCTAssertEqual(fetchedContacts, [contact1])
    }

    func testQueryContactsByCarePlanID() async throws {
        let carePlan = try await store.addCarePlan(OCKCarePlan(id: "B", title: "Care Plan A", patientUUID: nil))
        try await store.addContact(OCKContact(id: "care plan 1", givenName: "Mark", familyName: "Brown", carePlanUUID: nil))
        var contact = OCKContact(id: "care plan 2", givenName: "Amy", familyName: "Frost", carePlanUUID: carePlan.uuid)
        contact = try await store.addContact(contact)
        var query = OCKContactQuery()
        query.carePlanIDs = [carePlan.id]
        let fetchedContacts = try await store.fetchContacts(query: query)
        XCTAssertEqual(fetchedContacts, [contact])
    }

    func testContactsQueryGroupIdentifiers() async throws {
        var contactA = OCKContact(id: "A", givenName: "a", familyName: "aaa", carePlanUUID: nil)
        contactA.groupIdentifier = "Alpha"
        var contactB = OCKContact(id: "B", givenName: "b", familyName: "bbb", carePlanUUID: nil)
        contactB.groupIdentifier = "Beta"
        try await store.addContacts([contactA, contactB])
        var query = OCKContactQuery(for: Date())
        query.groupIdentifiers = ["Alpha"]
        let fetched = try await store.fetchContacts(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.groupIdentifier, "Alpha")
    }

    func testContactQueryTags() async throws {
        var contactA = OCKContact(id: "A", givenName: "a", familyName: "aaa", carePlanUUID: nil)
        contactA.tags = ["A"]
        var contactB = OCKContact(id: "B", givenName: "b", familyName: "bbb", carePlanUUID: nil)
        contactB.tags = ["B", "C"]
        var contactC = OCKContact(id: "C", givenName: "c", familyName: "cccc", carePlanUUID: nil)
        contactC.tags = ["C"]
        try await store.addContacts([contactA, contactB, contactC])
        var query = OCKContactQuery(for: Date())
        query.tags = ["C"]
        let fetched = try await store.fetchContacts(query: query)
        XCTAssertEqual(fetched.map { $0.id }.sorted(), ["B", "C"])
    }

    func testContactQueryLimited() async throws {
        let contactA = OCKContact(id: "A", givenName: "a", familyName: "aaa", carePlanUUID: nil)
        let contactB = OCKContact(id: "B", givenName: "b", familyName: "bbb", carePlanUUID: nil)
        let contactC = OCKContact(id: "C", givenName: "c", familyName: "cccc", carePlanUUID: nil)
        try await store.addContacts([contactA, contactB, contactC])
        var query = OCKContactQuery(for: Date())
        query.limit = 2
        let fetched = try await store.fetchContacts(query: query)
        XCTAssertEqual(fetched.count, 2)
    }

    func testContactQueryOffset() async throws {
        let contactA = OCKContact(id: "A", givenName: "a", familyName: "aaa", carePlanUUID: nil)
        let contactB = OCKContact(id: "B", givenName: "b", familyName: "bbb", carePlanUUID: nil)
        let contactC = OCKContact(id: "C", givenName: "c", familyName: "cccc", carePlanUUID: nil)
        try await store.addContacts([contactA, contactB, contactC])
        var query = OCKContactQuery(for: Date())
        query.offset = 2
        let fetched = try await store.fetchContacts(query: query)
        XCTAssertEqual(fetched.count, 1)
    }

    func testContactQuerySorted() async throws {
        let contactA = OCKContact(id: "A", givenName: "a", familyName: "aaa", carePlanUUID: nil)
        let contactB = OCKContact(id: "B", givenName: "b", familyName: "bbb", carePlanUUID: nil)
        let contactC = OCKContact(id: "C", givenName: "c", familyName: "cccc", carePlanUUID: nil)
        try await store.addContacts([contactA, contactB, contactC])
        var query = OCKContactQuery(for: Date())
        query.sortDescriptors = [.givenName(ascending: true)]
        let fetched = try await store.fetchContacts(query: query)
        XCTAssertEqual(fetched.map { $0.name.givenName }, ["a", "b", "c"])
    }

    func testContactNilQueryReturnsAllContacts() async throws {
        let contactA = OCKContact(id: "A", givenName: "a", familyName: "aaa", carePlanUUID: nil)
        let contactB = OCKContact(id: "B", givenName: "b", familyName: "bbb", carePlanUUID: nil)
        let contactC = OCKContact(id: "C", givenName: "c", familyName: "cccc", carePlanUUID: nil)
        try await store.addContacts([contactA, contactB, contactC])
        let contacts = try await store.fetchContacts(query: OCKContactQuery())
        XCTAssertEqual(contacts.count, 3)
    }

    func testQueryContactByRemoteID() async throws {
        var contact = OCKContact(id: "A", givenName: "B", familyName: "C", carePlanUUID: nil)
        contact.remoteID = "abc"
        contact = try await store.addContact(contact)
        var query = OCKContactQuery()
        query.remoteIDs = ["abc"]
        let fetched = try await store.fetchContacts(query: query).first
        XCTAssertEqual(fetched, contact)
    }

    func testQueryContactByCarePlanRemoteID() async throws {
        var plan = OCKCarePlan(id: "D", title: "", patientUUID: nil)
        plan.remoteID = "abc"
        plan = try await store.addCarePlan(plan)

        var contact = OCKContact(id: "A", givenName: "B", familyName: "C", carePlanUUID: plan.uuid)
        contact = try await store.addContact(contact)
        var query = OCKContactQuery(for: Date())
        query.carePlanRemoteIDs = ["abc"]
        let fetched = try await store.fetchContacts(query: query).first
        XCTAssertEqual(fetched, contact)
    }

    func testQueryContactByCarePlanVersionID() async throws {
        let plan = try await store.addCarePlan(OCKCarePlan(id: "A", title: "B", patientUUID: nil))
        let contact = try await store.addContact(OCKContact(id: "C", givenName: "D", familyName: "E", carePlanUUID: plan.uuid))
        var query = OCKContactQuery(for: Date())
        query.carePlanUUIDs = [plan.uuid]
        let fetched = try await store.fetchContacts(query: query).first
        XCTAssertEqual(fetched, contact)
    }

    func testQueryContactByUUID() async throws {
        var contact = OCKContact(id: "A", givenName: "B", familyName: "C", carePlanUUID: nil)
        contact = try await store.addContact(contact)
        var query = OCKContactQuery()
        query.uuids = [contact.uuid]
        let fetched = try await store.fetchContacts(query: query).first
        XCTAssertEqual(fetched, contact)
    }

    // MARK: Versioning

    func testUpdateContactCreatesNewVersion() async throws {
        let contact = try await store.addContact(OCKContact(id: "contact", givenName: "John", familyName: "Appleseed", carePlanUUID: nil))
        let updated = try await store.updateContact(OCKContact(id: "contact", givenName: "Jane", familyName: "Appleseed", carePlanUUID: nil))
        XCTAssertEqual(updated.name.givenName, "Jane")
        XCTAssertNotEqual(updated.uuid, contact.uuid)
        XCTAssertEqual(updated.previousVersionUUIDs.first, contact.uuid)
    }

    func testUpdateFailsForUnsavedContacts() async {
        let patient = OCKContact(id: "careplan", givenName: "John", familyName: "Appleseed", carePlanUUID: nil)

        do {
            try await store.updateContact(patient)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }

    func testContactQueryByIDOnlyReturnsLatestVersionOfAContact() async throws {
        try await store.addContact(OCKContact(id: "contact", givenName: "A", familyName: "", carePlanUUID: nil))
        try await store.updateContact(OCKContact(id: "contact", givenName: "B", familyName: "", carePlanUUID: nil))
        try await store.updateContact(OCKContact(id: "contact", givenName: "C", familyName: "", carePlanUUID: nil))
        let versionD = try await store.updateContact(OCKContact(id: "contact", givenName: "D", familyName: "", carePlanUUID: nil))
        let fetched = try await store.fetchContact(withID: "contact")
        XCTAssertEqual(fetched.id, versionD.id)
        XCTAssertEqual(fetched.name, versionD.name)
    }

    func testContactQueryWithDateOnlyReturnsLatestVersionOfAContact() async throws {
        try await store.addContact(OCKContact(id: "contact", givenName: "A", familyName: "", carePlanUUID: nil))
        try await store.updateContact(OCKContact(id: "contact", givenName: "B", familyName: "", carePlanUUID: nil))
        try await store.updateContact(OCKContact(id: "contact", givenName: "C", familyName: "", carePlanUUID: nil))
        try await store.updateContact(OCKContact(id: "contact", givenName: "D", familyName: "", carePlanUUID: nil))
        let fetched = try await store.fetchContacts(query: OCKContactQuery(for: Date()))
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name.givenName, "D")
    }

    func testContactQueryWithNoDateReturnsAllVersionsOfAContact() async throws {
        try await store.addContact(OCKContact(id: "contact", givenName: "A", familyName: "", carePlanUUID: nil))
        try await store.updateContact(OCKContact(id: "contact", givenName: "B", familyName: "", carePlanUUID: nil))
        try await store.updateContact(OCKContact(id: "contact", givenName: "C", familyName: "", carePlanUUID: nil))
        try await store.updateContact(OCKContact(id: "contact", givenName: "D", familyName: "", carePlanUUID: nil))
        let fetched = try await store.fetchContacts(query: OCKContactQuery())
        XCTAssertEqual(fetched.count, 4)
    }

    func testContactQueryOnPastDateReturnsPastVersionOfAContact() async throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKContact(id: "A", givenName: "a", familyName: "b", carePlanUUID: nil)
        versionA.effectiveDate = dateA
        versionA = try await store.addContact(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKContact(id: "A", givenName: "a", familyName: "c", carePlanUUID: nil)
        versionB.effectiveDate = dateB
        versionB = try await store.updateContact(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let query = OCKContactQuery(dateInterval: interval)
        let fetched = try await store.fetchContacts(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, versionA.name)
    }

    func testContactQuerySpanningVersionsReturnsNewestVersionOnly() async throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKContact(id: "A", givenName: "a", familyName: "b", carePlanUUID: nil)
        versionA.effectiveDate = dateA
        versionA = try await store.addContact(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKContact(id: "A", givenName: "a", familyName: "c", carePlanUUID: nil)
        versionB.effectiveDate = dateB
        versionB = try await store.updateContact(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let query = OCKContactQuery(dateInterval: interval)

        let fetched = try await store.fetchContacts(query: query)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, versionB.name)
    }

    func testContactQueryBeforeContactWasCreatedReturnsNoResults() async throws {
        let dateA = Date()
        try await store.addContact(OCKContact(id: "A", givenName: "a", familyName: "b", carePlanUUID: nil))
        let interval = DateInterval(start: dateA.addingTimeInterval(-100), end: dateA)
        let query = OCKContactQuery(dateInterval: interval)
        let fetched = try await store.fetchContacts(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: Deletion

    func testDeleteContact() async throws {
        let contact = try await store.addContact(OCKContact(id: "contact", givenName: "Christopher", familyName: "Foss", carePlanUUID: nil))
        try await store.deleteContact(contact)
        let fetched = try await store.fetchContacts(query: .init(for: Date()))
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteContactFailsIfContactDoesntExist() async {
        let contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)

        do {
            try await store.deleteContact(contact)
            XCTFail("Expected to fail")
        } catch {
            // no-op
        }
    }
}

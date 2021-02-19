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

import CoreData
import Foundation

@objc(OCKCDContact)
class OCKCDContact: OCKCDVersionedObject {
    @NSManaged var carePlan: OCKCDCarePlan?
    @NSManaged var name: OCKCDPersonName
    @NSManaged var address: OCKCDPostalAddress?
    @NSManaged var organization: String?
    @NSManaged var title: String?
    @NSManaged var role: String?
    @NSManaged var category: String?

    @NSManaged private var emailAddressesDictionary: [String: String]?
    @NSManaged private var messagingNumbersDictionary: [String: String]?
    @NSManaged private var phoneNumbersDictionary: [String: String]?
    @NSManaged private var otherContactInfoDictionary: [String: String]?

    var messagingNumbers: [OCKLabeledValue]? {
        get { messagingNumbersDictionary?.asLabeledValues() }
        set { messagingNumbersDictionary = newValue?.asDictionary() }
    }

    var emailAddresses: [OCKLabeledValue]? {
        get { emailAddressesDictionary?.asLabeledValues() }
        set { emailAddressesDictionary = newValue?.asDictionary() }
    }

    var phoneNumbers: [OCKLabeledValue]? {
        get { phoneNumbersDictionary?.asLabeledValues() }
        set { phoneNumbersDictionary = newValue?.asDictionary() }
    }

    var otherContactInfo: [OCKLabeledValue]? {
        get { otherContactInfoDictionary?.asLabeledValues() }
        set { otherContactInfoDictionary = newValue?.asDictionary() }
    }
    
    convenience init(contact: OCKContact, context: NSManagedObjectContext) {
        self.init(entity: Self.entity(), insertInto: context)
        self.copyVersionedValue(value: contact, context: context)
        self.name = OCKCDPersonName(name: contact.name, context: context)
        self.emailAddresses = contact.emailAddresses
        self.messagingNumbers = contact.messagingNumbers
        self.phoneNumbers = contact.phoneNumbers
        self.otherContactInfo = contact.otherContactInfo
        self.organization = contact.organization
        self.title = contact.title
        self.role = contact.role
        self.category = contact.category?.rawValue
        self.address = contact.address.map { OCKCDPostalAddress(address: $0, context: context) }

        if let carePlanUUID = contact.carePlanUUID {
            self.carePlan = try? context.fetchObject(uuid: carePlanUUID)
        }
    }

    override func makeValue() -> OCKVersionedObjectCompatible {
        makeContact()
    }

    func makeContact() -> OCKContact {

        var contact = OCKContact(
            id: id,
            name: name.makeValue(),
            carePlanUUID: carePlan?.uuid
        )

        contact.copyVersionedValues(from: self)
        contact.emailAddresses = emailAddresses
        contact.messagingNumbers = messagingNumbers
        contact.phoneNumbers = phoneNumbers
        contact.otherContactInfo = otherContactInfo
        contact.organization = organization
        contact.title = title
        contact.role = role
        contact.category = category.map { OCKContactCategory(rawValue: $0)! }
        contact.address = address?.makeValue()
        return contact
    }
}

private extension Dictionary where Key == String, Value == String {
    func asLabeledValues() -> [OCKLabeledValue] {
        let sortedKeys = keys.sorted()
        return sortedKeys.map { OCKLabeledValue(label: $0, value: self[$0]!) }
    }
}

private extension Array where Element == OCKLabeledValue {
    func asDictionary() -> [String: String] {
        var dictionary = [String: String]()
        for labeldValue in self {
            dictionary[labeldValue.label] = labeldValue.value
        }
        return dictionary
    }
}

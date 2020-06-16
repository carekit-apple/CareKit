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

import CareKitStore
import Contacts
import Foundation

private extension OCKLabeledValue {
    func toLabeledString() -> CNLabeledValue<NSString> { CNLabeledValue(label: label, value: NSString(string: value)) }
    func toLabeledPhoneNumber() -> CNLabeledValue<CNPhoneNumber> { CNLabeledValue(label: label, value: CNPhoneNumber(stringValue: value)) }
}

private extension OCKPostalAddress {
    func toCNLabeledValue() -> CNLabeledValue<CNPostalAddress> { CNLabeledValue(label: "", value: self) }
}


extension CNMutableContact {
    convenience init(from contact: OCKAnyContact) {
        self.init()
        if let value = contact.organization      { organizationName = value }
        if let value = contact.phoneNumbers      { phoneNumbers = value.map { $0.toLabeledPhoneNumber() } }
        if let value = contact.address           { postalAddresses = [value.toCNLabeledValue()] }
        if let value = contact.emailAddresses    { emailAddresses = value.map { $0.toLabeledString() } }
        if let value = contact.title             { jobTitle = value }
        if let value = contact.role              { note = value }
        if let value = contact.organization      { departmentName = value }
        if let value = contact.emailAddresses    { emailAddresses = value.map { $0.toLabeledString() } }
        if let value = contact.name.familyName   { familyName = value }
        if let value = contact.name.givenName    { givenName = value }
        if let value = contact.name.middleName   { middleName = value }
        if let value = contact.name.namePrefix   { namePrefix = value }
        if let value = contact.name.nameSuffix   { nameSuffix = value }
        if let value = contact.name.nickname     { nickname = value }

        if let value = contact.name.phoneticRepresentation?.familyName       { phoneticFamilyName = value }
        if let value = contact.name.phoneticRepresentation?.givenName        { phoneticGivenName = value }
        if let value = contact.name.phoneticRepresentation?.middleName       { phoneticMiddleName = value }
    }
}


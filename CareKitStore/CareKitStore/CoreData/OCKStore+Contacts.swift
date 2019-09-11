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

extension OCKStore {
    public func fetchContacts(_ anchor: OCKContactAnchor? = nil, query: OCKContactQuery? = nil, queue: DispatchQueue = .main,
                              completion: @escaping (Result<[OCKContact], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: anchor, and: query)
                let persistedContacts = OCKCDContact.fetchFromStore(in: self.context, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query?.limit ?? 0
                    fetchRequest.fetchOffset = query?.offset ?? 0
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(for: query)
                }

                let contacts = persistedContacts.map(self.makeContact)
                queue.async { completion(.success(contacts)) }
            } catch {
                queue.async { completion(.failure(.fetchFailed(reason: "Failed to fetch contacts. Error: \(error.localizedDescription)"))) }
            }
        }
    }

    public func addContacts(_ contacts: [OCKContact], queue: DispatchQueue = .main,
                            completion: ((Result<[OCKContact], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                try OCKCDContact.validateNewIdentifiers(contacts.map { $0.identifier }, in: self.context)
                let persistableContacts = contacts.map(self.addContact)
                try self.context.save()
                let savedContacts = persistableContacts.map(self.makeContact)
                queue.async {
                    self.delegate?.store(self, didAddContacts: savedContacts)
                    completion?(.success(savedContacts))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.addFailed(reason: "Failed to insert contacts: [\(contacts)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    public func updateContacts(_ contacts: [OCKContact], queue: DispatchQueue = .main, completion: OCKResultClosure<[OCKContact]>? = nil) {
        context.perform {
            do {
                try OCKCDContact.validateUpdateIdentifiers(contacts.map { $0.identifier }, in: self.context)

                let updatedContacts = self.configuration.updatesCreateNewVersions ?
                    try self.performVersionedUpdate(values: contacts, addNewVersion: self.addContact) :
                    try self.performUnversionedUpdate(values: contacts, update: self.copyContact)

                try self.context.save()
                let contacts = updatedContacts.map(self.makeContact)
                queue.async {
                    self.delegate?.store(self, didUpdateContacts: contacts)
                    completion?(.success(contacts))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.updateFailed(reason: "Failed to update contacts: [\(contacts)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    public func deleteContacts(_ contacts: [OCKContact], queue: DispatchQueue = .main,
                               completion: ((Result<[OCKContact], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let deletedContacts = try self.performUnversionedUpdate(values: contacts) { _, persistableContact in
                    persistableContact.deletedDate = Date()
                }.map(self.makeContact)

                try self.context.save()
                queue.async {
                    self.delegate?.store(self, didDeleteContacts: deletedContacts)
                    completion?(.success(deletedContacts))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete contacts: [\(contacts)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    private func addContact(from contact: OCKContact) -> OCKCDContact {
        let persistableContact = OCKCDContact(context: context)
        persistableContact.name = OCKCDPersonName(context: context)
        copyContact(contact, to: persistableContact)
        return persistableContact
    }

    private func copyContact(_ contact: OCKContact, to persistableContact: OCKCDContact) {
        persistableContact.copyVersionInfo(from: contact)
        persistableContact.allowsMissingRelationships = allowsEntitiesWithMissingRelationships
        persistableContact.name.copyPersonNameComponents(contact.name)
        persistableContact.emailAddresses = contact.emailAddresses
        persistableContact.messagingNumbers = contact.messagingNumbers
        persistableContact.phoneNumbers = contact.phoneNumbers
        persistableContact.otherContactInfo = contact.otherContactInfo
        persistableContact.organization = contact.organization
        persistableContact.title = contact.title
        persistableContact.role = contact.role
        persistableContact.category = contact.category?.rawValue

        if let carePlanID = contact.carePlanID { persistableContact.carePlan = try? fetchObject(havingLocalID: carePlanID) }
        if let address = contact.address {
            if let postalAddress = persistableContact.address {
                copyPostalAddress(address, to: postalAddress)
            } else {
                persistableContact.address = addPostalAddress(from: address)
            }
        } else {
            persistableContact.address = nil
        }
    }

    private func addPostalAddress(from address: OCKPostalAddress) -> OCKCDPostalAddress {
        let persistableAddress = OCKCDPostalAddress(context: context)
        copyPostalAddress(address, to: persistableAddress)
        return persistableAddress
    }

    private func copyPostalAddress(_ address: OCKPostalAddress, to persitableAddress: OCKCDPostalAddress) {
        persitableAddress.street = address.street
        persitableAddress.subLocality = address.subLocality
        persitableAddress.city = address.city
        persitableAddress.subAdministrativeArea = address.subAdministrativeArea
        persitableAddress.state = address.state
        persitableAddress.postalCode = address.postalCode
        persitableAddress.country = address.country
        persitableAddress.isoCountryCode = address.isoCountryCode
    }

    private func makeContact(from object: OCKCDContact) -> OCKContact {
        var contact = OCKContact(identifier: object.identifier, name: object.name.makeComponents(), carePlanID: object.carePlan?.localDatabaseID)
        contact.copyVersionedValues(from: object)
        contact.address = object.address.map(makePostalAddress)
        contact.emailAddresses = object.emailAddresses
        contact.messagingNumbers = object.messagingNumbers
        contact.phoneNumbers = object.phoneNumbers
        contact.otherContactInfo = object.otherContactInfo
        contact.organization = object.organization
        contact.title = object.title
        contact.role = object.role
        if let rawValue = object.category { contact.category = OCKContact.Category(rawValue: rawValue) }
        return contact
    }

    private func makePostalAddress(from object: OCKCDPostalAddress) -> OCKPostalAddress {
        let address = OCKPostalAddress()
        address.street = object.street
        address.subLocality = object.subLocality
        address.city = object.city
        address.subAdministrativeArea = object.subAdministrativeArea
        address.state = object.state
        address.postalCode = object.postalCode
        address.country = object.country
        address.isoCountryCode = object.isoCountryCode
        return address
    }

    private func buildPredicate(for anchor: OCKContactAnchor?, and query: OCKContactQuery?) throws -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            try buildSubPredicate(for: anchor),
            buildSubPredicate(for: query),
            NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedDate))
        ])
    }

    private func buildSubPredicate(for anchor: OCKContactAnchor?) throws -> NSPredicate {
        guard let anchor = anchor else { return NSPredicate(value: true) }
        switch anchor {
        case .contactIdentifier(let identifiers):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.identifier), identifiers)
        case .contactRemoteIDs(let remoteIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.remoteID), remoteIDs)
        case .carePlanRemoteIDs(let carePlanRemoteIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDContact.carePlan.remoteID), carePlanRemoteIDs)
        case .carePlanVersions(let carePlanVersionIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDContact.carePlan), try carePlanVersionIDs.map(fetchObject))
        }
    }

    private func buildSubPredicate(for query: OCKContactQuery?) -> NSPredicate {
        var predicate = NSPredicate(value: true)
        if let interval = query?.dateInterval {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                predicate, OCKCDVersionedObject.newestVersionPredicate(in: interval)
            ])
        }
        if let groupIdentifiers = query?.groupIdentifiers {
            predicate = predicate.including(groupIdentifiers: groupIdentifiers)
        }
        if let tags = query?.tags {
            predicate = predicate.including(tags: tags)
        }
        return predicate
    }

    private func buildSortDescriptors(for query: OCKContactQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.sortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.effectiveDate, ascending: ascending)
            case .familyName(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.name.familyName, ascending: ascending)
            case .givenName(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.name.givenName, ascending: ascending)
            }
        }
    }
}

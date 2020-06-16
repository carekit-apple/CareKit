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

    open func fetchContacts(query: OCKContactQuery = OCKContactQuery(), callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<[OCKContact], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: query)
                let persistedContacts = self.fetchFromStore(OCKCDContact.self, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query.limit ?? 0
                    fetchRequest.fetchOffset = query.offset
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(for: query)
                }

                let contacts = persistedContacts
                    .map(self.makeContact)
                    .filter({ $0.matches(tags: query.tags) })

                callbackQueue.async { completion(.success(contacts)) }
            } catch {
                callbackQueue.async { completion(.failure(.fetchFailed(reason: "Failed to fetch contacts. Error: \(error.localizedDescription)"))) }
            }
        }
    }

    open func addContacts(_ contacts: [OCKContact], callbackQueue: DispatchQueue = .main,
                          completion: ((Result<[OCKContact], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let addedContacts = try self.createContactsWithoutCommitting(contacts)
                try self.context.save()
                callbackQueue.async {
                    self.contactDelegate?.contactStore(self, didAddContacts: addedContacts)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(addedContacts))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.addFailed(reason: "Failed to insert contacts: [\(contacts)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    open func updateContacts(_ contacts: [OCKContact], callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<[OCKContact]>? = nil) {
        context.perform {
            do {
                let updated = try self.updateContactsWithoutCommitting(contacts, copyUUIDs: false)
                try self.context.save()
                callbackQueue.async {
                    self.contactDelegate?.contactStore(self, didUpdateContacts: updated)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(updated))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.updateFailed(reason: "Failed to update contacts: [\(contacts)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    open func deleteContacts(_ contacts: [OCKContact], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKContact], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let markedDeleted: [OCKCDContact] = try self.performDeletion(
                    values: contacts,
                    addNewVersion: self.createContact)
                
                try self.context.save()
                let deletedContacts = markedDeleted.map(self.makeContact)
                callbackQueue.async {
                    self.contactDelegate?.contactStore(self, didDeleteContacts: deletedContacts)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(deletedContacts))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete contacts: [\(contacts)]. \(error.localizedDescription)")))
                }
            }
        }
    }
    
    // MARK: Internal
    // These methods are called from elsewhere in CareKit, but must always be called
    // from the `contexts`'s thread.

    func createContactsWithoutCommitting(_ contacts: [Contact]) throws -> [Contact] {
        try self.validateNew(OCKCDContact.self, contacts)
        let persistableContacts = contacts.map(self.createContact)
        let addedContacts = persistableContacts.map(self.makeContact)
        return addedContacts
    }

    /// Updates existing contacts to the versions passed in.
    ///
    /// The copyUUIDs argument should be true when ingesting contacts from a remote to ensure
    /// the UUIDs match on all devices, and false when creating a new version of a contact locally
    /// to ensure that the new version has a different UUID than its parent version.
    ///
    /// - Parameters:
    ///   - contacts: The new versions of the contacts.
    ///   - copyUUIDs: If true, the UUIDs of the contacts will be copied to the new versions
    func updateContactsWithoutCommitting(_ contacts: [Contact], copyUUIDs: Bool) throws -> [Contact] {
        try validateUpdateIdentifiers(contacts.map { $0.id })
        let updatedContacts = try self.performVersionedUpdate(values: contacts, addNewVersion: self.createContact)
        if copyUUIDs {
            updatedContacts.enumerated().forEach { $1.uuid = contacts[$0].uuid! }
        }
        let updated = updatedContacts.map(self.makeContact)
        return updated
    }
    
    private func createContact(from contact: OCKContact) -> OCKCDContact {
        let persistableContact = OCKCDContact(context: context)
        persistableContact.name = OCKCDPersonName(context: context)
        persistableContact.copyVersionInfo(from: contact)
        persistableContact.allowsMissingRelationships = configuration.allowsEntitiesWithMissingRelationships
        persistableContact.name.copyPersonNameComponents(contact.name)
        persistableContact.emailAddresses = contact.emailAddresses
        persistableContact.messagingNumbers = contact.messagingNumbers
        persistableContact.phoneNumbers = contact.phoneNumbers
        persistableContact.otherContactInfo = contact.otherContactInfo
        persistableContact.organization = contact.organization
        persistableContact.title = contact.title
        persistableContact.role = contact.role
        persistableContact.category = contact.category?.rawValue

        if let carePlanUUID = contact.carePlanUUID { persistableContact.carePlan = try? fetchObject(uuid: carePlanUUID) }
        if let address = contact.address {
            if let postalAddress = persistableContact.address {
                copyPostalAddress(address, to: postalAddress)
            } else {
                persistableContact.address = createPostalAddress(from: address)
            }
        } else {
            persistableContact.address = nil
        }
        return persistableContact
    }

    private func createPostalAddress(from address: OCKPostalAddress) -> OCKCDPostalAddress {
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

    internal func makeContact(from object: OCKCDContact) -> OCKContact {
        var contact = OCKContact(id: object.id, name: object.name.makeComponents(), carePlanUUID: object.carePlan?.uuid)
        contact.copyVersionedValues(from: object)
        contact.address = object.address.map(makePostalAddress)
        contact.emailAddresses = object.emailAddresses
        contact.messagingNumbers = object.messagingNumbers
        contact.phoneNumbers = object.phoneNumbers
        contact.otherContactInfo = object.otherContactInfo
        contact.organization = object.organization
        contact.title = object.title
        contact.role = object.role
        if let rawValue = object.category { contact.category = OCKContactCategory(rawValue: rawValue) }
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

    private func buildPredicate(for query: OCKContactQuery) throws -> NSPredicate {
        var predicate = OCKCDVersionedObject.notDeletedPredicate

        if let interval = query.dateInterval {
            let intervalPredicate = OCKCDVersionedObject.newestVersionPredicate(in: interval)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, intervalPredicate])
        }

        if !query.ids.isEmpty {
            let idPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.id), query.ids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, idPredicate])
        }

        if !query.uuids.isEmpty {
            let objectPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.uuid), query.uuids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, objectPredicate])
        }

        if !query.remoteIDs.isEmpty {
            predicate = predicate.including(query.remoteIDs, for: #keyPath(OCKCDObject.remoteID))
        }

        if !query.carePlanIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDContact.carePlan.id), query.carePlanIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanUUIDs.isEmpty {
            let objectPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDContact.carePlan.uuid), query.carePlanUUIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, objectPredicate])
        }

        if !query.carePlanRemoteIDs.isEmpty {
            let remotePredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDContact.carePlan.remoteID), query.carePlanRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        if !query.groupIdentifiers.isEmpty {
            predicate = predicate.including(
                query.groupIdentifiers,
                for: #keyPath(OCKCDObject.groupIdentifier))
        }

        return predicate
    }

    private func buildSortDescriptors(for query: OCKContactQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.extendedSortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.effectiveDate, ascending: ascending)
            case .familyName(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.name.familyName, ascending: ascending)
            case .givenName(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDContact.name.givenName, ascending: ascending)
            }
        } + defaultSortDescritors()
    }
}

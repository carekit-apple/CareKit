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

import Foundation

extension OCKStore {

    open func fetchPatients(query: OCKPatientQuery = OCKPatientQuery(), callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<[OCKPatient], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: query)
                let patientsObjects = self.fetchFromStore(OCKCDPatient.self, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query.limit ?? 0
                    fetchRequest.fetchOffset = query.offset
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(from: query)
                }

                let patients = patientsObjects
                    .map(self.makePatient)
                    .filter({ $0.matches(tags: query.tags) })

                callbackQueue.async { completion(.success(patients)) }
            } catch {
                self.context.rollback()
                let message = "Failed to fetch patients with query: \(String(describing: query)). \(error.localizedDescription)"
                callbackQueue.async { completion(.failure(.fetchFailed(reason: message))) }
            }
        }
    }

    open func addPatients(_ patients: [OCKPatient], callbackQueue: DispatchQueue = .main,
                          completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                try self.validateNumberOfPatients()
                let addedPatients = try self.createPatientsWithoutCommitting(patients)
                try self.context.save()
                callbackQueue.async {
                    self.patientDelegate?.patientStore(self, didAddPatients: addedPatients)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(addedPatients))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.addFailed(reason: "Failed to insert OCKPatients: [\(patients)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    open func updatePatients(_ patients: [OCKPatient], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let updated = try self.updatePatientsWithoutCommitting(patients, copyUUIDs: false)
                try self.context.save()
                callbackQueue.async {
                    self.patientDelegate?.patientStore(self, didUpdatePatients: updated)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(updated))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.updateFailed(reason: "Failed to update OCKPatients: [\(patients)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    open func deletePatients(_ patients: [OCKPatient], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let markedDeleted: [OCKCDPatient] = try self.performDeletion(
                    values: patients,
                    addNewVersion: self.createPatient)
                
                try self.context.save()
                let deletedPatients = markedDeleted.map(self.makePatient)
                callbackQueue.async {
                    self.patientDelegate?.patientStore(self, didDeletePatients: deletedPatients)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(deletedPatients))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete OCKPatients: [\(patients)]. \(error.localizedDescription)")))
                }
            }
        }
    }
    
    // MARK: Internal
    // These methods are called from elsewhere in CareKit, but must always be called
    // from the `contexts`'s thread.

    func createPatientsWithoutCommitting(_ patients: [Patient]) throws -> [Patient] {
        try self.validateNew(OCKCDPatient.self, patients)
        let persistablePatients = patients.map(self.createPatient)
        let addedPatients = persistablePatients.map(self.makePatient)
        return addedPatients
    }

    /// Updates existing patients to the versions passed in.
    ///
    /// The copyUUIDs argument should be true when ingesting patients from a remote to ensure
    /// the UUIDs match on all devices, and false when creating a new version of a patient locally
    /// to ensure that the new version has a different UUID than its parent version.
    ///
    /// - Parameters:
    ///   - patients: The new versions of the patients.
    ///   - copyUUIDs: If true, the UUIDs of the patients will be copied to the new versions
    func updatePatientsWithoutCommitting(_ patients: [Patient], copyUUIDs: Bool) throws -> [Patient] {
        try validateUpdateIdentifiers(patients.map { $0.id })
        let updatedPatients = try self.performVersionedUpdate(values: patients, addNewVersion: self.createPatient)
        if copyUUIDs {
            updatedPatients.enumerated().forEach { $1.uuid = patients[$0].uuid! }
        }
        let updated = updatedPatients.map(self.makePatient)
        return updated
    }

    // MARK: Private

    /// - Remark: This does not commit the transaction. After calling this function one or more times, you must call `context.save()` in order to
    /// persist the changes to disk. This is an optimization to allow batching.
    /// - Remark: You should verify that the object does not already exist in the database and validate its values before calling this method.
    private func createPatient(from patient: OCKPatient) -> OCKCDPatient {
        let persistablePatient = OCKCDPatient(context: context)
        persistablePatient.name = OCKCDPersonName(context: context)
        persistablePatient.copyVersionInfo(from: patient)
        persistablePatient.allowsMissingRelationships = configuration.allowsEntitiesWithMissingRelationships
        persistablePatient.name.copyPersonNameComponents(patient.name)
        persistablePatient.sex = patient.sex?.rawValue
        persistablePatient.birthday = patient.birthday
        persistablePatient.allergies = patient.allergies
        return persistablePatient
    }

    /// - Remark: This method is intended to create a value type struct from a *persisted* NSManagedObject. Calling this method with an
    /// object that is not yet commited is a programmer error.
    internal func makePatient(from object: OCKCDPatient) -> OCKPatient {
        var patient = OCKPatient(id: object.id, name: object.name.makeComponents())
        patient.sex = object.sex == nil ? nil : OCKBiologicalSex(rawValue: object.sex!)
        patient.birthday = object.birthday
        patient.allergies = object.allergies
        patient.copyVersionedValues(from: object)
        return patient
    }

    private func buildPredicate(for query: OCKPatientQuery) throws -> NSPredicate {
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

        if !query.groupIdentifiers.isEmpty {
            predicate = predicate.including(
                query.groupIdentifiers,
                for: #keyPath(OCKCDObject.groupIdentifier))
        }

        return predicate
    }

    private func buildSortDescriptors(from query: OCKPatientQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.extendedSortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.effectiveDate, ascending: ascending)
            case .givenName(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.name.givenName, ascending: ascending)
            case .familyName(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.name.familyName, ascending: ascending)
            case .groupIdentifier(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.groupIdentifier, ascending: ascending)
            }
        } + defaultSortDescritors()
    }
    
    private func validateNumberOfPatients() throws {
        let fetchRequest = OCKCDPatient.fetchRequest()
        let numberOfPatients = try context.count(for: fetchRequest)
        if numberOfPatients > 0 {
            let explanation = """
            OCKStore` only supports one patient per store.
            If you would like to have more than one patient, create a new store for that patient.
            """
            throw OCKStoreError.addFailed(reason: explanation)
        }
    }
}

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

public extension OCKStore {
    func fetchPatients(_ anchor: OCKPatientAnchor? = nil, query: OCKPatientQuery? = nil,
                       queue: DispatchQueue = .main, completion: @escaping (Result<[OCKPatient], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(from: anchor, query: query)
                let patientsObjects = OCKCDPatient.fetchFromStore(in: self.context, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query?.limit ?? 0
                    fetchRequest.fetchOffset = query?.offset ?? 0
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(from: query)
                }

                let patients = patientsObjects.map(self.makePatient)
                queue.async { completion(.success(patients)) }
            } catch {
                self.context.rollback()
                let message = "Failed to fetch patients with query: \(String(describing: query)). \(error.localizedDescription)"
                queue.async { completion(.failure(.fetchFailed(reason: message))) }
            }
        }
    }

    func addPatients(_ patients: [OCKPatient], queue: DispatchQueue = .main, completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                try self.validateNumberOfPatients()
                try OCKCDPatient.validateNewIdentifiers(patients.map { $0.identifier }, in: self.context)
                let persistablePatients = patients.map(self.addPatient)
                try self.context.save()
                let updatedPatients = persistablePatients.map(self.makePatient)
                queue.async {
                    self.delegate?.store(self, didAddPatients: updatedPatients)
                    completion?(.success(updatedPatients))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.addFailed(reason: "Failed to insert OCKPatients: [\(patients)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    func updatePatients(_ patients: [OCKPatient], queue: DispatchQueue = .main,
                        completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let identifiers = patients.map { $0.identifier }
                try OCKCDPatient.validateUpdateIdentifiers(identifiers, in: self.context)

                let updatedPatients = self.configuration.updatesCreateNewVersions ?
                    try self.performVersionedUpdate(values: patients, addNewVersion: self.addPatient) :
                    try self.performUnversionedUpdate(values: patients, update: self.copyPatient)

                try self.context.save()
                let patients = updatedPatients.map(self.makePatient)
                queue.async {
                    self.delegate?.store(self, didUpdatePatients: patients)
                    completion?(.success(patients))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.updateFailed(reason: "Failed to update OCKPatients: [\(patients)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    func deletePatients(_ patients: [OCKPatient], queue: DispatchQueue = .main,
                        completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let deletedPatients = try self.performUnversionedUpdate(values: patients) { _, persistablePatient in
                    persistablePatient.deletedDate = Date()
                }.map(self.makePatient)

                try self.context.save()
                queue.async {
                    self.delegate?.store(self, didDeletePatients: deletedPatients)
                    completion?(.success(deletedPatients))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete OCKPatients: [\(patients)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    // MARK: Private

    /// - Remark: This does not commit the transaction. After calling this function one or more times, you must call `context.save()` in order to
    /// persist the changes to disk. This is an optimization to allow batching.
    /// - Remark: You should verify that the object does not already exist in the database and validate its values before calling this method.
    private func addPatient(_ patient: OCKPatient) -> OCKCDPatient {
        let persistablePatient = OCKCDPatient(context: context)
        persistablePatient.name = OCKCDPersonName(context: context)
        copyPatient(from: patient, to: persistablePatient)
        return persistablePatient
    }

    private func copyPatient(from patient: OCKPatient, to persistablePatient: OCKCDPatient) {
        persistablePatient.copyVersionInfo(from: patient)
        persistablePatient.allowsMissingRelationships = allowsEntitiesWithMissingRelationships
        persistablePatient.name.copyPersonNameComponents(patient.name)
        persistablePatient.sex = patient.sex?.rawValue
        persistablePatient.birthday = patient.birthday
        persistablePatient.allergies = patient.allergies
    }

    /// - Remark: This method is intended to create a value type struct from a *persisted* NSManagedObject. Calling this method with an
    /// object that is not yet commited is a programmer error.
    private func makePatient(from object: OCKCDPatient) -> OCKPatient {
        assert(object.localDatabaseID != nil, "Do not create a patient from an object that isn't persisted yet!")
        var patient = OCKPatient(identifier: object.identifier, name: object.name.makeComponents())
        patient.sex = object.sex == nil ? nil : OCKBiologicalSex(rawValue: object.sex!)
        patient.birthday = object.birthday
        patient.allergies = object.allergies
        patient.copyVersionedValues(from: object)
        return patient
    }

    private func buildPredicate(from anchor: OCKPatientAnchor?, query: OCKPatientQuery?) throws -> NSPredicate {
        let anchorPredicate = try buildSubPredicate(from: anchor)
        let queryPredicate = buildSubPredicate(from: query)
        let notDeletedPredicate = NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedDate))
        return NSCompoundPredicate(andPredicateWithSubpredicates: [anchorPredicate, queryPredicate, notDeletedPredicate])
    }

    private func buildSubPredicate(from anchor: OCKPatientAnchor?) throws -> NSPredicate {
        guard let anchor = anchor else { return NSPredicate(value: true) }
        switch anchor {
        case .patientIdentifiers(let patientIdentifiers):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.identifier), patientIdentifiers)
        case .patientVersions(let patientVersionIDs):
            return NSPredicate(format: "self IN %@", try patientVersionIDs.map(objectID))
        case .patientRemoteIDs(let patientremoteIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.remoteID), patientremoteIDs)
        }
    }

    private func buildSubPredicate(from query: OCKPatientQuery?) -> NSPredicate {
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

    private func buildSortDescriptors(from query: OCKPatientQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.sortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.effectiveDate, ascending: ascending)
            case .givenName(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.name.givenName, ascending: ascending)
            case .familyName(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.name.familyName, ascending: ascending)
            case .groupIdentifier(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.groupIdentifier, ascending: ascending)
            }
        }
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

/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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

extension NSManagedObjectContext {

    var clockID: UUID {
        var id: UUID!
        performAndWait {
            id = OCKCDClock.fetch(context: self).uuid
        }
        return id
    }

    var knowledgeVector: OCKRevisionRecord.KnowledgeVector {
        get {
            var vector: OCKRevisionRecord.KnowledgeVector!
            performAndWait {
                vector = OCKCDClock.fetch(context: self).vector
            }
            return vector
        }

        set {
            performAndWait {
                OCKCDClock.fetch(context: self).vector = newValue
            }
        }
    }

    var clockTime: Int {
        knowledgeVector.clock(for: clockID)
    }
}

extension OCKStore {

    /// Details the modes in which synchronization can be performed.
    public enum SynchronizationPolicy {

        /// Attempts to keep both device and local records, by merging them together.
        /// This is the option that should typically be used.
        case mergeDeviceRecordsWithRemote

        /// Deletes all records on the remote and replaces them with the records
        /// from this device.
        case overwriteRemoteWithDeviceRecords

        /// Deletes all records on this device and replaces them with the records
        /// from the remote.
        case overwriteDeviceRecordsWithRemote
    }

    /// Synchronizes the on device store with one on a remote server.
    ///
    /// Depending on the mode, it possible to overwrite the entire contents of the device or
    /// the remote with the data from the other.
    ///
    /// - Parameters:
    ///   - policy: The synchronization policy. Defaults to `.mergeDeviceRecordsWithRemote`
    ///   - completion: A completion closure that will be called when syncing completes.
    /// - SeeAlso: OCKRemoteSynchronizable
    public func synchronize(
        policy: SynchronizationPolicy = .mergeDeviceRecordsWithRemote,
        completion: @escaping(Error?) -> Void) {

        switch policy {

        case .mergeDeviceRecordsWithRemote:
            pullThenPush(completion: completion)

        case .overwriteDeviceRecordsWithRemote:
            deleteAndClone(completion: completion)

        case .overwriteRemoteWithDeviceRecords:
            forcePush(completion: completion)
        }
    }

    /// Calls synchronize if the remote is set and requests to notified after each database modification.
    func autoSynchronizeIfRequired() {
        if remote?.automaticallySynchronizes == true {
            pullThenPush { error in
                if let error = error {
                    print("Failed to automatically synchronize. \(error.localizedDescription)")
                }
            }
        }
    }

    /// Deletes the contents of this store and clones the remotes data in as ground truth.
    private func deleteAndClone(completion: @escaping (Error?) -> Void) {
        self.context.perform {
            // 1. Make sure a remote is setup
            guard let remote = self.remote else {
                completion(OCKStoreError.remoteSynchronizationFailed(
                    reason: "No remote setup for OCKStore."))
                return
            }

            // 2. Make sure a sync is not already in progress
            guard !self.isSynchronizing else {
                completion(OCKStoreError.remoteSynchronizationFailed(
                    reason: "Sync already in progress!"))
                return
            }

            // 3. Start the sync
            self.isSynchronizing = true

            // 4. Delete everything in the local store
            do {
                try self.deleteAllContent()
                self.context.knowledgeVector = .init()
            } catch {
                self.isSynchronizing = false
                self.context.rollback()
                completion(OCKStoreError.remoteSynchronizationFailed(
                    reason: "Failed to delete some store contents."))
                return
            }

            // 5. Pull in everything from remote
            remote.pullRevisions(
                since: self.context.knowledgeVector,
                mergeRevision: self.mergeRevision) { error in

                self.isSynchronizing = false
                completion(error)
            }
        }
    }

    /// Pushes the contents of this store to the remote, completely overwriting its present state
    private func forcePush(completion: @escaping (Error?) -> Void) {
        self.context.perform {
            // 1. Make sure a remote is setup
            guard let remote = self.remote else {
                completion(OCKStoreError.remoteSynchronizationFailed(
                    reason: "No remote setup for OCKStore."))
                return
            }

            // 2. Make sure a sync is not already in progress
            guard !self.isSynchronizing else {
                completion(OCKStoreError.remoteSynchronizationFailed(
                    reason: "Sync already in progress!"))
                return
            }

            // 3. Start synchronizing
            self.isSynchronizing = true

            // 4. Create a revision capturing the entire store
            let revision = self.computeRevision(since: 0)

            // 5. Send it to the remote with a force push
            remote.pushRevisions(
                deviceRevision: revision,
                overwriteRemote: true) { error in

                self.isSynchronizing = false
                completion(error)
            }
        }
    }

    /// Synchronize the contents of this instance of `OCKStore` against another store. Only changes
    /// that have been made since the last successful synchronization will be sent to the remote.
    private func pullThenPush(completion: @escaping (Error?) -> Void) {
        context.perform {

            // 1. Make sure a remote is setup
            guard let remote = self.remote else {
                completion(OCKStoreError.remoteSynchronizationFailed(
                    reason: "No remote set on OCKStore!"))
                return
            }

            // 2. Make sure a sync is not already in progress
            guard !self.isSynchronizing else {
                completion(OCKStoreError.remoteSynchronizationFailed(
                    reason: "Already busy synchronizing!"))
                return
            }

            // 3. Start synchronizing
            self.isSynchronizing = true

            // 4. Pull and merge revisions
            // The function wraps and augments `mergeRevision(:completion:)`
            // to ensure the developer calls it serially.
            var isMerging = false
            var latestClock = 0

            func performMerge(
                _ revision: OCKRevisionRecord,
                _ completion: @escaping(Error?) -> Void) {

                self.context.perform {
                    assert(!isMerging,
                           """
                           Do not call merge in parallel. You must wait until it the first \
                           merge completes before attempting to call merge a second time.
                           """)

                    isMerging = true
                    latestClock = revision.knowledgeVector.clock(for: self.context.clockID)

                    self.mergeRevision(revision, completion: { error in
                        self.context.perform {
                            isMerging = false
                            completion(error)
                        }
                    })
                }
            }

            remote.pullRevisions(
                since: self.context.knowledgeVector,
                mergeRevision: performMerge) { error in

                self.context.perform {
                    if let error = error {
                        self.isSynchronizing = false
                        completion(error)
                        return
                    }
                    // Local revisions will now include the changes
                    // just ingested. It's important that the server
                    // merge routine is idempotent to prevent duplication.
                    let localRevision = self.computeRevision(since: latestClock)

                    // 5. Push conflict resolutions + local changes to remote
                    remote.pushRevisions(
                        deviceRevision: localRevision,
                        overwriteRemote: false) { error in

                        self.context.perform {
                            self.isSynchronizing = false
                            completion(error)
                            return
                        }
                    }
                }
            }
        }
    }

    /// Returns a change set that summarizes the modifications to the local store since the last sync.
    /// The revision is computed by checking the `updatedDate` of entities in the store. Since entities
    /// are mutated by creating a new version, we can simply check if the `updatedDate` is newer
    /// than the date given.
    ///
    /// There are also cases where we performed unversioned updates to versioned objects that violate
    /// the append only nature of the store. In those cases, the `updatedDate` reflects when these
    /// changes were made and can be used to include the entity in revisions.
    func computeRevision(since clock: Int) -> OCKRevisionRecord {

        var localRevisions = [OCKEntity]()

        context.performAndWait {
            changedQuery(OCKCDPatient.self, since: clock).forEach { patient in
                localRevisions.append(.patient(makePatient(from: patient)))
            }
            changedQuery(OCKCDCarePlan.self, since: clock).forEach { carePlan in
                localRevisions.append(.carePlan(makePlan(from: carePlan)))
            }
            changedQuery(OCKCDContact.self, since: clock).forEach { contact in
                localRevisions.append(.contact(makeContact(from: contact)))
            }
            changedQuery(OCKCDTask.self, since: clock).forEach { task in
                localRevisions.append(.task(makeTask(from: task)))
            }
            changedQuery(OCKCDOutcome.self, since: clock).forEach { outcome in
                localRevisions.append(.outcome(self.makeOutcome(from: outcome)))
            }
        }

        // We need to sort the revision so that conflict resolutions are applied
        // before updates from this device's store. conflict resolutions result
        // in the creation of tombstones, we need to shuffle them to the front.
        let (tombstones, others) = localRevisions.split { $0.deletedDate != nil }
        let sortedTombstones = tombstones.sorted(by: { $0.value.updatedDate! < $1.value.updatedDate! })
        let sortedOthers = others.sorted(by: { $0.value.updatedDate! < $1.value.updatedDate! })
        let sortedRevisions = sortedTombstones + sortedOthers

        let record = OCKRevisionRecord(
            entities: sortedRevisions,
            knowledgeVector: context.knowledgeVector)

        return record
    }

    /// Attempts to resolve the changes from a remote store.
    /// Commits the transaction if successful, rollsback otherwise.
    func mergeRevision(
        _ revision: OCKRevisionRecord,
        completion: @escaping (Error?) -> Void) {

        context.perform {
            self.recursiveMerge(revision: revision) { error in
                do {
                    if let error = error {
                        throw error
                    }

                    self.context.knowledgeVector.merge(with: revision.knowledgeVector)
                    self.context.knowledgeVector.increment(clockFor: self.context.clockID)

                    try self.context.save()
                    completion(nil)

                } catch {
                    self.context.rollback()
                    completion(error)
                }
            }
        }
    }

    private func recursiveMerge(
        revision: OCKRevisionRecord,
        currentIndex: Int = 0,
        error: Error? = nil,
        completion: @escaping (Error?) -> Void) {

        if let error = error {
            completion(error)
            return
        }

        if currentIndex >= revision.entities.count {
            completion(nil)
            return
        }

        let nextIteration = { error in
            self.recursiveMerge(
                revision: revision,
                currentIndex: currentIndex + 1,
                error: error,
                completion: completion)
        }

        switch revision.entities[currentIndex] {

        case let .patient(patient):
            self.mergePatientRevision(
                patient: patient,
                vector: revision.knowledgeVector,
                completion: nextIteration)
            
        case let .carePlan(carePlan):
            self.mergeCarePlanRevision(
                carePlan: carePlan,
                vector: revision.knowledgeVector,
                completion: nextIteration)
            
        case let .contact(contact):
            self.mergeContactRevision(
            contact: contact,
            vector: revision.knowledgeVector,
            completion: nextIteration)
            
        case let .task(task):
            self.mergeTaskRevision(
                task: task,
                vector: revision.knowledgeVector,
                completion: nextIteration)

        case let .outcome(outcome):
            self.mergeOutcomeRevision(
                outcome: outcome,
                vector: revision.knowledgeVector,
                completion: nextIteration)
        }
    }

    /// - Warning: This method must be called on the `context`'s queue.
    ///
    /// Fetches objects that have been created or modified since the given date. These are the objects that need
    /// to be pushed to the server as part of a sync operation.
    private func changedQuery<T: OCKCDObject>(_ type: T.Type, since clock: Int) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))

        request.predicate = NSPredicate(
            format: "%K >= %lld", #keyPath(OCKCDObject.logicalClock), Int64(clock))

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \OCKCDObject.updatedDate, ascending: false)
        ]

        let results = try! context.fetch(request)
        return results
    }

    /// - Warning: This method must be called on the `context`'s queue.
    private func mergePatientRevision(
        patient: OCKPatient,
        vector: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping (Error?) -> Void) {
        do {
            // If the patient exists on disk already, it means that another device
            // ruled to overwrite this value as part of a conflict resolution.
            if entityExists(OCKCDPatient.self, uuid: patient.uuid!) {
                completion(nil)
                return
            }

            // The patient is either a brand new patient or an update of an existing patient.
            // Deletes count as updates since they are just a new version with the
            // `deletedDate` property set to a non-nil value.
            //
            // Make sure there are no conflicts locally. If the device's knowledge
            // vector is strictly less than the remotes, we can guarantee there is no
            // conflict. Otherwise we need to check.
            let localPatientRevisions = computeRevision(since: vector.clock(for: self.context.clockID))
                .entities
                .compactMap { $0.value as? OCKPatient }

            if let local = localPatientRevisions.first(where: {
                $0.id == patient.id &&
                $0.previousVersionUUID == patient.previousVersionUUID
            }) {

                let conflict = OCKMergeConflictDescription(
                    entities: .patients(
                        deviceVersion: local,
                        remoteVersion: patient))

                remote!.chooseConflictResolutionPolicy(conflict) { strategy in
                    switch strategy {
                    case .abortMerge:
                        let error = OCKStoreError.remoteSynchronizationFailed(
                            reason: "Aborted merge because of conflict in two versions of patient \(patient.id)")
                        completion(error)

                    case .keepRemote:
                        do {
                            // If the remote is a new version of an existing patient, find the previous
                            // version and delete its conflicting next version. This will cascade
                            // delete all future versions and their outcomes. Then update the previous
                            // version to the new version from the remote.
                            if let previousUUD = patient.previousVersionUUID {
                                let previous: OCKCDPatient = try self.fetchObject(uuid: previousUUD)
                                previous.next.map(self.context.delete)

                                let updated = try self.updatePatientsWithoutCommitting([patient], copyUUIDs: true)
                                self.patientDelegate?.patientStore(self, didUpdatePatients: updated)

                                completion(nil)
                                return
                            }

                            // A new patient with the same id was created on both the server
                            // and the local device. Delete the local one and keep the remote.
                            let localPatient: OCKCDPatient = try self.fetchObject(uuid: local.uuid!)
                            self.context.delete(localPatient)
                            let added = try self.createPatientsWithoutCommitting([patient])
                            self.patientDelegate?.patientStore(self, didAddPatients: added)
                            completion(nil)

                        } catch {
                            completion(error)
                        }

                    case .keepDevice:
                        // No action needs to be taken. When the entity from this
                        // device lands on a peer device, ingesting it will cause
                        // any conflicts to be overwritten.
                        completion(nil)
                    }
                }

                return
            }

            // There is no conflict. This is the simplest case, we can just create a new patient.
            if patient.previousVersionUUID == nil {
                let newPatients = try createPatientsWithoutCommitting([patient])
                patientDelegate?.patientStore(self, didAddPatients: newPatients)

            // This is a new version of an existing patient. We might need to delete future versions
            // and their outcomes before adding this version in their place. This happens when
            // one node processes a conflict resolution performed on a different node.
            } else {
                let current: OCKCDPatient = try self.fetchObject(uuid: patient.previousVersionUUID!)
                current.next.map(self.context.delete)
                let updated = try updatePatientsWithoutCommitting([patient], copyUUIDs: true)
                for update in updated {
                    update.deletedDate == nil ?
                        patientDelegate?.patientStore(self, didUpdatePatients: [update]) :
                        patientDelegate?.patientStore(self, didDeletePatients: [update])
                }
            }

            completion(nil)

        } catch {
            completion(error)
        }
    }
    
    /// - Warning: This method must be called on the `context`'s queue.
    private func mergeCarePlanRevision(
        carePlan: OCKCarePlan,
        vector: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping (Error?) -> Void) {
        do {
            // If the carePlan exists on disk already, it means that another device
            // ruled to overwrite this value as part of a conflict resolution.
            if entityExists(OCKCDCarePlan.self, uuid: carePlan.uuid!) {
                completion(nil)
                return
            }

            // The carePlan is either a brand new carePlan or an update of an existing carePlan.
            // Deletes count as updates since they are just a new version with the
            // `deletedDate` property set to a non-nil value.
            //
            // Make sure there are no conflicts locally. If the device's knowledge
            // vector is strictly less than the remotes, we can guarantee there is no
            // conflict. Otherwise we need to check.
            let localCarePlanRevisions = computeRevision(since: vector.clock(for: self.context.clockID))
                .entities
                .compactMap { $0.value as? OCKCarePlan }

            if let local = localCarePlanRevisions.first(where: {
                $0.id == carePlan.id &&
                $0.previousVersionUUID == carePlan.previousVersionUUID
            }) {

                let conflict = OCKMergeConflictDescription(
                    entities: .carePlans(
                        deviceVersion: local,
                        remoteVersion: carePlan))

                remote!.chooseConflictResolutionPolicy(conflict) { strategy in
                    switch strategy {
                    case .abortMerge:
                        let error = OCKStoreError.remoteSynchronizationFailed(
                            reason: "Aborted merge because of conflict in two versions of carePlan \(carePlan.id)")
                        completion(error)

                    case .keepRemote:
                        do {
                            // If the remote is a new version of an existing carePlan, find the previous
                            // version and delete its conflicting next version. This will cascade
                            // delete all future versions and their outcomes. Then update the previous
                            // version to the new version from the remote.
                            if let previousUUD = carePlan.previousVersionUUID {
                                let previous: OCKCDCarePlan = try self.fetchObject(uuid: previousUUD)
                                previous.next.map(self.context.delete)

                                let updated = try self.updateCarePlansWithoutCommitting([carePlan], copyUUIDs: true)
                                self.carePlanDelegate?.carePlanStore(self, didUpdateCarePlans: updated)

                                completion(nil)
                                return
                            }

                            // A new carePlan with the same id was created on both the server
                            // and the local device. Delete the local one and keep the remote.
                            let localCarePlan: OCKCDCarePlan = try self.fetchObject(uuid: local.uuid!)
                            self.context.delete(localCarePlan)
                            let added = try self.createCarePlansWithoutCommitting([carePlan])
                            self.carePlanDelegate?.carePlanStore(self, didAddCarePlans: added)
                            completion(nil)

                        } catch {
                            completion(error)
                        }

                    case .keepDevice:
                        // No action needs to be taken. When the entity from this
                        // device lands on a peer device, ingesting it will cause
                        // any conflicts to be overwritten.
                        completion(nil)
                    }
                }

                return
            }

            // There is no conflict. This is the simplest case, we can just create a new carePlan.
            if carePlan.previousVersionUUID == nil {
                let newCarePlans = try createCarePlansWithoutCommitting([carePlan])
                carePlanDelegate?.carePlanStore(self, didAddCarePlans: newCarePlans)

            // This is a new version of an existing carePlan. We might need to delete future versions
            // and their outcomes before adding this version in their place. This happens when
            // one node processes a conflict resolution performed on a different node.
            } else {
                let current: OCKCDCarePlan = try self.fetchObject(uuid: carePlan.previousVersionUUID!)
                current.next.map(self.context.delete)
                let updated = try updateCarePlansWithoutCommitting([carePlan], copyUUIDs: true)
                for update in updated {
                    update.deletedDate == nil ?
                        carePlanDelegate?.carePlanStore(self, didUpdateCarePlans: [update]) :
                        carePlanDelegate?.carePlanStore(self, didDeleteCarePlans: [update])
                }
            }

            completion(nil)

        } catch {
            completion(error)
        }
    }
    
    /// - Warning: This method must be called on the `context`'s queue.
    private func mergeContactRevision(
        contact: OCKContact,
        vector: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping (Error?) -> Void) {
        do {
            // If the contact exists on disk already, it means that another device
            // ruled to overwrite this value as part of a conflict resolution.
            if entityExists(OCKCDContact.self, uuid: contact.uuid!) {
                completion(nil)
                return
            }

            // The contact is either a brand new contact or an update of an existing contact.
            // Deletes count as updates since they are just a new version with the
            // `deletedDate` property set to a non-nil value.
            //
            // Make sure there are no conflicts locally. If the device's knowledge
            // vector is strictly less than the remotes, we can guarantee there is no
            // conflict. Otherwise we need to check.
            let localContactRevisions = computeRevision(since: vector.clock(for: self.context.clockID))
                .entities
                .compactMap { $0.value as? OCKContact }

            if let local = localContactRevisions.first(where: {
                $0.id == contact.id &&
                $0.previousVersionUUID == contact.previousVersionUUID
            }) {

                let conflict = OCKMergeConflictDescription(
                    entities: .contacts(
                        deviceVersion: local,
                        remoteVersion: contact))

                remote!.chooseConflictResolutionPolicy(conflict) { strategy in
                    switch strategy {
                    case .abortMerge:
                        let error = OCKStoreError.remoteSynchronizationFailed(
                            reason: "Aborted merge because of conflict in two versions of contact \(contact.id)")
                        completion(error)

                    case .keepRemote:
                        do {
                            // If the remote is a new version of an existing contact, find the previous
                            // version and delete its conflicting next version. This will cascade
                            // delete all future versions and their outcomes. Then update the previous
                            // version to the new version from the remote.
                            if let previousUUD = contact.previousVersionUUID {
                                let previous: OCKCDContact = try self.fetchObject(uuid: previousUUD)
                                previous.next.map(self.context.delete)

                                let updated = try self.updateContactsWithoutCommitting([contact], copyUUIDs: true)
                                self.contactDelegate?.contactStore(self, didUpdateContacts: updated)

                                completion(nil)
                                return
                            }

                            // A new contact with the same id was created on both the server
                            // and the local device. Delete the local one and keep the remote.
                            let localContact: OCKCDContact = try self.fetchObject(uuid: local.uuid!)
                            self.context.delete(localContact.name)
                            self.context.delete(localContact)
                            let added = try self.createContactsWithoutCommitting([contact])
                            self.contactDelegate?.contactStore(self, didAddContacts: added)
                            completion(nil)

                        } catch {
                            completion(error)
                        }

                    case .keepDevice:
                        // No action needs to be taken. When the entity from this
                        // device lands on a peer device, ingesting it will cause
                        // any conflicts to be overwritten.
                        completion(nil)
                    }
                }

                return
            }

            // There is no conflict. This is the simplest case, we can just create a new contact.
            if contact.previousVersionUUID == nil {
                let newContacts = try createContactsWithoutCommitting([contact])
                contactDelegate?.contactStore(self, didAddContacts: newContacts)

            // This is a new version of an existing contact. We might need to delete future versions
            // and their outcomes before adding this version in their place. This happens when
            // one node processes a conflict resolution performed on a different node.
            } else {
                let current: OCKCDContact = try self.fetchObject(uuid: contact.previousVersionUUID!)
                current.next.map{self.context.delete(($0 as! OCKCDContact).name)}
                current.next.map(self.context.delete)
                let updated = try updateContactsWithoutCommitting([contact], copyUUIDs: true)
                for update in updated {
                    update.deletedDate == nil ?
                        contactDelegate?.contactStore(self, didUpdateContacts: [update]) :
                        contactDelegate?.contactStore(self, didDeleteContacts: [update])
                }
            }

            completion(nil)

        } catch {
            completion(error)
        }
    }
    
    /// - Warning: This method must be called on the `context`'s queue.
    private func mergeTaskRevision(
        task: OCKTask,
        vector: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping (Error?) -> Void) {
        do {
            // If the task exists on disk already, it means that another device
            // ruled to overwrite this value as part of a conflict resolution.
            if entityExists(OCKCDTask.self, uuid: task.uuid!) {
                completion(nil)
                return
            }

            // The task is either a brand new task or an update of an existing task.
            // Deletes count as updates since they are just a new version with the
            // `deletedDate` property set to a non-nil value.
            //
            // Make sure there are no conflicts locally. If the device's knowledge
            // vector is strictly less than the remotes, we can guarantee there is no
            // conflict. Otherwise we need to check.
            let localTaskRevisions = computeRevision(since: vector.clock(for: self.context.clockID))
                .entities
                .compactMap { $0.value as? OCKTask }

            if let local = localTaskRevisions.first(where: {
                $0.id == task.id &&
                $0.previousVersionUUID == task.previousVersionUUID
            }) {

                let conflict = OCKMergeConflictDescription(
                    entities: .tasks(
                        deviceVersion: local,
                        remoteVersion: task))

                remote!.chooseConflictResolutionPolicy(conflict) { strategy in
                    switch strategy {
                    case .abortMerge:
                        let error = OCKStoreError.remoteSynchronizationFailed(
                            reason: "Aborted merge because of conflict in two versions of task \(task.id)")
                        completion(error)

                    case .keepRemote:
                        do {
                            // If the remote is a new version of an existing task, find the previous
                            // version and delete its conflicting next version. This will cascade
                            // delete all future versions and their outcomes. Then update the previous
                            // version to the new version from the remote.
                            if let previousUUD = task.previousVersionUUID {
                                let previous: OCKCDTask = try self.fetchObject(uuid: previousUUD)
                                previous.next.map(self.context.delete)

                                let updated = try self.updateTasksWithoutCommitting([task], copyUUIDs: true)
                                self.taskDelegate?.taskStore(self, didUpdateTasks: updated)

                                completion(nil)
                                return
                            }

                            // A new task with the same id was created on both the server
                            // and the local device. Delete the local one and keep the remote.
                            let localTask: OCKCDTask = try self.fetchObject(uuid: local.uuid!)
                            self.context.delete(localTask)
                            let added = try self.createTasksWithoutCommitting([task])
                            self.taskDelegate?.taskStore(self, didAddTasks: added)
                            completion(nil)

                        } catch {
                            completion(error)
                        }

                    case .keepDevice:
                        // No action needs to be taken. When the entity from this
                        // device lands on a peer device, ingesting it will cause
                        // any conflicts to be overwritten.
                        completion(nil)
                    }
                }

                return
            }

            // There is no conflict. This is the simplest case, we can just create a new task.
            if task.previousVersionUUID == nil {
                let newTasks = try createTasksWithoutCommitting([task])
                taskDelegate?.taskStore(self, didAddTasks: newTasks)

            // This is a new version of an existing task. We might need to delete future versions
            // and their outcomes before adding this version in their place. This happens when
            // one node processes a conflict resolution performed on a different node.
            } else {
                let current: OCKCDTask = try self.fetchObject(uuid: task.previousVersionUUID!)
                current.next.map(self.context.delete)
                let updated = try updateTasksWithoutCommitting([task], copyUUIDs: true)
                for update in updated {
                    update.deletedDate == nil ?
                        taskDelegate?.taskStore(self, didUpdateTasks: [update]) :
                        taskDelegate?.taskStore(self, didDeleteTasks: [update])
                }
            }

            completion(nil)

        } catch {
            completion(error)
        }
    }

    /// - Warning: This method must be called on the `context`'s queue.
    private func mergeOutcomeRevision(
        outcome: OCKOutcome,
        vector: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping(Error?) -> Void) {
        do {
            // If the outcome exists on disk already, it means that another device
            // ruled to overwrite this value as part of a conflict resolution.
            if entityExists(OCKCDOutcome.self, uuid: outcome.uuid!) {
                completion(nil)
                return
            }

            // Check if there are any local changes since the last sync
            // that conflict with the revision from the server.
            let localRevision = computeRevision(since: vector.clock(for: self.context.clockID))
                .entities
                .compactMap { $0.value as? OCKOutcome }

            if let current = localRevision.first(where: { $0.conflicts(with: outcome) }) {

                let conflict = OCKMergeConflictDescription(
                    entities: .outcomes(
                        deviceVersion: current,
                        remoteVersion: outcome))

                remote!.chooseConflictResolutionPolicy(conflict) { strategy in
                    self.context.perform {
                        switch strategy {
                        case .abortMerge:
                            completion(OCKStoreError.remoteSynchronizationFailed(
                                reason: "Aborted merge because of conflict in two versions of outcome \(outcome.id)"))

                        case .keepRemote:
                            // We need to delete the local version and add the new remote version.
                            // It's fine to just delete the local version becaues it will never
                            // need to be synchronized. (Assuming there is only one remote endpoint!)
                            self.fetchMatchingOutcomes([outcome]).forEach { object in
                                self.context.delete(object)
                            }

                            do {
                                let updated = try self.createOutcomesWithoutCommiting([outcome])
                                self.outcomeDelegate?.outcomeStore(self, didUpdateOutcomes: updated)
                                completion(nil)
                            } catch {
                                completion(error)
                            }

                        case .keepDevice:
                            // We don't need to do anything. The version from this device
                            // will overwrite the version on the remote when it is pushed.
                            completion(nil)
                        }
                    }
                }

                return
            }

            // It's possible this outcome is for a version of a task that
            // was overwritten when resolving a merge conflict, so we may
            // not need to do anything.
            if entityExists(OCKCDTask.self, uuid: outcome.taskUUID) {

                let existing = fetchMatchingOutcomes([outcome])
                existing.forEach { $0.deletedDate = outcome.createdDate! }

                let updated = existing.map(makeOutcome)

                let created = try createOutcomesWithoutCommiting([outcome])
                let deleted = updated + created.filter { $0.deletedDate != nil }
                let added = created.filter { $0.deletedDate == nil }

                outcomeDelegate?.outcomeStore(self, didDeleteOutcomes: deleted)
                outcomeDelegate?.outcomeStore(self, didAddOutcomes: added)
            }

            completion(nil)

        } catch {
            completion(error)
        }
    }
}

private extension OCKOutcome {
    func conflicts(with other: OCKOutcome) -> Bool {
        taskUUID == other.taskUUID &&
        taskOccurrenceIndex == other.taskOccurrenceIndex
    }
}

private extension Array {
    func split(_ applyCriteria: (Element) -> Bool) -> (Self, Self) {
        var pass = [Element]()
        var fail = [Element]()
        for element in self {
            applyCriteria(element) ?
                pass.append(element) :
                fail.append(element)
        }
        return (pass, fail)
    }
}

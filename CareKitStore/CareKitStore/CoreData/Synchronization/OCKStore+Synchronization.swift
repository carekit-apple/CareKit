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
import os.log


extension NSManagedObjectContext {

    var clockID: UUID {
        get {
            performAndWait {
                return OCKCDClock.fetch(context: self).uuid
            }
        } set {
            performAndWait {
                OCKCDClock.fetch(context: self).uuid = newValue
            }
        }
    }

    var knowledgeVector: OCKRevisionRecord.KnowledgeVector {
        get {
            performAndWait {
                return OCKCDClock.fetch(context: self).vector
            }
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

    func performAndWait<T>(_ work: () throws -> T) throws -> T {
        var result = Result<T, Error>.failure(OCKStoreError.invalidValue(reason: "timeout"))
        performAndWait {
            result = Result(catching: work)
        }
        let value = try result.get()
        return value
    }

    func performAndWait<T>(_ work: () -> T) -> T {
        var value: T!
        performAndWait {
            value = work()
        }
        return value
    }

    func fetchObjects<T: OCKCDObject>(withUUIDs uuids: [UUID]) throws -> [T] {

        guard let entityName = T.entity().name else {
            return []
        }

        let request = NSFetchRequest<T>(entityName: entityName)
        request.fetchLimit = 1

        request.predicate = NSPredicate(
            format: "%K IN %@",
            #keyPath(OCKCDObject.uuid),
            uuids
        )

        let results = try fetch(request)
        return results
    }

    func fetchObject<T: OCKCDObject>(uuid: UUID) throws -> T {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(OCKCDObject.uuid), uuid as CVarArg)
        guard let object = try fetch(request).first else {
            throw OCKStoreError.fetchFailed(reason: "No object \(T.self) for UUID \(uuid)")
        }
        return object
    }
}

extension OCKStore: OCKRemoteSynchronizationDelegate {

    public func remote(
        _ remote: OCKRemoteSynchronizable, didUpdateProgress progress: Double) {

    }

    public func didRequestSynchronization(
        _ remote: OCKRemoteSynchronizable) {
        os_log("Remote requested synchronization", log: .store, type: .debug)
        autoSynchronizeIfRequired()
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
    public func synchronize(completion: @escaping(Error?) -> Void) {
        pullThenPush(completion: completion)
    }

    /// Calls synchronize if the remote is set and requests to notified after each database modification.
    func autoSynchronizeIfRequired() {
        if remote?.automaticallySynchronizes == true {
            pullThenPush { error in
                if let error = error {
                    os_log("Failed to automatically synchronize. %{private}@",
                           log: .store, type: .error, error.localizedDescription)
                }
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

            // 2. Pull and merge revisions
            //    Keep track of what the remote knows so that we can send
            //    it the appropriate revision after resolving conflicts.
            var remoteKnowledge = OCKRevisionRecord.KnowledgeVector()

            remote.pullRevisions(since: self.context.knowledgeVector) { revision in

                remoteKnowledge.merge(with: revision.knowledgeVector)
                self.mergeRevision(revision)

            } completion: { error in

                self.context.perform {

                    if let error = error {
                        os_log("Failed to pull revision. %{private}@",
                               log: .store, type: .error, error as NSError)
                        self.context.rollback()
                        completion(error)
                        return
                    }

                    // 3. Increment the knowledge vector so that all conflict
                    //    revisions applied in the next step count as new for
                    //    the peer.
                    self.context.knowledgeVector.increment(clockFor: self.context.clockID)

                    // 4. Detect and resolve any conflicts that exist. The store
                    //    is a CRDT, so there aren't any conflicts at the data
                    //    layer, but we want to resolve concurrent changes.
                    self.resolveConflicts { error in

                        self.context.perform {
                            do {
                                // 5. Lock in the changes. If this fails, all
                                //    merged changes will be rolled back and
                                //    we'll need to try again later.
                                try self.context.save()

                                // 6. Local revisions will now include any patches
                                //    that were applied during conflict resolution.
                                let localKnowledge = self.context.knowledgeVector

                                let localRevisions = try self.computeRevisions(
                                    since: remoteKnowledge
                                )

                                // 7. Bump knowledge vector to indicate that any
                                //    objects created beyond this point in time
                                //    are considered unknown to the peer.
                                self.context.knowledgeVector.increment(
                                    clockFor: self.context.clockID
                                )
                                
                                // 8. Lock in the changes. If this fails, all
                                //    merged changes will be rolled back and
                                //    we'll need to try again later.
                                try self.context.save()

                                // 9. Push conflict resolutions + local changes to remote
                                remote.pushRevisions(
                                    deviceRevisions: localRevisions,
                                    deviceKnowledge: localKnowledge) { error in

                                    if let error = error {
                                        os_log("Failed to push revision. %{private}@",
                                               log: .store, type: .error, error as NSError)
                                    }
                                    // 10. The sync is still considered successful
                                    //    even if the remote doesn't accept the
                                    //    push. The next time we sync with it, it
                                    //    will still have the same knowledge
                                    //    vector, which means the proper diff will
                                    //    be generated.
                                    self.context.perform {
                                        completion(nil)
                                    }
                                }
                            } catch {
                                self.context.rollback()
                                completion(error)
                            }
                        }
                    }
                }
            }
        }
    }


    func computeRevisions(since vector: OCKRevisionRecord.KnowledgeVector) throws -> [OCKRevisionRecord] {

        var entitiesGroupedByKnowledge: [OCKRevisionRecord.KnowledgeVector: [OCKEntity]] = [:]

        try context.performAndWait {

            for entity in supportedTypes {

                let groupedByKnowledge = try changedQuery(
                    entity: entity.entity(),
                    since: vector
                )

                for (vector, values) in groupedByKnowledge {
                    let existing = entitiesGroupedByKnowledge[vector] ?? []
                    let combined = existing + values.map { $0.entity() }
                    entitiesGroupedByKnowledge[vector] = combined
                }
            }
        }

        let localRevisions = entitiesGroupedByKnowledge.map { knowledge, entities in
            OCKRevisionRecord(entities: entities, knowledgeVector: knowledge)
        }

        return localRevisions
    }

    func mergeRevision(_ revision: OCKRevisionRecord) {

        context.performAndWait {

            self.context.knowledgeVector.merge(with: revision.knowledgeVector)

            revision.entities.map(\.value).forEach { value in
                if entityExists(
                    entity: type(of: value).entity(),
                    uuid: value.uuid) {

                    return
                }

                let object = value.insert(context: self.context)
                object.set(knowledge: revision.knowledgeVector)
            }
        }
    }

    /// - Note: Thread Safe
    private func findNextConflict() throws -> [OCKEntity]? {
        try context.performAndWait { () throws -> [OCKEntity]? in

            for entity in supportedTypes.map({ $0.entity() }) {

                if let conflict = try self.findFirstConflict(entity: entity) {
                    return conflict
                }
            }

            return nil
        }
    }

    /// - Warning: This method must be called on the `context`'s queue.
    ///
    /// Fetches objects that have been created or modified since the given date. These are the objects that need
    /// to be pushed to the server as part of a sync operation.
    private func changedQuery(
        entity: NSEntityDescription,
        since vector: OCKRevisionRecord.KnowledgeVector) throws -> [OCKRevisionRecord.KnowledgeVector: [OCKVersionedObjectCompatible]] {

        let knowledgeKey = #keyPath(OCKCDObject.knowledge)
        let uuidKey = #keyPath(OCKCDKnowledgeElement.uuid)
        let timeKey = #keyPath(OCKCDKnowledgeElement.time)

        let predicates = vector.processes.map { uuid, time -> NSPredicate in

            let greaterSubquery = "SUBQUERY(\(knowledgeKey), $element, $element.\(uuidKey) == %@ AND $element.\(timeKey) > %lld).@count > 0"
            let greaterPredicate = NSPredicate(
                format: greaterSubquery,
                uuid as CVarArg, time
            )

            return greaterPredicate
        }

        let missingSubquery = "SUBQUERY(\(knowledgeKey), $element, $element.\(uuidKey) IN %@).@count == 0"
        let missingPredicate = NSPredicate(
            format: missingSubquery,
            Array(vector.processes.keys)
        )

        let request = NSFetchRequest<OCKCDVersionedObject>(entityName: entity.name!)

        request.predicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: predicates + [missingPredicate]
        )

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \OCKCDObject.updatedDate, ascending: false)
        ]

        request.returnsObjectsAsFaults = false

        let objects = try context.fetch(request)
        let grouped = Dictionary(grouping: objects, by: { $0.knowledgeVector() })
        let values = grouped.mapValues({ $0.map { $0.makeValue() } })
        return values
    }

    private func findFirstConflict(entity: NSEntityDescription) throws -> [OCKEntity]? {
        let request = NSFetchRequest<OCKCDVersionedObject>(entityName: entity.name!)
        request.predicate = NSPredicate(format: "%K.@count == 0", #keyPath(OCKCDVersionedObject.next))
        request.returnsObjectsAsFaults = false

        let tips = try context.fetch(request)
        let grouped = Dictionary(grouping: tips, by: \.id).map(\.1)
        let multiple = grouped.first(where: { $0.count > 1 })
        let entities = multiple?.map { $0.makeValue().entity() }
        return entities
    }

    func resolveConflicts(completion: @escaping (Error?) -> Void) {
        do {
            guard let next = try findNextConflict() else {
                completion(nil)
                return
            }

            remote!.chooseConflictResolution(conflicts: next) { result in
                self.context.perform {
                    do {
                        let keeper = try result.get()
                        try self.updateValue(keeper.value)
                        self.resolveConflicts(completion: completion)
                    } catch {
                        completion(error)
                    }
                }
            }
        } catch {
            completion(error)
        }
    }
}


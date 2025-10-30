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

import CoreData
import Foundation

extension OCKStore {

    struct TransactionResult<T: Sendable>: Sendable {
        var inserts: [T] = []
        var updates: [T] = []
        var deletes: [T] = []
    }

    func fetchValues<T>(
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor],
        offset: Int,
        limit: Int?,
        completion: @escaping OCKResultClosure<[T]>)
        where T: OCKVersionedObjectCompatible {

        context.perform {
            do {
                let request = NSFetchRequest<OCKCDVersionedObject>(
                    entityName: T.entity().name!)
                request.predicate = predicate
                request.sortDescriptors = sortDescriptors
                request.fetchLimit = limit ?? 0
                request.fetchOffset = offset
                request.returnsObjectsAsFaults = false

                let fetched = try self.context.fetch(request)

                let values = fetched.map { $0.makeValue() as! T }

                completion(.success(values))
            } catch {
                completion(.failure(.fetchFailed(reason: error.localizedDescription)))
            }
        }
    }

    func transaction<T: OCKVersionedObjectCompatible>(
        inserts: [T],
        updates: [T],
        deletes: [T],
        preInsertValidate: @escaping () throws -> Void = { },
        preUpdateValidate: @escaping () throws -> Void = { },
        preSaveValidate: @escaping () throws -> Void = { },
        completion: @escaping OCKResultClosure<TransactionResult<T>>) {

        context.perform {
            do {
                try preInsertValidate()
                var result = TransactionResult<T>()

                // Perform inserts
                if !inserts.isEmpty {
                    try self.validateNew(inserts)
                    result.inserts = inserts
                        .map { $0.insert(context: self.context) }
                        .map { $0.makeValue() as! T }
                }

                // Perform updates
                try preUpdateValidate()
                
                if !updates.isEmpty {
                    try self.validateUpdates(updates)
                    result.updates = try updates
                        .map(self.updateValue)
                        .map { $0.makeValue() as! T }
                }

                // Perform deletes
                if !deletes.isEmpty {
                    result.deletes = try deletes
                        .map(self.updateValue)
                        .map { delete in
                            delete.deletedDate = Date()
                            return delete.makeValue() as! T
                        }
                }

                try preSaveValidate()
                try self.context.save()
                completion(.success(result))

            } catch {
                self.context.rollback()
                completion(.failure(.invalidValue(reason: error.localizedDescription)))
            }
        }
    }

    @discardableResult
    func updateValue(_ value: OCKVersionedObjectCompatible) throws -> OCKCDVersionedObject {

        let name = type(of: value).entity().name!

        let request = NSFetchRequest<OCKCDVersionedObject>(entityName: name)
        request.predicate = OCKCDVersionedObject.headerPredicate([value])
        request.returnsObjectsAsFaults = false

        let tips = try context.fetch(request)

        guard !tips.isEmpty else {
            throw OCKStoreError.updateFailed(reason: "No previous version exists")
        }


        let update = value.insert(context: context)
        update.previous = Set(tips)
        update.uuid = UUID()
        update.updatedDate = Date()

        return update
    }

    func entityExists(entity: NSEntityDescription, uuid: UUID) -> Bool {
        let request = NSFetchRequest<OCKCDObject>(entityName: entity.name!)
        request.predicate = NSPredicate(format: "%K == %@",
                                        #keyPath(OCKCDObject.uuid),
                                        uuid as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.count(for: request) > 0
        } catch {
            return false
        }
    }

    private func validateNew<T: OCKVersionedObjectCompatible>(_ objects: [T]) throws {
        let ids = objects.map { $0.id }
        let uuids = objects.map { $0.uuid }

        guard Set(ids).count == ids.count else {
            throw OCKStoreError.invalidValue(reason: "Identifiers contains duplicate values! \(ids)")
        }

        let existingPredicate = NSPredicate(
            format: "(%K IN %@) OR (%K IN %@)",
            #keyPath(OCKCDVersionedObject.id), ids,
            #keyPath(OCKCDVersionedObject.uuid), uuids
        )

        let request = NSFetchRequest<OCKCDVersionedObject>(entityName: T.entity().name!)
        request.predicate = existingPredicate

        let existing = try context.performAndWait {
            try context.count(for: request)
        }

        if existing > 0 {
            throw OCKStoreError.addFailed(reason: "\(T.entity().name!) with conflicting IDs or UUIDs already exists!")
        }
    }

    private func validateUpdates<T: OCKVersionedObjectCompatible>(_ values: [T]) throws {
        let ids = Set(values.map(\.id))

        guard ids.count == values.count else {
            throw OCKStoreError.invalidValue(reason: "Identifiers contains duplicate values! [\(ids)]")
        }

        // Make sure the versions about to be updated aren't deleted already
        let deletedPredicate = NSPredicate(
            format: "(%K IN %@) AND (%K != nil)",
            #keyPath(OCKCDVersionedObject.id), ids,
            #keyPath(OCKCDVersionedObject.deletedDate)
        )

        let request = NSFetchRequest<OCKCDVersionedObject>(entityName: T.entity().name!)
        request.predicate = deletedPredicate

        let deletes = try context.performAndWait {
            try context.count(for: request)
        }

        if deletes > 0 {
            throw OCKStoreError.updateFailed(reason: "\(T.entity().name!) with one of the following ids has been deleted already: [\(ids)]")
        }
    }
}

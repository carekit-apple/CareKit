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

/// An enumerator specifying the type of stores that may be chosen.
public enum OCKCoreDataStoreType {

    /// An in memory store runs in RAM. It is fast and is not persisted between app launches.
    /// Its primary use case is for testing.
    case inMemory

    /// A store that persists data to disk. This option should be used in almost all cases.
    case onDisk

    internal var stringValue: String {
        switch self {
        case .inMemory: return NSInMemoryStoreType
        case .onDisk:   return NSSQLiteStoreType
        }
    }
}

internal protocol OCKCoreDataStoreProtocol: AnyObject {
    var name: String { get }
    var storeType: OCKCoreDataStoreType { get }
    var context: NSManagedObjectContext { get }
    var configuration: OCKStoreConfiguration { get }

    func autoSynchronizeIfRequired()
}

extension OCKCoreDataStoreProtocol {

    var storeDirectory: URL {
        NSPersistentContainer.defaultDirectoryURL()
    }

    var storeURL: URL {
        storeDirectory.appendingPathComponent(name + ".sqlite")
    }

    var walFileURL: URL {
        storeDirectory.appendingPathComponent(name + ".sqlite-wal")
    }

    var shmFileURL: URL {
        storeDirectory.appendingPathComponent(name + ".sqlite-shm")
    }

    func makePersistentContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: self.name, managedObjectModel: sharedManagedObjectModel)
        let descriptor = NSPersistentStoreDescription()
        descriptor.url = storeURL
        descriptor.type = storeType.stringValue
        descriptor.shouldAddStoreAsynchronously = false
        descriptor.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        container.persistentStoreDescriptions = [descriptor]
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? { fatalError("Unresolved error \(error), \(error.userInfo)") }
            if self.storeType == .onDisk {
                do {
                    guard var storeUrl = descriptor.url else { throw OCKStoreError.invalidValue(reason: "Bad URL") }
                    var resourceValues = URLResourceValues()
                    resourceValues.isExcludedFromBackup = true
                    try storeUrl.setResourceValues(resourceValues)
                } catch {
                    fatalError("Failed to setup security for the care store. \(error)")
                }
            }
        })
        return container
    }

    func fetchObject<T: OCKCDObject>(uuid: UUID) throws -> T {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(OCKCDObject.uuid), uuid as CVarArg)
        guard let object = try context.fetch(request).first else {
            throw OCKStoreError.fetchFailed(reason: "No object \(T.self) for UUID \(uuid)")
        }
        return object
    }

    func fetchFromStore<T: OCKCDVersionedObject>(
        _ type: T.Type,
        where predicate: NSPredicate,
        configureFetchRequest: ((NSFetchRequest<T>) -> Void) = { _ in }) -> [T] {

        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \OCKCDVersionedObject.effectiveDate, ascending: false)]
        request.predicate = predicate

        configureFetchRequest(request)

        guard let results = try? context.fetch(request) else { fatalError("This should never fail") }
        return results
    }

    func fetchHeads<T: OCKCDVersionedObject>(_ type: T.Type, ids: [String]) -> [T] {
        return fetchFromStore(type, where: OCKCDVersionedObject.headerPredicate(for: ids)) { request in
            request.fetchLimit = ids.count
            request.returnsObjectsAsFaults = false
        }
    }

    func entityExists<T: OCKCDObject>(_ type: T.Type, uuid: UUID) -> Bool {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "%K == %@",
                                        #keyPath(OCKCDObject.uuid),
                                        uuid as CVarArg)
        request.fetchLimit = 1
        return try! context.count(for: request) > 0
    }

    func validateNew<T: OCKCDVersionedObject, U: OCKVersionedObjectCompatible>(_ type: T.Type, _ objects: [U]) throws {
        let ids = objects.map{$0.id}
        let uuids = objects.map{$0.uuid}

        guard Set(ids).count == ids.count else {
            throw OCKStoreError.invalidValue(reason: "Identifiers contains duplicate values! \(ids)")
        }

        let existingPredicate = NSPredicate(format: "(%K IN %@ OR %K IN %@) AND (%K == nil)",
                                            #keyPath(OCKCDVersionedObject.id), ids,
                                            #keyPath(OCKCDVersionedObject.uuid), uuids,
                                            #keyPath(OCKCDVersionedObject.deletedDate))

        let existingIDs = fetchFromStore(T.self, where: existingPredicate, configureFetchRequest: { request in
            request.propertiesToFetch = [#keyPath(OCKCDVersionedObject.id)]
        }).map { $0.id }

        guard existingIDs.isEmpty else {
            let objectClass = String(describing: T.self)
            throw OCKStoreError.invalidValue(reason: "\(objectClass) with IDs [\(Set(existingIDs))] already exists!")
        }
    }

    func validateUpdateIdentifiers(_ ids: [String]) throws {
        guard Set(ids).count == ids.count else {
            throw OCKStoreError.invalidValue(reason: "Identifiers contains duplicate values! [\(ids)]")
        }
    }

    func performVersionedUpdate<Value, Object>(values: [Value], addNewVersion: (Value) -> Object) throws -> [Object]
        where Value: OCKVersionedObjectCompatible, Object: OCKCDVersionedObject {

        let currentVersions = fetchHeads(Object.self, ids: values.map { $0.id })
        return try values.map { value -> Object in
            guard let current = currentVersions.first(where: { $0.id == value.id }) else {
                throw OCKStoreError.invalidValue(reason: "No matching object could be found for id: \(value.id)")
            }
            let newVersion = addNewVersion(value)
            newVersion.previous = current
            newVersion.uuid = UUID()
            return newVersion
        }
    }

    func performDeletion<Value, Object>(values: [Value], addNewVersion: (Value) -> Object) throws -> [Object]
        where Value: OCKVersionedObjectCompatible, Object: OCKCDVersionedObject {
        let newVersions = try performVersionedUpdate(values: values, addNewVersion: addNewVersion)
        newVersions.forEach { $0.deletedDate = Date() }
        return newVersions
    }

    func tombstone(versionedObject: OCKCDVersionedObject) {
        versionedObject.next.map(context.delete)
        versionedObject.previous = nil
        versionedObject.deletedDate = Date()
        versionedObject.updatedDate = Date()
    }

    func defaultSortDescritors() -> [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \OCKCDObject.createdDate, ascending: false)]
    }
}

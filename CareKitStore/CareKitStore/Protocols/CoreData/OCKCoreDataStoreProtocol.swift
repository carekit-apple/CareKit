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

    /// An in memory store runs in RAM. It is very fast, but cannot support large datasets and is not persisted between app launches.
    /// Its primary use case is for testing.
    case inMemory

    /// A store that persists data to disk. This option should be in almost all cases.
    case onDisk

    internal var stringValue: String {
        switch self {
        case .inMemory: return NSInMemoryStoreType
        case .onDisk:   return NSSQLiteStoreType
        }
    }
}

internal protocol OCKCoreDataStoreProtocol {
    var name: String { get }
    var storeType: OCKCoreDataStoreType { get }
    var context: NSManagedObjectContext { get }
    var configuration: OCKStoreConfiguration { get }
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

    func objectID(for versionID: OCKLocalVersionID) throws -> NSManagedObjectID {
        guard let coordinator = context.persistentStoreCoordinator else {
            throw OCKStoreError.invalidValue(reason: "Store coordinator not initialized") }
        guard let url = URL(string: versionID.stringValue) else {
            throw OCKStoreError.invalidValue(reason: "versionID is not a URL: \(versionID)") }
        guard let objectId = coordinator.managedObjectID(forURIRepresentation: url)
            else { throw OCKStoreError.fetchFailed(reason: "No matching NSManagedObjectID for versionID: \(versionID)") }
        return objectId
    }

    func fetchObject<T: NSManagedObject>(havingLocalID versionID: OCKLocalVersionID) throws -> T {
        guard let object = try context.existingObject(with: try objectID(for: versionID)) as? T else {
            throw OCKStoreError.invalidValue(reason: "versionID could not be converted to NSManagedObjectID: \(versionID)")
        }
        return object
    }

    func retrieveObjectIDs<T>(for objects: [T]) throws -> [NSManagedObjectID] where T: OCKObjectCompatible {
        let localIDs = objects.compactMap { $0.localDatabaseID }
        guard localIDs.count == objects.count else { throw OCKStoreError.invalidValue(reason: "Missing localDatabaseID!") }
        return try localIDs.map(objectID)
    }

    func performVersionedUpdate<Value, Object>(values: [Value], addNewVersion: (Value) -> Object) throws -> [Object]
        where Value: OCKVersionedObjectCompatible, Object: OCKCDVersionedObject {

        let currentVersions: [Object] = Object.fetchHeads(ids: values.map { $0.id }, in: context)
        return try values.map { value -> Object in
            guard let current = currentVersions.first(where: { $0.id == value.id }) else {
                throw OCKStoreError.invalidValue(reason: "No matching object could be found for id: \(value.id)")
            }
            let newVersion = addNewVersion(value)
            newVersion.previous = current
            return newVersion
        }
    }

    func performDeletion<Value, Object>(values: [Value]) throws -> [Object]
        where Value: OCKVersionedObjectCompatible, Object: OCKCDVersionedObject {
        let currentVersions: [Object] = Object.fetchHeads(ids: values.map { $0.id }, in: context)
        currentVersions.forEach { $0.deletedDate = Date() }
        return currentVersions
    }
}

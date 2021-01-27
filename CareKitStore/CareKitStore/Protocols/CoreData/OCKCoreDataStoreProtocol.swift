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
public enum OCKCoreDataStoreType: Equatable {

    /// An in memory store runs in RAM. It is fast and is not persisted between app launches.
    /// Its primary use case is for testing.
    case inMemory

    /// A store that persists data to disk. This option should be used in almost all cases.
    case onDisk(protection: FileProtectionType = .complete)

    var stringValue: String {
        switch self {
        case .inMemory:
            return NSInMemoryStoreType
        case .onDisk:
            return NSSQLiteStoreType
        }
    }

    var securityClass: FileProtectionType {
        switch self {
        case .inMemory:
            return .none
        case let .onDisk(protection):
            return protection
        }
    }
}

internal protocol OCKCoreDataStoreProtocol: AnyObject {
    var name: String { get }
    var securityApplicationGroupIdentifier: String? { get }
    var storeType: OCKCoreDataStoreType { get }
    var _context: NSManagedObjectContext? { get set }
    var _container: NSPersistentContainer? { get set }
    var configuration: OCKStoreConfiguration { get }

    func autoSynchronizeIfRequired()
}

// The managed object model can only be loaded once
// per app invocation, so we load it here and reuse
// the shared MoM each time a store is instantiated.
let sharedManagedObjectModel: NSManagedObjectModel = {
    //#if SWIFT_PACKAGE
    //let bundle = Bundle.module // Use the SPM package's module
    //#else
    let bundle = Bundle(for: OCKStore.self)
    //#endif
    let modelUrl = bundle.url(forResource: "CareKitStore", withExtension: "momd")!
    let mom = NSManagedObjectModel(contentsOf: modelUrl)!
    return mom
}()

extension OCKCoreDataStoreProtocol {

    var storeDirectory: URL {
        guard let identifier = securityApplicationGroupIdentifier else {
            return NSPersistentContainer.defaultDirectoryURL()
        }

        // A security group allows a sandboxed app to share files across apps and app extensions
        if let securityGroup = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return securityGroup
        }

        fatalError(
            "Could not find a container for the specified app group identifier: \(identifier)"
        )
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

    func context() throws -> NSManagedObjectContext {
        _context = try _context ?? persistentContainer().newBackgroundContext()
        return _context!
    }

    func persistentContainer() throws -> NSPersistentContainer {
        _container = try _container ?? makePersistentContainer()
        return _container!
    }

    func performWithContextAndWait<T>(_ closure: (NSManagedObjectContext) throws -> T) throws -> T {

        let context = try self.context()

        var value: T!
        var thrownError: Error?

        context.performAndWait {
            do {
                value = try closure(context)
            } catch {
                thrownError = error
            }
        }

        if let error = thrownError {
            throw error
        }

        return value
    }

    private func makePersistentContainer() throws -> NSPersistentContainer {
        var loadError: Error?

        let container = NSPersistentContainer(name: self.name, managedObjectModel: sharedManagedObjectModel)
        let descriptor = NSPersistentStoreDescription()
        descriptor.url = storeURL
        descriptor.type = storeType.stringValue
        descriptor.shouldAddStoreAsynchronously = false
        descriptor.setOption(storeType.securityClass as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        container.persistentStoreDescriptions = [descriptor]

        // This closure runs synchronously because of the settings above
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                loadError = error
                return
            }

            if case .onDisk = self.storeType {
                do {
                    guard var storeUrl = descriptor.url else {
                        loadError = OCKStoreError.invalidValue(reason: "Bad URL")
                        return
                    }
                    var resourceValues = URLResourceValues()
                    resourceValues.isExcludedFromBackup = true
                    try storeUrl.setResourceValues(resourceValues)
                } catch {
                    loadError = error
                }
            }
        })

        if let error = loadError {
            throw error
        }

        return container
    }

    func fetchObject<T: OCKCDObject>(uuid: UUID) throws -> T {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(OCKCDObject.uuid), uuid as CVarArg)
        guard let object = try context().fetch(request).first else {
            throw OCKStoreError.fetchFailed(reason: "No object \(T.self) for UUID \(uuid)")
        }
        return object
    }

    func fetchFromStore<T: OCKCDVersionedObject>(
        _ type: T.Type,
        where predicate: NSPredicate,
        configureFetchRequest: ((NSFetchRequest<T>) -> Void) = { _ in }) throws -> [T] {

        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \OCKCDVersionedObject.effectiveDate, ascending: false)]
        request.predicate = predicate

        configureFetchRequest(request)

        let results = try context().fetch(request)

        return results
    }

    func fetchHeads<T: OCKCDVersionedObject>(_ type: T.Type, ids: [String]) throws -> [T] {
        return try fetchFromStore(type, where: OCKCDVersionedObject.headerPredicate(for: ids)) { request in
            request.fetchLimit = ids.count
            request.returnsObjectsAsFaults = false
        }
    }

    func entityExists<T: OCKCDObject>(_ type: T.Type, uuid: UUID) throws -> Bool {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "%K == %@",
                                        #keyPath(OCKCDObject.uuid),
                                        uuid as CVarArg)
        request.fetchLimit = 1

        return try context().count(for: request) > 0
    }

    func validateNew<T: OCKCDVersionedObject, U: OCKVersionedObjectCompatible>(_ type: T.Type, _ objects: [U]) throws {
        let ids = objects.map { $0.id }
        let uuids = objects.map { $0.uuid }

        guard Set(ids).count == ids.count else {
            throw OCKStoreError.invalidValue(reason: "Identifiers contains duplicate values! \(ids)")
        }

        let existingPredicate = NSPredicate(format: "(%K IN %@ OR %K IN %@) AND (%K == nil)",
                                            #keyPath(OCKCDVersionedObject.id), ids,
                                            #keyPath(OCKCDVersionedObject.uuid), uuids,
                                            #keyPath(OCKCDVersionedObject.deletedDate))

        let existingIDs = try fetchFromStore(T.self, where: existingPredicate, configureFetchRequest: { request in
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

    func performVersionedUpdate<Value, Object>(values: [Value], addNewVersion: (Value) throws -> Object) throws -> [Object]
        where Value: OCKVersionedObjectCompatible, Object: OCKCDVersionedObject {

        let currentVersions = try fetchHeads(Object.self, ids: values.map { $0.id })
        return try values.map { value -> Object in
            guard let current = currentVersions.first(where: { $0.id == value.id }) else {
                throw OCKStoreError.invalidValue(reason: "No matching object could be found for id: \(value.id)")
            }
            current.logicalClock = Int64(try context().clockTime)
            let newVersion = try addNewVersion(value)
            newVersion.previous = current
            newVersion.uuid = UUID()
            return newVersion
        }
    }

    func performDeletion<Value, Object>(values: [Value], addNewVersion: (Value) throws -> Object) throws -> [Object]
        where Value: OCKVersionedObjectCompatible, Object: OCKCDVersionedObject {
        let newVersions = try performVersionedUpdate(values: values, addNewVersion: addNewVersion)
        newVersions.forEach { $0.deletedDate = Date() }
        return newVersions
    }

    func tombstone(versionedObject: OCKCDVersionedObject) throws {
        versionedObject.next.map(try context().delete)
        versionedObject.previous = nil
        versionedObject.deletedDate = Date()
        versionedObject.updatedDate = Date()
    }

    func defaultSortDescritors() -> [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \OCKCDObject.createdDate, ascending: false)]
    }
}

extension OCKCoreDataStoreProtocol where Self: OCKAnyResettableStore {

    func deleteAllContents() throws {
        try performWithContextAndWait { context -> Void in
            try OCKEntity
                .EntityType.allCases
                .map(\.coreDataType)
                .forEach(deleteAll)
            try context.save()
        }

        resetDelegate?.storeDidReset(self)
    }

    private func deleteAll<T: NSManagedObject>(entity: T.Type) throws {
        try performWithContextAndWait { context -> Void in

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: String(describing: entity))
            fetchRequest.includesPropertyValues = false
            fetchRequest.includesSubentities = false

            let objects = try context.fetch(fetchRequest)
            objects.forEach { context.delete($0) }
        }
    }
}

private extension OCKEntity.EntityType {
    var coreDataType: NSManagedObject.Type {
        switch self {
        case .patient: return OCKCDPatient.self
        case .carePlan: return OCKCDCarePlan.self
        case .contact: return OCKCDContact.self
        case .task: return OCKCDTask.self
        case .outcome: return OCKCDOutcome.self
        }
    }
}

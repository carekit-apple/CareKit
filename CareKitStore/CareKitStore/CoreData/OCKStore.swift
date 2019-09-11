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
import Foundation

/// The default store used in CareKit. The underlying database used is CoreData.
open class OCKStore: OCKStoreProtocol {
    /// The delegate receives callbacks when the contents of the store are modified. In `CareKit` apps, the delegate should always be set to
    ///  an instance of `OCKSynchronizedStoreManager`.
    public weak var delegate: OCKStoreDelegate?

    /// The configuration can be modified to enable or disable versioning of database entities.
    public var configuration = OCKStoreConfiguration()

    /// Two instances of `OCKStore` are considered to be equal if they have the same name and store type.
    public static func == (lhs: OCKStore, rhs: OCKStore) -> Bool {
        return lhs.name == rhs.name && lhs.storeType == rhs.storeType
    }

    /// The name of the store. When the store type is `onDisk`, this name will be used for the SQLite filename.
    public let name: String

    /// The store type determines where data is stored. Generally `onDisk` should be chosen in order to persist data, but `inMemory` may be useful
    /// for development and testing purposes.
    private let storeType: StoreType

    /// True by default. Setting to false will enforce that all database entities have the expected relationships.
    /// Specifically, it will cause errors to be throw if any care plan's patient is not specified, and task's care
    /// plan is not specified, any contact's care plan is not specified, or any outcome's task is not specified.
    public var allowsEntitiesWithMissingRelationships = true

    /// Initialize a new store by specifying its name and store type. Store's with conflicting names and types must not be created.
    ///
    /// - Parameters:
    ///   - name: A unique name for the store. It will be used for the filename if stored on disk.
    ///   - type: The type of store to be used.
    public init(name: String, type: StoreType = .onDisk) {
        self.storeType = type
        self.name = name
    }

    /// An enumerator specifying the type of stores that may be chosen.
    public enum StoreType {
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

    internal static var managedObjectModel = makeManagedObjectModel()

    internal lazy var persistentContainer: NSPersistentContainer = {
        let model = OCKStore.managedObjectModel
        let container = NSPersistentContainer(name: self.name, managedObjectModel: model)
        let descriptor = NSPersistentStoreDescription()
        descriptor.url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(name + ".sqlite")
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
    }()

    internal lazy var context: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()

    internal func fetchObject<T: NSManagedObject>(havingLocalID versionID: OCKLocalVersionID) throws -> T {
        guard let object = try context.existingObject(with: try objectID(for: versionID)) as? T else {
            throw OCKStoreError.invalidValue(reason: "versionID could not be converted to NSManagedObjectID: \(versionID)")
        }
        return object
    }

    // MARK: Internal

    internal func objectID(for versionID: OCKLocalVersionID) throws -> NSManagedObjectID {
        guard let coordinator = context.persistentStoreCoordinator else {
            throw OCKStoreError.invalidValue(reason: "Store coordinator not initialized") }
        guard let url = URL(string: versionID.stringValue) else {
            throw OCKStoreError.invalidValue(reason: "versionID is not a URL: \(versionID)") }
        guard let objectId = coordinator.managedObjectID(forURIRepresentation: url)
            else { throw OCKStoreError.fetchFailed(reason: "No matching NSManagedObjectID for versionID: \(versionID)") }
        return objectId
    }

    internal func retrieveObjectIDs<T>(for objects: [T]) throws -> [NSManagedObjectID] where T: OCKLocalPersistable {
        let localIDs = objects.compactMap { $0.localDatabaseID }
        guard localIDs.count == objects.count else { throw OCKStoreError.invalidValue(reason: "Missing localDatabaseID!") }
        return try localIDs.map(objectID(for:))
    }

    internal func performUnversionedUpdate<Value, Object>(values: [Value], update: (Value, Object) -> Void) throws -> [Object]
        where Value: OCKVersionable, Object: OCKCDVersionedObject {
        let currentVersions: [Object] = Object.fetchHeads(identifiers: values.map { $0.identifier }, in: context)
        for value in values {
            guard let current = currentVersions.first(where: { $0.identifier == value.identifier }) else {
                throw OCKStoreError.invalidValue(reason: "No matching object could be found for identifier: \(value.identifier)")
            }
            update(value, current)
        }
        return currentVersions
    }

    internal func performVersionedUpdate<Value, Object>(values: [Value],
                                                        addNewVersion: (Value) -> Object) throws -> [Object]
        where Value: OCKVersionable, Object: OCKCDVersionedObject {
        let currentVersions: [Object] = Object.fetchHeads(identifiers: values.map { $0.identifier }, in: context)
            return try values.map { value -> Object in
                guard let current = currentVersions.first(where: { $0.identifier == value.identifier }) else {
                    throw OCKStoreError.invalidValue(reason: "No matching object could be found for identifier: \(value.identifier)")
                }
                let newVersion = addNewVersion(value)
                newVersion.previous = current
                return newVersion
            }
    }

    internal func makeSchedule(from objects: Set<OCKCDScheduleElement>) -> OCKSchedule {
        return OCKSchedule(composing: objects.map { object -> OCKScheduleElement in
            return OCKScheduleElement(start: object.startDate, end: object.endDate,
                                      interval: object.interval, text: object.text,
                                      targetValues: object.targetValues.map(makeValue),
                                      duration: object.duration, isAllDay: object.isAllDay)
        })
    }

    internal func makeValue(from object: OCKCDOutcomeValue) -> OCKOutcomeValue {
        assert(object.localDatabaseID != nil, "You shouldn't be calling this method with an object that hasn't been saved yet!")
        var value = OCKOutcomeValue(object.value, units: object.units)
        value.index = object.index?.intValue
        value.copyCommonValues(from: object)
        return value
    }
}

internal extension NSPredicate {
    func including(groupIdentifiers: [String]) -> NSPredicate {
        let groupPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.groupIdentifier), groupIdentifiers)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [self, groupPredicate])
    }

    func including(tags: [String]) -> NSPredicate {
        let tagsPredicate = NSPredicate(format: "SOME %K IN %@", #keyPath(OCKCDObject.tags), tags)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [self, tagsPredicate])
    }
}

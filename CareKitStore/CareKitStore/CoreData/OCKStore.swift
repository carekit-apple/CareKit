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
import os.log

/// An enumerator specifying the type of stores that may be chosen.
public enum OCKCoreDataStoreType: Equatable {

    /// An in memory store runs in RAM. It is fast and is not persisted between app launches.
    /// Its primary use case is for testing.
    case inMemory

    /// A store that persists data to disk. This option should be used in almost all cases.
    case onDisk(protection: FileProtectionType = .complete)

    var securityClass: FileProtectionType {
        switch self {
        case .inMemory:
            return .none
        case let .onDisk(protection):
            return protection
        }
    }
}

// The managed object model can only be loaded once
// per app invocation, so we load it here and reuse
// the shared MoM each time a store is instantiated.
let sharedManagedObjectModel: NSManagedObjectModel = {
    #if SWIFT_PACKAGE
    let bundle = Bundle.module // Use the SPM package's module
    #else
    let bundle = Bundle(for: OCKStore.self)
    #endif
    let modelUrl = bundle.url(forResource: "CareKitStore", withExtension: "momd")!
    let mom = NSManagedObjectModel(contentsOf: modelUrl)!
    return mom
}()

/// The default store used in CareKit. The underlying database used is CoreData.
open class OCKStore: OCKStoreProtocol, Equatable {

    /// A list of all the types that `OCKStore` supports.
    let supportedTypes: [OCKVersionedObjectCompatible.Type] = [
        OCKPatient.self,
        OCKCarePlan.self,
        OCKContact.self,
        OCKTask.self,
        OCKHealthKitTask.self,
        OCKOutcome.self
    ]


    /// The delegate receives callbacks when the contents of the patient store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var patientDelegate: OCKPatientStoreDelegate? {
        fatalError("Property is unavailable")
    }

    /// The delegate receives callbacks when the contents of the care plan store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var carePlanDelegate: OCKCarePlanStoreDelegate? {
        fatalError("Property is unavailable")
    }

    /// The delegate receives callbacks when the contents of the contacts store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var contactDelegate: OCKContactStoreDelegate? {
        fatalError("Property is unavailable")
    }

    /// The delegate receives callbacks when the contents of the tasks store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var taskDelegate: OCKTaskStoreDelegate? {
        fatalError("Property is unavailable")
    }

    /// The delegate receives callbacks when the contents of the outcome store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var outcomeDelegate: OCKOutcomeStoreDelegate? {
        fatalError("Property is unavailable")
    }

    /// The delegate receives callbacks when the contents of the store are reset.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    @available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
    public weak var resetDelegate: OCKResetDelegate? {
        fatalError("Property is unavailable")
    }


    /// Two instances of `OCKStore` are considered to be equal if they have the same name and store type.
    public static func == (lhs: OCKStore, rhs: OCKStore) -> Bool {
        lhs.name == rhs.name && lhs.storeType == rhs.storeType
    }

    /// The name of the store. When the store type is `onDisk`, this name will be used for the SQLite filename.
    public let name: String

    /// App group identifier for a sandboxed app that shares files with other apps from the same developer.
    public let securityApplicationGroupIdentifier: String?

    /// The store type determines where data is stored. Generally `onDisk` should be chosen in order to persist data, but `inMemory` may be useful
    /// for development and testing purposes.
    internal let storeType: OCKCoreDataStoreType

    /// A remote store synchronizer.
    internal let remote: OCKRemoteSynchronizable?

    private lazy var persistentContainer = NSPersistentContainer(
        name: self.name,
        managedObjectModel: sharedManagedObjectModel
    )

    private lazy var _context = persistentContainer.newBackgroundContext()

    private var isStoreLoaded = false

    var context: NSManagedObjectContext {
        if isStoreLoaded {
            return _context
        } else {
            isStoreLoaded = loadStore(into: persistentContainer)
            return _context
        }
    }

    private var storeDirectory: URL {
        if storeType == .inMemory {
            return URL(fileURLWithPath: "/dev/null")
        }
        
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

    /// Initialize a new store by specifying its name and store type. Store's with conflicting names and types must not be created.
    ///
    /// - Parameters:
    ///   - name: A unique name for the store. It will be used for the filename if stored on disk.
    ///   - securityApplicationGroupIdentifier: App group identifier for a sandboxed app that shares files with other apps
    ///                                         from the same developer. See [Adding an App To an App Group](1).
    ///   - type: The type of store to be used. `.onDisk` is used by default.
    ///   - remote: A store synchronization endpoint.
    ///
    /// [1]: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW19
    public init(
        name: String,
        securityApplicationGroupIdentifier: String? = nil,
        type: OCKCoreDataStoreType = .onDisk(),
        remote: OCKRemoteSynchronizable? = nil
    ) {
        self.storeType = type
        self.name = name
        self.securityApplicationGroupIdentifier = securityApplicationGroupIdentifier
        self.remote = remote
        self.remote?.delegate = remote?.delegate ?? self

        NotificationCenter.default.addObserver(
            self, selector: #selector(contextDidSave(_:)),
            name: .NSManagedObjectContextDidSave,
            object: context)
    }

    /// Completely deletes the store and all its files from disk.
    ///
    /// You should not attempt to call any other methods an instance of `OCKStore`
    /// after it has been deleted.
    public func delete() throws {
        try persistentContainer
            .persistentStoreCoordinator
            .destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)

        if case .onDisk = storeType {
            try FileManager.default.removeItem(at: storeURL)
            try FileManager.default.removeItem(at: shmFileURL)
            try FileManager.default.removeItem(at: walFileURL)
        }
    }

    /// Deletes the contents of the store, resetting it to its initial state.
    public func reset() throws {

        try context.performAndWait {
            for name in supportedTypes.map({ $0.entity().name! }) {
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: name)
                fetchRequest.includesPropertyValues = false
                fetchRequest.includesSubentities = false

                let objects = try self.context.fetch(fetchRequest)
                objects.forEach { self.context.delete($0) }
            }
            try self.context.save()
        }
    }

    private func loadStore(into container: NSPersistentContainer) -> Bool {

        let descriptor = NSPersistentStoreDescription()
        descriptor.url = storeURL
        descriptor.type = NSSQLiteStoreType
        descriptor.shouldAddStoreAsynchronously = false
        descriptor.setOption(storeType.securityClass as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        container.persistentStoreDescriptions = [descriptor]

        // This closure runs synchronously because of the settings above
        var loadError: Error?

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
            os_log("Failed to load CareKit's store. %{private}@",
                   log: .store, type: .fault, error as NSError)
            return false
        }

        return true
    }

    @objc
    private func contextDidSave(_ notification: Notification) {
        guard let inserts = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> else {
            return
        }

        let objects = inserts.compactMap { $0 as? OCKCDVersionedObject }
        if !objects.isEmpty {
            autoSynchronizeIfRequired()
        }
    }
}

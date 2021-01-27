/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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
@testable import CareKitStore
import CoreData
import Foundation
import XCTest

#if SWIFT_PACKAGE
private let testsBundle = Bundle.module
#else
private let testsBundle = Bundle(for: TestCoreDataSchemaMigrations.self)
#endif

class TestCoreDataSchemaMigrations: XCTestCase {

    /// The `SampleStore2.0` database was created using the `OCKSample` app checked out
    /// at release tag 2.0.1. The database model version is `CareKitStore2.0`.
    ///
    /// It contains:
    ///   Contacts: 2
    ///   Tasks: 3
    ///   Outcomes: 3
    ///   OutcomeValues: 3
    func testMigrationFrom2_0to2_1() throws {

        // 1. Copy the sample store files to a temporary directory
        // The temporary directory and it's contents will be deleted automatically.

        let tempDir = NSTemporaryDirectory()
        let folder = UUID().uuidString
        let dir = URL(fileURLWithPath: tempDir).appendingPathComponent(folder, isDirectory: true)

        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [:])

        try FileManager.default.copyItem(
            at: testsBundle.url(forResource: "SampleStore2.0", withExtension: "sqlite")!,
            to: dir.appendingPathComponent("SampleStore2.0.sqlite"))

        try FileManager.default.copyItem(
            at: testsBundle.url(forResource: "SampleStore2.0", withExtension: "sqlite-shm")!,
            to: dir.appendingPathComponent("SampleStore2.0.sqlite-shm"))

        try FileManager.default.copyItem(
            at: testsBundle.url(forResource: "SampleStore2.0", withExtension: "sqlite-wal")!,
            to: dir.appendingPathComponent("SampleStore2.0.sqlite-wal"))

        // 2. Create a store from the copied SQL files.
        let descriptor = NSPersistentStoreDescription()
        descriptor.url = dir.appendingPathComponent("SampleStore2.0.sqlite")
        descriptor.type = NSSQLiteStoreType
        descriptor.shouldAddStoreAsynchronously = false
        descriptor.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        descriptor.shouldMigrateStoreAutomatically = true

        let container = NSPersistentContainer(name: "sut", managedObjectModel: sharedManagedObjectModel)
        container.persistentStoreDescriptions = [descriptor]

        // 3. Perform migration and ensure it was successful.
        // The closure here is executed synchronously.
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        // 4. Query the contents of the store and ensure all the relationships
        // were setup correctly.
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "OCKCDTask")
        let tasks = try container.viewContext.fetch(fetchRequest)
        XCTAssert(tasks.count == 3)

        let ckTask = tasks.first(where: { $0.value(forKey: "healthKitLinkage") == nil })
        let ckSchedule = ckTask?.value(forKey: "scheduleElements")
        XCTAssertNotNil(ckTask)
        XCTAssertNotNil(ckSchedule)

        let outcomes = ckTask?.value(forKey: "outcomes") as? Set<NSManagedObject>
        let values = outcomes?.map { $0.value(forKey: "values") as? Set<NSManagedObject> }
        XCTAssertNotNil(outcomes)
        XCTAssertNotNil(values)

        // 5. Tear down the CoreData stack before the files get deleted
        let store = container.persistentStoreCoordinator.persistentStores[0]
        try container.persistentStoreCoordinator.remove(store)
        try FileManager.default.removeItem(at: dir)
    }
}

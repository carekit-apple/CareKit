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
#if os(iOS)

import CoreData

class OCKHealthKitTaskStore: OCKCoreDataTaskStoreProtocol {
    typealias Task = OCKHealthKitTask
    typealias TaskQuery = OCKTaskQuery

    let name: String
    let securityApplicationGroupIdentifier: String?
    let storeType: OCKCoreDataStoreType
    var configuration = OCKStoreConfiguration()
    var allowsEntitiesWithMissingRelationships = true

    weak var taskDelegate: OCKTaskStoreDelegate?
    weak var resetDelegate: OCKResetDelegate?

    /// Initialize a new store by specifying its name and store type. Store's with conflicting names and types must not be created.
    ///
    /// - Parameters:
    ///   - name: A unique name for the store. It will be used for the filename if stored on disk.
    ///   - securityApplicationGroupIdentifier: App group identifier for a sandboxed app that shares files with other apps
    ///                                         from the same developer. See [Adding an App To an App Group](1).
    ///   - type: The type of store to be used. `.onDisk` is used by default.
    ///   - synchronizer: A store synchronization endpoint.
    ///
    /// [1]: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW19
    init(
        name: String,
        securityApplicationGroupIdentifier: String? = nil,
        type: OCKCoreDataStoreType = .onDisk()
    ) {
        self.storeType = type
        self.name = name
        self.securityApplicationGroupIdentifier = securityApplicationGroupIdentifier
    }

    func reset() throws {
        try deleteAllContents()
    }

    func makeTask(from task: OCKCDTask) -> OCKHealthKitTask {
        assert(task.healthKitLinkage != nil, "Programmer error. Only tasks with non-nil HealthKit linkages should be considered HealthKitTasks.")
        let schedule = makeSchedule(elements: Array(task.scheduleElements))
        let linkage = makeHealthKitLinkage(from: task.healthKitLinkage)!
        let healthKitTask = OCKHealthKitTask(id: task.id, title: task.title, carePlanUUID: task.carePlan?.uuid,
                                             schedule: schedule, healthKitLinkage: linkage)
        return copyTaskValues(from: task, to: healthKitTask)
    }

    var _container: NSPersistentContainer?
    var _context: NSManagedObjectContext?

    func autoSynchronizeIfRequired() {
        // Intentionally empty implementation.
    }

    // MARK: Internal Synchronous Methods

    internal func fetchTask(for outcome: OCKOutcome) throws -> OCKHealthKitTask {
        try performWithContextAndWait { _ in
            let persistedTask: OCKCDTask = try fetchObject(uuid: outcome.taskUUID)
            let task = makeTask(from: persistedTask)
            return task
        }
    }

    internal func fetchTasks(query: OCKTaskQuery) throws -> [OCKHealthKitTask] {
        try performWithContextAndWait { _ in
            let predicate = try buildPredicate(for: query)
            let persistedTasks = try self.fetchFromStore(OCKCDTask.self, where: predicate)
            let tasks = persistedTasks.map(self.makeTask)
            return tasks
        }
    }
}
#endif

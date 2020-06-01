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
import HealthKit

protocol OCKCDTaskCompatible: OCKAnyMutableTask, OCKVersionedObjectCompatible {
    var carePlanUUID: UUID? { get set }
    var optionalHealthKitLinkage: OCKHealthKitLinkage? { get set }
}

extension OCKTask: OCKCDTaskCompatible {
    var optionalHealthKitLinkage: OCKHealthKitLinkage? {
        get { nil }
        set { /* No-op */ }
    }
}

protocol OCKCoreDataTaskStoreProtocol: OCKCoreDataStoreProtocol, OCKTaskStore where Task: OCKCDTaskCompatible {
    func makeTask(from task: OCKCDTask) -> Task
}

// MARK: Conformance to OCKTasStore

extension OCKCoreDataTaskStoreProtocol {
    public func fetchTasks(query: OCKTaskQuery = OCKTaskQuery(), callbackQueue: DispatchQueue = .main,
                           completion: @escaping (Result<[Task], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: query)
                let tasks = self.fetchFromStore(OCKCDTask.self, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query.limit ?? 0
                    fetchRequest.fetchOffset = query.offset
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(for: query)
                }
                .map(self.makeTask)
                .filtered(against: query)

                callbackQueue.async {
                    completion(.success(tasks))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    let message = "Failed to fetch tasks with query: \(String(describing: query)). "
                    completion(.failure(.fetchFailed(reason: message + error.localizedDescription)))
                }
            }
        }
    }

    public func addTasks(_ tasks: [Task], callbackQueue: DispatchQueue = .main,
                         completion: ((Result<[Task], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let addedTasks = try self.createTasksWithoutCommitting(tasks)
                try self.context.save()
                callbackQueue.async {
                    self.taskDelegate?.taskStore(self, didAddTasks: addedTasks)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(addedTasks))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.addFailed(reason: "Failed to add OCKTasks: [\(tasks)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    public func updateTasks(_ tasks: [Task], callbackQueue: DispatchQueue = .main,
                            completion: ((Result<[Task], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let updated = try self.updateTasksWithoutCommitting(tasks, copyUUIDs: false)
                try self.context.save()
                callbackQueue.async {
                    self.taskDelegate?.taskStore(self, didUpdateTasks: updated)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(updated))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.updateFailed(reason: "\(error.localizedDescription)")))
                }
            }
        }
    }

    public func deleteTasks(_ tasks: [Task], callbackQueue: DispatchQueue = .main,
                            completion: ((Result<[Task], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                try self.validateUpdateIdentifiers(tasks.map { $0.id })
                let markedTasks: [OCKCDTask] = try self.performDeletion(
                    values: tasks,
                    addNewVersion: self.createTask)

                try self.context.save()
                let deletedTasks = markedTasks.map(self.makeTask)
                callbackQueue.async {
                    self.taskDelegate?.taskStore(self, didDeleteTasks: deletedTasks)
                    self.autoSynchronizeIfRequired()
                    completion?(.success(deletedTasks))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete OCKTasks: [\(tasks)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    public func addUpdateOrDeleteTasks(addOrUpdate tasks: [Task], delete deleteTasks: [Task],
                                       callbackQueue: DispatchQueue = .main,
                                       completion: ((Result<([Task], [Task], [Task]), OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let existingTaskIDs = self.fetchHeads(OCKCDTask.self, ids: tasks.map { $0.id }).map { $0.id }
                let addTasks = tasks.filter { !existingTaskIDs.contains($0.id) }
                let updateTasks = tasks.filter { existingTaskIDs.contains($0.id) }
                try self.confirmUpdateWillNotCauseDataLoss(tasks: updateTasks)

                let inserted = addTasks.map(self.createTask)
                let updated = try self.performVersionedUpdate(values: updateTasks, addNewVersion: self.createTask)
                let deleted: [OCKCDTask] = try self.performDeletion(values: deleteTasks, addNewVersion: self.createTask)

                try self.context.save()

                let addedTasks = inserted.map(self.makeTask)
                let updatedTasks = updated.map(self.makeTask)
                let deletedTasks = deleted.map(self.makeTask)

                callbackQueue.async {
                    self.taskDelegate?.taskStore(self, didAddTasks: addedTasks)
                    self.taskDelegate?.taskStore(self, didUpdateTasks: updatedTasks)
                    self.taskDelegate?.taskStore(self, didDeleteTasks: deleteTasks)
                    completion?(.success((addedTasks, updateTasks, deletedTasks)))
                }

            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.updateFailed(reason: "\(error.localizedDescription)")))
                }
            }
        }
    }

    // MARK: Internal
    // These methods are called from elsewhere in CareKit, but must always be called
    // from the `contexts`'s thread.

    func createTasksWithoutCommitting(_ tasks: [Task]) throws -> [Task] {
        try self.validateNew(OCKCDTask.self, tasks)
        let persistableTasks = tasks.map(self.createTask)
        let addedTasks = persistableTasks.map(self.makeTask)
        return addedTasks
    }

    /// Updates existing tasks to the versions passed in.
    ///
    /// The copyUUIDs argument should be true when ingesting tasks from a remote to ensure
    /// the UUIDs match on all devices, and false when creating a new version of a task locally
    /// to ensure that the new version has a different UUID than its parent version.
    ///
    /// - Parameters:
    ///   - tasks: The new versions of the tasks.
    ///   - copyUUIDs: If true, the UUIDs of the tasks will be copied to the new versions
    func updateTasksWithoutCommitting(_ tasks: [Task], copyUUIDs: Bool) throws -> [Task] {
        try validateUpdateIdentifiers(tasks.map { $0.id })
        try confirmUpdateWillNotCauseDataLoss(tasks: tasks)
        let updatedTasks = try self.performVersionedUpdate(values: tasks, addNewVersion: self.createTask)
        if copyUUIDs {
            updatedTasks.enumerated().forEach { $1.uuid = tasks[$0].uuid! }
        }
        let updated = updatedTasks.map(self.makeTask)
        return updated
    }

    func createTask(from task: Task) -> OCKCDTask {
        let persistableTask = OCKCDTask(context: context)
        copyTask(task, to: persistableTask)
        return persistableTask
    }

    func copyTask(_ task: Task, to persistableTask: OCKCDTask) {
        persistableTask.copyVersionInfo(from: task)
        persistableTask.allowsMissingRelationships = configuration.allowsEntitiesWithMissingRelationships
        persistableTask.title = task.title
        persistableTask.instructions = task.instructions
        persistableTask.impactsAdherence = task.impactsAdherence
        persistableTask.scheduleElements.forEach { context.delete($0) }
        persistableTask.scheduleElements = Set(createScheduleElements(from: task.schedule))
        persistableTask.healthKitLinkage = task.optionalHealthKitLinkage == nil ? nil : createHealthKitLinkage(from: task.optionalHealthKitLinkage!)
        if let planUUID = task.carePlanUUID { persistableTask.carePlan = try? fetchObject(uuid: planUUID) }
    }

    func copyTaskValues<T: OCKCDTaskCompatible>(from other: OCKCDTask, to task: T) -> T {
        var mutable = task
        mutable.copyVersionedValues(from: other)
        mutable.carePlanUUID = other.carePlan?.uuid
        mutable.optionalHealthKitLinkage = makeHealthKitLinkage(from: other.healthKitLinkage)
        mutable.title = other.title
        mutable.instructions = other.instructions
        mutable.impactsAdherence = other.impactsAdherence
        mutable.schedule = makeSchedule(elements: Array(other.scheduleElements))
        return mutable
    }

    private func createScheduleElements(from schedule: OCKSchedule) -> [OCKCDScheduleElement] {
        return schedule.elements.map { element -> OCKCDScheduleElement in
            let scheduleElement = OCKCDScheduleElement(context: context)
            scheduleElement.interval = element.interval
            scheduleElement.startDate = element.start
            scheduleElement.endDate = element.end
            scheduleElement.duration = element.duration
            scheduleElement.interval = element.interval
            scheduleElement.text = element.text
            scheduleElement.targetValues = Set(element.targetValues.map(createValue))
            return scheduleElement
        }
    }

    private func createHealthKitLinkage(from link: OCKHealthKitLinkage?) -> OCKCDHealthKitLinkage? {
        guard let link = link else { return nil }
        let linkage = OCKCDHealthKitLinkage(context: context)
        linkage.quantityIdentifier = link.quantityIdentifier.rawValue
        linkage.quantityType = link.quantityType.rawValue
        linkage.unitString = link.unitString
        return linkage
    }

    internal func createValue(from value: OCKOutcomeValue) -> OCKCDOutcomeValue {
        let object = OCKCDOutcomeValue(context: context)
        object.copyValues(from: value)
        object.value = value.value
        object.kind = value.kind
        object.units = value.units
        object.index = value.index == nil ? nil : NSNumber(value: value.index!)
        return object
    }

    func makeSchedule(elements: [OCKCDScheduleElement]) -> OCKSchedule {
        OCKSchedule(composing: elements.map { object -> OCKScheduleElement in
            OCKScheduleElement(start: object.startDate, end: object.endDate,
                               interval: object.interval, text: object.text,
                               targetValues: object.targetValues.map(makeValue),
                               duration: object.duration)
        })
    }

    func makeValue(persistableValue: OCKCDOutcomeValue) -> OCKOutcomeValue {
        var value = OCKOutcomeValue(persistableValue.value, units: persistableValue.units)
        value.index = persistableValue.index?.intValue
        value.kind = persistableValue.kind
        value.copyCommonValues(from: persistableValue)
        return value
    }

    func makeHealthKitLinkage(from linkage: OCKCDHealthKitLinkage?) -> OCKHealthKitLinkage? {
        guard let linkage = linkage else { return nil }
        guard let quantity = OCKHealthKitLinkage.QuantityType(rawValue: linkage.quantityType) else { fatalError("Invlaid quantity type!") }
        let identifier = HKQuantityTypeIdentifier(rawValue: linkage.quantityIdentifier)
        let unit = HKUnit(from: linkage.unitString)
        return OCKHealthKitLinkage(quantityIdentifier: identifier, quantityType: quantity, unit: unit)
    }

    // Ensure that new versions of tasks do not overwrite regions of previous
    // versions that already have outcomes saved to them.
    //
    // |<------------- Time Line --------------->|
    //  TaskV1 ------x------------------->
    //                     V2 ---------->
    //              V3------------------>
    //
    // Throws an error when updating to V3 from V2 if V1 has outcomes after `x`.
    // Throws an error when updating to V3 from V2 if V2 has any outcomes.
    // Does not throw when updating to V3 from V2 if V1 has outcomes before `x`.
    func confirmUpdateWillNotCauseDataLoss(tasks: [Task]) throws {
        let heads = fetchHeads(OCKCDTask.self, ids: tasks.map { $0.id })
        for task in heads {

            // For each task, gather all outcomes
            var allOutcomes: Set<OCKCDOutcome> = []
            var currentVersion: OCKCDTask? = task
            while let version = currentVersion {
                allOutcomes = allOutcomes.union(version.outcomes)
                currentVersion = version.previous as? OCKCDTask
            }

            // Get the date highest date on which an outcome exists.
            // If there are no outcomes, then any update is safe.
            guard let latestDate = allOutcomes.map({ $0.date }).max()
                else { continue }

            guard let proposedUpdate = tasks.first(where: { $0.id == task.id })
                else { fatalError("Fetched an OCKCDTask for which an update was not proposed.") }

            if proposedUpdate.effectiveDate <= latestDate {
                throw OCKStoreError.updateFailed(reason: """
                    Updating task \(task.id) failed. The new version of the task takes effect on \(task.effectiveDate), but an outcome for a
                    previous version of the task exists on \(latestDate). To prevent implicit data loss, you must explicitly delete all outcomes
                    that exist after the new version's `effectiveDate` before applying the update, or move the new version's `effectiveDate` to
                    some date past the latest outcome's date.
                    """
                )
            }
        }
    }

    func buildPredicate(for query: OCKTaskQuery) throws -> NSPredicate {
        var predicate = OCKCDVersionedObject.notDeletedPredicate

        if let interval = query.dateInterval {
            let headPredicate = OCKCDVersionedObject.newestVersionPredicate(in: interval)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, headPredicate])
        }

        if !query.ids.isEmpty {
            let idPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.id), query.ids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, idPredicate])
        }

        if !query.uuids.isEmpty {
            let objectPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.uuid), query.uuids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, objectPredicate])
        }

        if !query.remoteIDs.isEmpty {
            predicate = predicate.including(query.remoteIDs, for: #keyPath(OCKCDObject.remoteID))
        }

        if !query.carePlanIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.id), query.carePlanIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanUUIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.uuid), query.carePlanUUIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanRemoteIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.remoteID), query.carePlanRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        return predicate
    }

    func buildSortDescriptors(for query: OCKTaskQuery) -> [NSSortDescriptor] {
        let orders = query.extendedSortDescriptors
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.effectiveDate, ascending: ascending)
            case .title(let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: ascending)
            case .groupIdentifier(let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.groupIdentifier, ascending: ascending)
            case .createdDate(ascending: let ascending):
                return NSSortDescriptor(keyPath: \OCKCDTask.createdDate, ascending: ascending)
            }
        } + defaultSortDescritors()
    }
}

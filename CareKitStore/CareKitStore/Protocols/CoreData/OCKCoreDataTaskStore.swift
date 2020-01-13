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
    var carePlanID: OCKLocalVersionID? { get set }
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
                let tasks = OCKCDTask
                    .fetchFromStore(in: self.context, where: predicate) { fetchRequest in
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
                try OCKCDTask.validateNewIDs(tasks.map { $0.id }, in: self.context)
                let persistableTasks = tasks.map { self.createTask(from: $0) }
                try self.context.save()
                let addedTasks = persistableTasks.map(self.makeTask)
                callbackQueue.async {
                    self.taskDelegate?.taskStore(self, didAddTasks: addedTasks)
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
                let ids = tasks.map { $0.id }
                try OCKCDTask.validateUpdateIdentifiers(ids, in: self.context)
                try self.confirmUpdateWillNotCauseDataLoss(tasks: tasks)
                let updatedTasks = try self.performVersionedUpdate(values: tasks, addNewVersion: self.createTask)
                try self.context.save()
                let tasks = updatedTasks.map(self.makeTask)
                callbackQueue.async {
                    self.taskDelegate?.taskStore(self, didUpdateTasks: tasks)
                    completion?(.success(tasks))
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
                let ids = tasks.map { $0.id }
                try OCKCDTask.validateUpdateIdentifiers(ids, in: self.context)
                let markedTasks: [OCKCDTask] = try self.performDeletion(values: tasks)
                try self.context.save()
                let deletedTasks = markedTasks.map(self.makeTask)
                callbackQueue.async {
                    self.taskDelegate?.taskStore(self, didDeleteTasks: deletedTasks)
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

    private func createTask(from task: Task) -> OCKCDTask {
        let persistableTask = OCKCDTask(context: context)
        persistableTask.copyVersionInfo(from: task)
        persistableTask.allowsMissingRelationships = configuration.allowsEntitiesWithMissingRelationships
        persistableTask.title = task.title
        persistableTask.instructions = task.instructions
        persistableTask.impactsAdherence = task.impactsAdherence
        persistableTask.scheduleElements = Set(createScheduleElements(from: task.schedule))
        persistableTask.healthKitLinkage = task.optionalHealthKitLinkage == nil ? nil : createHealthKitLinkage(from: task.optionalHealthKitLinkage!)
        if let planId = task.carePlanID { persistableTask.carePlan = try? fetchObject(havingLocalID: planId) }

        return persistableTask
    }

    internal func copyTaskValues<T: OCKCDTaskCompatible>(from other: OCKCDTask, to task: T) -> T {
        var mutable = task
        mutable.copyVersionedValues(from: other)
        mutable.carePlanID = other.carePlan?.localDatabaseID
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
            scheduleElement.copyValues(from: element)
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
        assert(persistableValue.localDatabaseID != nil, "You shouldn't be calling this method with an object that hasn't been saved yet!")
        var value = OCKOutcomeValue(persistableValue.value, units: persistableValue.units)
        value.index = persistableValue.index?.intValue
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
    // Does not trow when updating to V3 from V2 if V1 has outcomes before `x`.
    private func confirmUpdateWillNotCauseDataLoss(tasks: [Task]) throws {
        let heads: [OCKCDTask] = OCKCDTask.fetchHeads(ids: tasks.map { $0.id }, in: context)
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

            if task.effectiveDate <= latestDate {
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
        var predicate = NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedDate)) // Not deleted

        if let interval = query.dateInterval {
            let headPredicate = OCKCDVersionedObject.newestVersionPredicate(in: interval)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, headPredicate])
        }

        if !query.ids.isEmpty {
            let idPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.id), query.ids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, idPredicate])
        }

        if !query.versionIDs.isEmpty {
            let versionPredicate = NSPredicate(format: "self IN %@", try query.versionIDs.map(objectID))
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, versionPredicate])
        }

        if !query.remoteIDs.isEmpty {
            let remotePredicate = NSPredicate(format: "%K in %@", #keyPath(OCKCDVersionedObject.remoteID), query.remoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        if !query.carePlanIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.id), query.carePlanIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanVersionIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan), try query.carePlanVersionIDs.map(objectID))
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanRemoteIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.remoteID), query.carePlanRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        return predicate
    }

    func buildSortDescriptors(for query: OCKTaskQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.extendedSortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.effectiveDate, ascending: ascending)
            case .title(let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: ascending)
            case .groupIdentifier(let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.groupIdentifier, ascending: ascending)
            }
        }
    }
}

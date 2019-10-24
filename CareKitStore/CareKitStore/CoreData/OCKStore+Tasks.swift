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

import Foundation

extension OCKStore {
    public func fetchTasks(_ anchor: OCKTaskAnchor? = nil, query: OCKTaskQuery? = nil, queue: DispatchQueue = .main,
                           completion: @escaping (Result<[OCKTask], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: anchor, and: query)
                let tasks = OCKCDTask
                    .fetchFromStore(in: self.context, where: predicate) { fetchRequest in
                        fetchRequest.fetchLimit = query?.limit ?? 0
                        fetchRequest.fetchOffset = query?.offset ?? 0
                        fetchRequest.sortDescriptors = self.buildSortDescriptors(for: query)
                    }
                    .map(self.makeTask)
                    .filtered(against: query)

                queue.async {
                    completion(.success(Array(tasks)))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    let message = "Failed to fetch tasks with anchor: \(String(describing: anchor)) and query: \(String(describing: query)). "
                    completion(.failure(.fetchFailed(reason: message + error.localizedDescription)))
                }
            }
        }
    }

    public func addTasks(_ tasks: [OCKTask], queue: DispatchQueue = .main,
                         completion: ((Result<[OCKTask], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                try OCKCDTask.validateNewIdentifiers(tasks.map { $0.identifier }, in: self.context)
                let persistableTasks = tasks.map { self.addTask($0) }
                try self.context.save()
                let addedTasks = persistableTasks.map(self.makeTask)
                queue.async {
                    self.delegate?.store(self, didAddTasks: addedTasks)
                    completion?(.success(addedTasks))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.addFailed(reason: "Failed to add OCKTasks: [\(tasks)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    public func updateTasks(_ tasks: [OCKTask], queue: DispatchQueue = .main,
                            completion: ((Result<[OCKTask], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let identifiers = tasks.map { $0.identifier }
                try OCKCDTask.validateUpdateIdentifiers(identifiers, in: self.context)

                let updatedTasks = self.configuration.updatesCreateNewVersions ?
                    try self.performVersionedUpdate(values: tasks, addNewVersion: self.addTask) :
                    try self.performUnversionedUpdate(values: tasks, update: self.copyTask)

                try self.context.save()
                let tasks = updatedTasks.map(self.makeTask)
                queue.async {
                    self.delegate?.store(self, didUpdateTasks: tasks)
                    completion?(.success(tasks))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.updateFailed(reason: "Failed to update OCKTasks: [\(tasks)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    public func deleteTasks(_ tasks: [OCKTask], queue: DispatchQueue = .main,
                            completion: ((Result<[OCKTask], OCKStoreError>) -> Void)? = nil) {
        context.perform {
            do {
                let identifiers = tasks.map { $0.identifier }
                try OCKCDTask.validateUpdateIdentifiers(identifiers, in: self.context)
                let deletedTasks = try self.performUnversionedUpdate(values: tasks) { _, persistableTask in
                    persistableTask.deletedDate = Date()
                }.map(self.makeTask)
                try self.context.save()
                queue.async {
                    self.delegate?.store(self, didDeleteTasks: deletedTasks)
                    completion?(.success(deletedTasks))
                }
            } catch {
                self.context.rollback()
                queue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete OCKTasks: [\(tasks)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    // MARK: Private

    /// - Remark: This does not commit the transaction. After calling this function one or more times, you must call `context.save()` in order to
    /// persist the changes to disk. This is an optimization to allow batching.
    /// - Remark: You should verify that the object does not already exist in the database and validate its values before calling this method.
    private func addTask(_ task: OCKTask) -> OCKCDTask {
        let persistableTask = OCKCDTask(context: context)
        copyTask(task, to: persistableTask)
        return persistableTask
    }

    private func copyTask(_ task: OCKTask, to persistableTask: OCKCDTask) {
        persistableTask.copyVersionInfo(from: task)
        persistableTask.allowsMissingRelationships = allowsEntitiesWithMissingRelationships
        persistableTask.title = task.title
        persistableTask.instructions = task.instructions
        persistableTask.impactsAdherence = task.impactsAdherence
        persistableTask.scheduleElements = Set(makeScheduleElements(from: task.schedule))
        if let planId = task.carePlanID { persistableTask.carePlan = try? fetchObject(havingLocalID: planId) }
    }

    private func makeScheduleElements(from schedule: OCKSchedule) -> [OCKCDScheduleElement] {
        return schedule.elements.map { element -> OCKCDScheduleElement in
            let scheduleElement = OCKCDScheduleElement(context: context)
            scheduleElement.interval = element.interval
            scheduleElement.startDate = element.start
            scheduleElement.endDate = element.end
            scheduleElement.duration = element.duration
            scheduleElement.interval = element.interval
            scheduleElement.text = element.text
            scheduleElement.isAllDay = element.isAllDay
            scheduleElement.targetValues = Set(element.targetValues.map(addValue))
            scheduleElement.copyValues(from: element)
            return scheduleElement
        }
    }

    /// - Remark: This method is intended to create a value type struct from a *persisted* NSManagedObject. Calling this method with an
    /// object that is not yet commited is a programmer error.
    private func makeTask(from object: OCKCDTask) -> OCKTask {
        assert(object.localDatabaseID != nil, "This should never be called on an unsaved object")
        let schedule = makeSchedule(from: object.scheduleElements)
        var task = OCKTask(identifier: object.identifier, title: object.title,
                           carePlanID: object.carePlan?.localDatabaseID, schedule: schedule)
        task.copyVersionedValues(from: object)
        task.instructions = object.instructions
        task.impactsAdherence = object.impactsAdherence
        return task
    }

    private func buildPredicate(for anchor: OCKTaskAnchor?, and query: OCKTaskQuery?) throws -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            try buildSubPredicate(for: anchor),
            buildSubPredicate(for: query),
            NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedDate))
        ])
    }

    private func buildSubPredicate(for anchor: OCKTaskAnchor?) throws -> NSPredicate {
        guard let anchor = anchor else { return NSPredicate(value: true) }
        switch anchor {
        case .taskIdentifiers(let taskIdentifiers):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.identifier), taskIdentifiers)
        case .taskVersions(let versionIDs):
            return NSPredicate(format: "self IN %@", try versionIDs.map(objectID))
        case .taskRemoteIDs(let remoteIDs):
            return NSPredicate(format: "%K in %@", #keyPath(OCKCDVersionedObject.remoteID), remoteIDs)

        case .carePlanIdentifiers(let carePlanIdentifiers):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.identifier), carePlanIdentifiers)
        case .carePlanVersions(let versionIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan), try versionIDs.map(objectID))
        case .carePlanRemoteIDs(let remoteIDs):
            return NSPredicate(format: "%K IN %@", #keyPath(OCKCDTask.carePlan.remoteID), remoteIDs)
        }
    }

    private func buildSubPredicate(for query: OCKTaskQuery?) -> NSPredicate {
        var predicate = NSPredicate(value: true)
        if let interval = query?.dateInterval {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                predicate, OCKCDVersionedObject.newestVersionPredicate(in: interval)
            ])
        }
        return predicate
    }

    private func buildSortDescriptors(for query: OCKTaskQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.sortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.effectiveDate, ascending: ascending)
            case .title(let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.title, ascending: ascending)
            case .groupIdentifier(let ascending): return NSSortDescriptor(keyPath: \OCKCDTask.groupIdentifier, ascending: ascending)
            }
        }
    }
}

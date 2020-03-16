//
/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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

extension OCKStore {

    open func fetchTaskCategories(query: OCKTaskCategoryQuery = OCKTaskCategoryQuery(), callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<[OCKTaskCategory], OCKStoreError>) -> Void) {
        context.perform {
            do {
                let predicate = try self.buildPredicate(for: query)
                let persistedTaskCategories = OCKCDTaskCategory.fetchFromStore(in: self.context, where: predicate) { fetchRequest in
                    fetchRequest.fetchLimit = query.limit ?? 0
                    fetchRequest.fetchOffset = query.offset
                    fetchRequest.sortDescriptors = self.buildSortDescriptors(for: query)
                }

                let taskCategories = persistedTaskCategories.map(self.makeTaskCategory)
                callbackQueue.async { completion(.success(taskCategories)) }
            } catch {
                callbackQueue.async { completion(.failure(.fetchFailed(reason: "Failed to fetch task categories. Error: \(error.localizedDescription)"))) }
            }
        }
    }

    open func addTaskCategories(_ taskCategories: [OCKTaskCategory], callbackQueue: DispatchQueue = .main,
                          completion: ((Result<[OCKTaskCategory], OCKStoreError>) -> Void)?) {
        context.perform {
            do {
                try OCKCDTaskCategory.validateNewIDs(taskCategories.map { $0.id }, in: self.context)
                let persistableTaskCategories = taskCategories.map(self.createTaskCategory)
                try self.context.save()
                let savedTaskCategories = persistableTaskCategories.map(self.makeTaskCategory)
                callbackQueue.async {

                    self.taskCategoryDelegate?.taskCategoryStore(self, didAddTaskCategories: savedTaskCategories)
                    
                    completion?(.success(savedTaskCategories))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.addFailed(reason: "Failed to insert task categories: [\(taskCategories)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    open func updateTaskCategories(_ taksCategories: [OCKTaskCategory], callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<[OCKTaskCategory]>?) {
        context.perform {
            do {
                try OCKCDTaskCategory.validateUpdateIdentifiers(taksCategories.map { $0.id }, in: self.context)
                let updatedCategories = try self.performVersionedUpdate(values: taksCategories, addNewVersion: self.createTaskCategory)
                try self.context.save()
                let taksCategories = updatedCategories.map(self.makeTaskCategory)
                callbackQueue.async {
                    self.taskCategoryDelegate?.taskCategoryStore(self, didUpdateTaskCategories: taksCategories)
                    completion?(.success(taksCategories))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.updateFailed(reason: "Failed to update task categories: [\(taksCategories)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    open func deleteTaskCategories(_ taskCategories: [OCKTaskCategory], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKTaskCategory], OCKStoreError>) -> Void)?) {
        context.perform {
            do {
                let markedDeleted: [OCKCDTaskCategory] = try self.performDeletion(values: taskCategories)
                try self.context.save()
                let deletedTaskCategories = markedDeleted.map(self.makeTaskCategory)
                callbackQueue.async {
                    self.taskCategoryDelegate?.taskCategoryStore(self, didDeleteTaskCategories: deletedTaskCategories)
                    completion?(.success(deletedTaskCategories))
                }
            } catch {
                self.context.rollback()
                callbackQueue.async {
                    completion?(.failure(.deleteFailed(reason: "Failed to delete task categories: [\(taskCategories)]. \(error.localizedDescription)")))
                }
            }
        }
    }

    private func createTaskCategory(from taskCategory: OCKTaskCategory) -> OCKCDTaskCategory {
        let persistableTaskCategory = OCKCDTaskCategory(context: context)
        persistableTaskCategory.copyVersionInfo(from: taskCategory)
        persistableTaskCategory.allowsMissingRelationships = configuration.allowsEntitiesWithMissingRelationships
        persistableTaskCategory.title = taskCategory.title

        if let carePlanID = taskCategory.carePlanID { persistableTaskCategory.carePlan = try? fetchObject(havingLocalID: carePlanID) }
        return persistableTaskCategory
    }

    private func createPostalAddress(from address: OCKPostalAddress) -> OCKCDPostalAddress {
        let persistableAddress = OCKCDPostalAddress(context: context)
        copyPostalAddress(address, to: persistableAddress)
        return persistableAddress
    }

    private func copyPostalAddress(_ address: OCKPostalAddress, to persitableAddress: OCKCDPostalAddress) {
        persitableAddress.street = address.street
        persitableAddress.subLocality = address.subLocality
        persitableAddress.city = address.city
        persitableAddress.subAdministrativeArea = address.subAdministrativeArea
        persitableAddress.state = address.state
        persitableAddress.postalCode = address.postalCode
        persitableAddress.country = address.country
        persitableAddress.isoCountryCode = address.isoCountryCode
    }

    private func makeTaskCategory(from object: OCKCDTaskCategory) -> OCKTaskCategory {
        var taskCategory = OCKTaskCategory(id: object.id,
                                           title: object.title,
                                           carePlanID: object.carePlan?.localDatabaseID)
        taskCategory.copyVersionedValues(from: object)
        taskCategory.title = object.title
        return taskCategory
    }

    private func buildPredicate(for query: OCKTaskCategoryQuery) throws -> NSPredicate {
        var predicate = OCKCDVersionedObject.notDeletedPredicate

        if let interval = query.dateInterval {
            let intervalPredicate = OCKCDVersionedObject.newestVersionPredicate(in: interval)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, intervalPredicate])
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
            let remotePredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.remoteID), query.remoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        if !query.carePlanIDs.isEmpty {
            let planPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTaskCategory.carePlan.id), query.carePlanIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, planPredicate])
        }

        if !query.carePlanVersionIDs.isEmpty {
            let versionPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTaskCategory.carePlan), try query.carePlanVersionIDs.map(fetchObject))
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, versionPredicate])
        }

        if !query.carePlanRemoteIDs.isEmpty {
            let remotePredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDTaskCategory.carePlan.remoteID), query.carePlanRemoteIDs)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, remotePredicate])
        }

        if !query.groupIdentifiers.isEmpty {
            predicate = predicate.including(groupIdentifiers: query.groupIdentifiers)
        }

        if !query.tags.isEmpty {
            predicate = predicate.including(tags: query.tags)
        }

        return predicate
    }

    private func buildSortDescriptors(for query: OCKTaskCategoryQuery?) -> [NSSortDescriptor] {
        guard let orders = query?.extendedSortDescriptors else { return [] }
        return orders.map { order -> NSSortDescriptor in
            switch order {
            case .title(ascending: let ascending): return NSSortDescriptor(keyPath: \OCKCDTaskCategory.title, ascending: ascending)
            }
        }
    }
}

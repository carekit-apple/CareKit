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

#if (CARE && HEALTH) || HEALTH
import CoreData
import Foundation
import HealthKit

extension OCKStore {

    func fetchHealthKitTasks(query: OCKTaskQuery) throws -> [OCKHealthKitTask] {
        var result: Result<[OCKHealthKitTask], Error> = .failure(OCKStoreError.fetchFailed(reason: "Timeout"))

        context.performAndWait {
            do {
                let request = NSFetchRequest<OCKCDHealthKitTask>(entityName: OCKCDHealthKitTask.entity().name!)
                request.fetchLimit = query.limit ?? 0
                request.fetchOffset = query.offset
                request.sortDescriptors = self.buildSortDescriptors(for: query)
                request.predicate = self.buildPredicate(for: query)

                let cdTasks = try self.context.fetch(request)
                let tasks = cdTasks.map { $0.makeTask() }
                    .filtered(dateInterval: query.dateInterval, excludeTasksWithNoEvents: query.excludesTasksWithNoEvents)

                result = .success(tasks)
            } catch {
                result = .failure(error)
            }
        }

        let tasks = try result.get()
        return tasks
    }

    func addHealthKitTasks(
        _ tasks: [OCKHealthKitTask],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {

        transaction(inserts: tasks, updates: [], deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.inserts))
            }
        }
    }

    func updateHealthKitTasks(
        _ tasks: [OCKHealthKitTask],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {

        transaction(inserts: [], updates: tasks, deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.updates))
            }
        }
    }

    func deleteHealthKitTasks(
        _ tasks: [OCKHealthKitTask],
        callbackQueue: DispatchQueue = .main,
        completion: ((Result<[OCKHealthKitTask], OCKStoreError>) -> Void)? = nil) {

        transaction(inserts: [], updates: [], deletes: tasks) { result in
            callbackQueue.async {
                completion?(result.map(\.deletes))
            }
        }
    }
}
#endif

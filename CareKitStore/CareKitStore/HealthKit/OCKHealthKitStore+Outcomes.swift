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
#if os(iOS)

import Foundation
import HealthKit

public extension OCKHealthKitPassthroughStore {

    func fetchOutcomes(query: OCKOutcomeQuery, callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<[OCKHealthKitOutcome], OCKStoreError>) -> Void) {
        guard let range = query.dateInterval else {
            let problem = "OCKHealthKitPassthroughStore requires that outcome queries have valid date interval"
            let error = OCKStoreError.fetchFailed(reason: problem)
            callbackQueue.async { completion(.failure(error)) }
            return
        }

        var taskQuery = OCKTaskQuery(dateInterval: range)
        taskQuery.ids = query.taskIDs
        taskQuery.remoteIDs = query.taskRemoteIDs
        taskQuery.uuids = query.taskUUIDs

        do {
            let tasks = try store.fetchHealthKitTasks(query: taskQuery)
            let closures = tasks.map { task in { done in self.fetchOutcomes(task: task, dateRange: range, completion: done) } }
            aggregate(closures, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async { completion(.failure(.fetchFailed(reason: "Failed to fetch tasks with error: \(error.localizedDescription)"))) }
        }
    }

    func addOutcomes(_ outcomes: [OCKHealthKitOutcome], callbackQueue: DispatchQueue = .main,
                     completion: ((Result<[OCKHealthKitOutcome], OCKStoreError>) -> Void)? = nil) {
        do {
            let tasks = try fetchTasks(for: outcomes)
            let samples = try outcomes.map { outcome throws -> HKObject in
                guard outcome.isOwnedByApp
                    else { throw OCKStoreError.addFailed(reason: "Cannot persist an OCKHealthKitOutcome that is not owned by this app!") }
                guard outcome.values.count == 1
                    else { throw OCKStoreError.addFailed(reason: "OCKHealthKitOutcomes must have exactly 1 value, but got \(outcome.values.count).") }
                guard let value = outcome.values.first?.doubleValue
                    else { throw OCKStoreError.addFailed(reason: "OCKHealthKitOutcome's value must be of type Double, but was not.") }
                guard let task = tasks.first(where: { $0.uuid == outcome.taskUUID })
                    else { throw OCKStoreError.addFailed(reason: "No task could be for outcome") }

                let unit = task.healthKitLinkage.unit
                let quantity = HKQuantity(unit: unit, doubleValue: value)
                let type = HKObjectType.quantityType(forIdentifier: task.healthKitLinkage.quantityIdentifier)!
                let event = task.schedule.event(forOccurrenceIndex: outcome.taskOccurrenceIndex)!
                let eventInterval = DateInterval(start: event.start, end: event.end)
                let currentTime = Date()
                let sampleTime = eventInterval.contains(currentTime) ? currentTime : eventInterval.start
                let sample = HKQuantitySample(type: type, quantity: quantity, start: sampleTime, end: sampleTime.advanced(by: 1))
                return sample
            }

            healthStore.save(samples) { _, error in
                if let error = error {
                    callbackQueue.async {
                        completion?(.failure(.addFailed(
                            reason: "Failed to add outcomes to HealthKit. Error: \(error.localizedDescription)")))
                    }
                    return
                }

                // Copy the newly assigned HealthKit UUID from the HKSample objects to the saves outcomes.
                var saved = outcomes
                samples.enumerated().forEach { index, value in
                    saved[index].healthKitUUIDs = Set([value.uuid])
                }

                callbackQueue.async {
                    self.outcomeDelegate?.outcomeStore(self, didAddOutcomes: saved)
                    completion?(.success(saved))
                }
            }

        } catch {
            callbackQueue.async {
                completion?(.failure(.addFailed(
                    reason: "Failed to add outcomes to HealthKit. Error: \(error.localizedDescription)")))
            }
        }
    }

    func updateOutcomes(_ outcomes: [OCKHealthKitOutcome], callbackQueue: DispatchQueue = .main,
                        completion: ((Result<[OCKHealthKitOutcome], OCKStoreError>) -> Void)? = nil) {
        callbackQueue.async {
            completion?(.failure(.updateFailed(reason: "Data in HealthKit can only be added and deleted. Updates are not allowed.")))
        }
    }

    func deleteOutcomes(_ outcomes: [OCKHealthKitOutcome], callbackQueue: DispatchQueue = .main,
                        completion: ((Result<[OCKHealthKitOutcome], OCKStoreError>) -> Void)? = nil) {
        do {
            let tasks = try fetchTasks(for: outcomes)
            let objectTypes = Set(tasks.map { HKObjectType.quantityType(forIdentifier: $0.healthKitLinkage.quantityIdentifier)! })
            guard let objectType = objectTypes.first, objectTypes.count == 1 else {
                throw OCKStoreError.deleteFailed(reason: "Cannot batch delete samples with different underlying HealthKit sample types!")
            }
            guard outcomes.allSatisfy({ $0.isOwnedByApp }) else {
                throw OCKStoreError.deleteFailed(reason: "Cannot delete samples in HealthKit not owned by this app!")
            }
            guard outcomes.allSatisfy({ $0.healthKitUUIDs != nil }) else {
                throw OCKStoreError.deleteFailed(reason: "Not all outcomes are outcomes previously retrieved from HealthKit!")
            }
            let predicate = HKQuery.predicateForObjects(with: Set(outcomes.compactMap({ $0.healthKitUUIDs }).flatMap({ $0 })))
            healthStore.deleteObjects(of: objectType, predicate: predicate) { _, _, error in
                if let error = error {
                    callbackQueue.async {
                        completion?(.failure(.deleteFailed(
                            reason: "Failed to delete HealthKit samples. Error: \(error.localizedDescription)")))
                    }
                    return
                }
                callbackQueue.async {
                    self.outcomeDelegate?.outcomeStore(self, didDeleteOutcomes: outcomes)
                    completion?(.success(outcomes))
                }
            }
        } catch {
            callbackQueue.async {
                completion?(.failure(.deleteFailed(
                    reason: "Failed to delete HealthKit samples. Error: \(error.localizedDescription)")))
            }
        }
    }

    // Make sure to call `prepTasks(_:)` before this.
    private func fetchOutcomes(task: OCKHealthKitTask, dateRange: DateInterval,
                               completion: @escaping (Result<[OCKHealthKitOutcome], OCKStoreError>) -> Void) {
        let events = task.schedule.events(from: dateRange.start, to: dateRange.end)
        let eventIntervals = events.map { DateInterval(start: $0.start, end: $0.end) }

        proxy.queryValue(identifier: task.healthKitLinkage.quantityIdentifier, unit: task.healthKitLinkage.unit,
                         queryType: task.healthKitLinkage.quantityType, in: eventIntervals) { [weak self] result in
            switch result {
            case let .failure(error): completion(.failure(.fetchFailed(reason: "HealthKit fetch failed. Error: \(error.localizedDescription)")))
            case let .success(samples):
                assert(samples.count == eventIntervals.count, "The number of outcome values and events should match!. Please file a bug.")
                let outcomes = samples.enumerated().compactMap { index, sample -> OCKHealthKitOutcome? in
                    guard !sample.values.isEmpty else { return nil } // Don't return an outcome for events where no HealthKit values exist.
                    var outcomeValues: [OCKOutcomeValue] = []
                    if let mapper = self?.samplesToOutcomesValueMapper, !sample.samples.isEmpty {
                        outcomeValues.append(contentsOf: mapper(sample.samples, task))
                    } else {
                        outcomeValues = sample.values.map {
                            task.healthKitLinkage.quantityIdentifier == .stepCount
                                ? OCKOutcomeValue(Int($0), units: task.healthKitLinkage.unit.unitString)
                                : OCKOutcomeValue($0, units: task.healthKitLinkage.unit.unitString)
                        }
                    }
                    guard !outcomeValues.isEmpty else { return nil }
                    let correspondingEvent = events[index]
                    let isOwnedByApp = !sample.samples.isEmpty && sample.samples.allSatisfy({ $0.sourceRevision.source == HKSource.default() })
                    let outcome = OCKHealthKitOutcome(taskUUID: task.uuid,
                                               taskOccurrenceIndex: correspondingEvent.occurrence,
                                               values: outcomeValues,
                                               isOwnedByApp: isOwnedByApp,
                                               healthKitUUIDs: Set(sample.samples.map { $0.uuid }))
                    return outcome
                }
                completion(.success(outcomes))
            }
        }
    }
}
#endif

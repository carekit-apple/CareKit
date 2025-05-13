/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
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
import HealthKit
import os.log

@available(iOS 15, watchOS 8, macOS 13.0, *)
public extension OCKHealthKitPassthroughStore {

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
                    saved[index].healthKitUUIDs = [[value.uuid]]
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

            // All outcomes should refer to the same HealthKit object type

            let tasks = try fetchTasks(for: outcomes)

            let objectTypes = tasks.map {
                HKObjectType.quantityType(forIdentifier: $0.healthKitLinkage.quantityIdentifier)!
            }

            let uniqueObjectTypes = Set(objectTypes)

            guard
                let objectTypeToDelete = uniqueObjectTypes.first,
                uniqueObjectTypes.count == 1
            else {
                let message = "Cannot batch delete samples with different underlying HealthKit sample types."
                throw OCKStoreError.deleteFailed(reason: message)
            }

            // Make sure the outcomes can be deleted

            try checkAbilityToDelete(outcomes: outcomes)

            // Delete the outcomes from HealthKit

            let allHealthKitUUIDs = outcomes
                .flatMap(\.healthKitUUIDs)
                .flatMap { $0 }

            let predicate = HKQuery.predicateForObjects(with: Set(allHealthKitUUIDs))

            healthStore.deleteObjects(of: objectTypeToDelete, predicate: predicate) { _, _, error in
                if let error = error {
                    callbackQueue.async {
                        completion?(.failure(.deleteFailed(
                            reason: "Failed to delete HealthKit samples. Error: \(error.localizedDescription)")))
                    }
                    return
                } else {
                    callbackQueue.async {
                        completion?(.success(outcomes))
                    }
                }
            }
        } catch {
            callbackQueue.async {
                completion?(.failure(.deleteFailed(
                    reason: "Failed to delete HealthKit samples. Error: \(error.localizedDescription)")))
            }
        }
    }

    func checkAbilityToDelete(outcomes: [OCKHealthKitOutcome]) throws {

        // All outcomes should be owned by this app

        let areOutcomesOwnedByApp = outcomes.allSatisfy { $0.isOwnedByApp }

        guard areOutcomesOwnedByApp else {
            let message = "Cannot delete samples in HealthKit not owned by this app."
            throw OCKStoreError.deleteFailed(reason: message)
        }

        // All outcomes need to have been retrieved from HealthKit

        let areOutcomesFromHealthKit = outcomes.allSatisfy { outcome in
            isOutcomeFromHealthKit(outcome)
        }

        guard areOutcomesFromHealthKit else {
            let message = "Not all outcomes have been retrieved from HealthKit."
            throw OCKStoreError.deleteFailed(reason: message)
        }
    }

    private func isOutcomeFromHealthKit(_ outcome: Outcome) -> Bool {

        let healthKitUUIDs = outcome.healthKitUUIDs
        let numberOfOutcomeValues = outcome.values.count
        let numberOfHealthKitUUIDs = healthKitUUIDs.count

        guard numberOfOutcomeValues == numberOfHealthKitUUIDs else {
            return false
        }

        let allHealthKitUUIDsExist = healthKitUUIDs.allSatisfy { healthKitUUIDs in
            healthKitUUIDs.isEmpty == false
        }

        return allHealthKitUUIDsExist
    }
}

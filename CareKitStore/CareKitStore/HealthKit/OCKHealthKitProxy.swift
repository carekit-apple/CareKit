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
import HealthKit

class OCKHealthKitProxy {
    private let store = HKHealthStore()

    func requestPermissionIfNecessary(writeTypes: Set<HKSampleType>, completion: @escaping (Error?) -> Void) {
        let authStatuses = writeTypes.map { store.authorizationStatus(for: $0) }
        let needsAuthorization = authStatuses.contains(.notDetermined)

        guard needsAuthorization else {
            completion(nil)
            return
        }

        store.requestAuthorization(toShare: writeTypes, read: writeTypes) { _, error in
            completion(error)
        }
    }

    struct QueryResult {
        let dateRange: DateInterval
        let values: [Double]
        let samples: [HKQuantitySample]
    }

    // MARK: Queries

    func queryValue(identifier: HKQuantityTypeIdentifier, unit: HKUnit, queryType: OCKHealthKitLinkage.QuantityType, in dateRanges: [DateInterval],
                    completion: @escaping (Result<[QueryResult], Error>) -> Void) {
        guard let quantity = HKQuantityType.quantityType(forIdentifier: identifier) else { fatalError("\(identifier) is not a valid quantity!") }
        
        if identifier == .bloodPressureSystolic || identifier == .bloodPressureDiastolic {
            bloodPressureQuery(quantity: quantity, dateRanges: dateRanges, completion: completion)
        } else {
            switch queryType {
            case .cumulative:
                cumulativeQuery(quantity: quantity, unit: unit, in: dateRanges, completion: completion)
            case .discrete:
                discreteQuery(quantity: quantity, unit: unit, in: dateRanges, completion: completion)
            }
        }
    }

    func cumulativeQuery(quantity: HKQuantityType, unit: HKUnit, in dateRanges: [DateInterval],
                         completion: @escaping (Result<[QueryResult], Error>) -> Void) {
        guard !dateRanges.isEmpty else { completion(.success([])); return } // Nothing to query

        var values = dateRanges.map { QueryResult(dateRange: $0, values: [], samples: []) }
        var fetchError: Error?
        let group = DispatchGroup()

        dateRanges.enumerated().forEach { index, event in
            let predicate = HKQuery.predicateForSamples(withStart: event.start, end: event.end, options: [.strictStartDate, .strictEndDate])
            let options: HKStatisticsOptions = [.cumulativeSum]
            let components = Set<Calendar.Component>([.year, .month, .day, .hour, .month, .second])
            let interval = Calendar.current.dateComponents(components, from: event.start, to: event.end)
            let query = HKStatisticsCollectionQuery(quantityType: quantity, quantitySamplePredicate: predicate,
                                                    options: options, anchorDate: event.start, intervalComponents: interval)
            var outerTimesCalled = 0
            query.initialResultsHandler = { _, results, error in
                outerTimesCalled += 1
                assert(outerTimesCalled <= 1, "This handler should never be called more than once. Check the query interval. This is a bug!")
                defer { group.leave() }

                if let error = error {
                    fetchError = error
                    return
                }

                guard let results = results else {
                    fetchError = OCKStoreError.fetchFailed(reason: "Failed to cumulative query for \(quantity).")
                    return
                }

                var innerTimesCalled = 0
                group.enter()
                results.enumerateStatistics(from: event.start, to: event.end.advanced(by: -1)) { statistics, _ in
                    innerTimesCalled += 1
                    assert(innerTimesCalled <= 1, "This handler should never be called more than once. Check the query interval. This is a bug!")
                    defer { group.leave() }

                    if let quantity = statistics.sumQuantity() {
                        let dateRange = DateInterval(start: event.start, end: event.end)
                        values[index] = QueryResult(dateRange: dateRange, values: [quantity.doubleValue(for: unit)], samples: [])
                    }
                }
            }

            group.enter()
            store.execute(query)
        }

        group.notify(queue: .main) {
            if let error = fetchError { completion(.failure(error)); return }
            completion(.success(values))
        }
    }

    func discreteQuery(quantity: HKQuantityType, unit: HKUnit, in dateRanges: [DateInterval],
                       completion: @escaping (Result<[QueryResult], Error>) -> Void) {
        let group = DispatchGroup()
        var values = dateRanges.map({ QueryResult(dateRange: $0, values: [], samples: []) })
        var fetchError: Error?

        for (index, range) in dateRanges.enumerated() {
            let predicate = HKQuery.predicateForSamples(withStart: range.start, end: range.end, options: [.strictStartDate])
            let sorting = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: quantity, predicate: predicate, limit: 999, sortDescriptors: [sorting]) { _, samples, error in
                defer { group.leave() }
                if let error = error { fetchError = error; return }
                guard let samples = samples else { fetchError = OCKStoreError.fetchFailed(reason: "HealthKit query failed!"); return }

                let quantitySamples = samples.compactMap { $0 as? HKQuantitySample }
                assert(quantitySamples.count == samples.count, "Not all samples were HKQuantity samples! Only HKQuantitySamples are supported!")
                let doubleValues = quantitySamples.map { $0.quantity.doubleValue(for: unit) }
                values[index] = QueryResult(dateRange: range, values: doubleValues, samples: quantitySamples)
            }
            group.enter()
            store.execute(query)
        }

        group.notify(queue: .main) {
            if let error = fetchError { completion(.failure(error)); return }
            completion(.success(values))
        }
    }
    
    func bloodPressureQuery(quantity: HKQuantityType, dateRanges: [DateInterval], completion: @escaping (Result<[QueryResult], Error>) -> Void) {
        guard let bloodPressure = HKQuantityType.correlationType(forIdentifier: .bloodPressure) else {
            completion(.failure(OCKStoreError.fetchFailed(reason: "HealthKit query failed!")))
            return
        }

        let group = DispatchGroup()
        var values = dateRanges.map({ QueryResult(dateRange: $0, values: [], samples: []) })
        var fetchError: Error?

        for (index, range) in dateRanges.enumerated() {
            let predicate = HKQuery.predicateForSamples(withStart: range.start, end: range.end, options: [.strictStartDate])
            let sorting = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: bloodPressure, predicate: predicate, limit: 999, sortDescriptors: [sorting]) { _, correlations, error in
                defer { group.leave() }
                if let error = error { fetchError = error; return }
                guard let correlations = correlations else { fetchError = OCKStoreError.fetchFailed(reason: "HealthKit query failed!"); return }
                let quantitySamples = correlations.compactMap { sample -> HKQuantitySample? in
                    guard let correlationSample = sample as? HKCorrelation else {
                        return  nil
                    }
                    return correlationSample.bloodPressureSample(quantityType: quantity, dateRange: range, correlationSampleUuid: correlationSample.uuid)
                }
                guard quantitySamples.count == correlations.count else {
                    fetchError = OCKStoreError.fetchFailed(reason: "Not all samples were HKQuantity samples! Only HKQuantitySamples are supported!")
                    return
                }
                let doubleValues = quantitySamples.map { $0.quantity.doubleValue(for: .millimeterOfMercury()) }
                values[index] = QueryResult(dateRange: range, values: doubleValues, samples: quantitySamples)
            }
            group.enter()
            store.execute(query)
        }
        
        group.notify(queue: .main) {
            if let error = fetchError { completion(.failure(error)); return }
            completion(.success(values))
        }
    }
}

extension HKCorrelation {
    func bloodPressureSample(quantityType: HKQuantityType, dateRange: DateInterval, correlationSampleUuid: UUID?) -> HKQuantitySample? {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic), let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return nil
        }
        guard let systolicSample = self.objects(for: systolicType).first as? HKQuantitySample, let diastolicSample = self.objects(for: diastolicType).first as? HKQuantitySample else {
            return nil
        }
        let systolicQuantity = systolicSample.quantity
        let diastolicQuantity = diastolicSample.quantity
        let systolicValue = systolicQuantity.doubleValue(for: .millimeterOfMercury())
        let diastolicValue = diastolicQuantity.doubleValue(for: .millimeterOfMercury())

        let metadata: [String: Any] = ["systolicValue": systolicValue,
                                       "diastolicValue": diastolicValue,
                                       "startDate": self.startDate.timeIntervalSince1970,
                                       "endDate": self.endDate.timeIntervalSince1970,
                                       "correlationSampleUUID": correlationSampleUuid?.uuidString ?? ""
        ]
        let sample = HKQuantitySample(type: quantityType, quantity: systolicQuantity, start: dateRange.start, end: dateRange.end, metadata: metadata)
        return sample
    }
}

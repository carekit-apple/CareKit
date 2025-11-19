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

extension OCKStoreCoordinator {

    public func anyPatients(matching query: OCKPatientQuery) -> CareStoreQueryResults<OCKAnyPatient> {

        let respondingStores = storesHandlingQuery(query)

        let patientsStreams = respondingStores.map {
            $0.anyPatients(matching: query)
        }

        let patients = combineMany(
            sequences: patientsStreams,
            makeSortDescriptors: {
                return query
                    .sortDescriptors
                    .map(\.nsSortDescriptor)
            }
        )

        return patients
    }

    public func fetchAnyPatients(
        query: OCKPatientQuery,
        callbackQueue: DispatchQueue = .main,
        completion: @escaping OCKResultClosure<[OCKAnyPatient]>
    ) {
        let respondingStores = storesHandlingQuery(query)

        let closures = respondingStores.map({ store in { done in
            store.fetchAnyPatients(query: query, callbackQueue: callbackQueue, completion: done) }
        })

        aggregateAndFlatten(closures, callbackQueue: callbackQueue, completion: completion)
    }

    public func addAnyPatients(
        _ patients: [OCKAnyPatient],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyPatient], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let respondingStore = try firstStoreHandlingPatients(patients)
            respondingStore.addAnyPatients(patients, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.addFailed(
                    reason: "Failed to find store accepting patients. Error: \(error.localizedDescription)")))
            }
        }
    }

    public func updateAnyPatients(
        _ patients: [OCKAnyPatient],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyPatient], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let respondingStore = try firstStoreHandlingPatients(patients)
            respondingStore.updateAnyPatients(patients, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.updateFailed(
                    reason: "Failed to find store accepting patients. Error: \(error.localizedDescription)")))
            }
        }
    }

    public func deleteAnyPatients(
        _ patients: [OCKAnyPatient],
        callbackQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<[OCKAnyPatient], OCKStoreError>) -> Void)? = nil
    ) {
        do {
            let respondingStore = try firstStoreHandlingPatients(patients)
            respondingStore.deleteAnyPatients(patients, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.deleteFailed(
                    reason: "Failed to find store accepting patients. Error: \(error.localizedDescription)")))
            }
        }
    }

    private func firstStoreHandlingPatients(_ patients: [OCKAnyPatient]) throws -> OCKAnyPatientStore {

        let firstMatchingStore = state.withLock { state in

            return state.patientStores.first { store in
                return patients.allSatisfy { patient in
                    return
                        state.delegate?.patientStore(store, shouldHandleWritingPatient: patient) ??
                        patientStore(store, shouldHandleWritingPatient: patient)
                }
            }
        }

        guard let firstMatchingStore else {
            throw OCKStoreError.invalidValue(reason: "Cannot find store to handle patients")
        }

        return firstMatchingStore
    }

    private func storesHandlingQuery(_ query: OCKPatientQuery) -> [OCKAnyReadOnlyPatientStore] {

        return state.withLock { state in

            let stores = state.readOnlyPatientStores + state.patientStores

            let respondingStores = stores.filter { store in
                return
                    state.delegate?.patientStore(store, shouldHandleQuery: query) ??
                    patientStore(store, shouldHandleQuery: query)
            }

            return respondingStores
        }
    }
}

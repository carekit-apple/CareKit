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

extension OCKStoreCoordinator {

    open func fetchAnyPatients(query: OCKAnyPatientQuery, callbackQueue: DispatchQueue = .main,
                               completion: @escaping OCKResultClosure<[OCKAnyPatient]>) {
        let readableStores = readOnlyPatientStores + patientStores
        let respondingStores = readableStores.filter { patientStore($0, shouldHandleQuery: query) }
        let closures = respondingStores.map({ store in { done in
            store.fetchAnyPatients(query: query, callbackQueue: callbackQueue, completion: done) }
        })
        aggregate(closures, callbackQueue: callbackQueue, completion: completion)
    }

    open func addAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKAnyPatient], OCKStoreError>) -> Void)? = nil) {
        do {
            try findStore(forPatients: patients).addAnyPatients(patients, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.addFailed(
                    reason: "Failed to find store accepting patients. Error: \(error.localizedDescription)")))
            }
        }
    }

    open func updateAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue = .main,
                                completion: ((Result<[OCKAnyPatient], OCKStoreError>) -> Void)? = nil) {
        do {
            try findStore(forPatients: patients).updateAnyPatients(patients, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.updateFailed(
                    reason: "Failed to find store accepting patients. Error: \(error.localizedDescription)")))
            }
        }
    }

    open func deleteAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue = .main,
                                completion: ((Result<[OCKAnyPatient], OCKStoreError>) -> Void)? = nil) {
        do {
            try findStore(forPatients: patients).deleteAnyPatients(patients, callbackQueue: callbackQueue, completion: completion)
        } catch {
            callbackQueue.async {
                completion?(.failure(.deleteFailed(
                    reason: "Failed to find store accepting patients. Error: \(error.localizedDescription)")))
            }
        }
    }

    private func findStore(forPatients patients: [OCKAnyPatient]) throws -> OCKAnyPatientStore {
        let matchingStores = patients.compactMap { patient in patientStores.first(where: { patientStore($0, shouldHandleWritingPatient: patient) }) }
        guard matchingStores.count == patients.count else { throw OCKStoreError.invalidValue(reason: "No store could be found for some patients.") }
        guard let store = matchingStores.first else { throw OCKStoreError.invalidValue(reason: "No store could be found for any patients.") }
        guard matchingStores.allSatisfy({ $0 === store }) else { throw OCKStoreError.invalidValue(reason: "Not all patients belong to same store.") }
        return store
    }
}

extension OCKStoreCoordinator: OCKPatientStoreDelegate {
    open func patientStore(_ store: OCKAnyReadOnlyPatientStore, didAddPatients patients: [OCKAnyPatient]) {
        patientDelegate?.patientStore(self, didAddPatients: patients)
    }

    open func patientStore(_ store: OCKAnyReadOnlyPatientStore, didUpdatePatients patients: [OCKAnyPatient]) {
        patientDelegate?.patientStore(self, didUpdatePatients: patients)
    }

    open func patientStore(_ store: OCKAnyReadOnlyPatientStore, didDeletePatients patients: [OCKAnyPatient]) {
        patientDelegate?.patientStore(self, didDeletePatients: patients)
    }
}

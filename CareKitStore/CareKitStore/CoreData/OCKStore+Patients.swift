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

    public func fetchPatients(query: OCKPatientQuery = OCKPatientQuery(), callbackQueue: DispatchQueue = .main,
                            completion: @escaping (Result<[OCKPatient], OCKStoreError>) -> Void) {
        fetchValues(
            predicate: query.basicPredicate(enforceDateInterval: true),
            sortDescriptors: buildSortDescriptors(from: query),
            offset: query.offset,
            limit: query.limit) { result in

            callbackQueue.async {
                completion(result)
            }
        }
    }

    public func addPatients(_ patients: [OCKPatient], callbackQueue: DispatchQueue = .main,
                          completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        transaction(
            inserts: patients, updates: [], deletes: [],
            preInsertValidate: self.validateNumberOfPatients) { result in
            
            callbackQueue.async {
                completion?(result.map(\.inserts))
            }
        }
    }

    public func updatePatients(_ patients: [OCKPatient], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        transaction(inserts: [], updates: patients, deletes: []) { result in
            callbackQueue.async {
                completion?(result.map(\.updates))
            }
        }
    }

    public func deletePatients(_ patients: [OCKPatient], callbackQueue: DispatchQueue = .main,
                             completion: ((Result<[OCKPatient], OCKStoreError>) -> Void)? = nil) {
        transaction(inserts: [], updates: [], deletes: patients) { result in
            callbackQueue.async {
                completion?(result.map(\.deletes))
            }
        }
    }
    
    // MARK: Private

    private func buildSortDescriptors(from query: OCKPatientQuery) -> [NSSortDescriptor] {
        query.sortDescriptors.map { order -> NSSortDescriptor in
            switch order {
            case .effectiveDate(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.effectiveDate, ascending: ascending)
            case .givenName(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.name.givenName, ascending: ascending)
            case .familyName(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.name.familyName, ascending: ascending)
            case .groupIdentifier(let ascending): return NSSortDescriptor(keyPath: \OCKCDPatient.groupIdentifier, ascending: ascending)
            }
        } + query.defaultSortDescriptors()
    }

    private func validateNumberOfPatients() throws {
        let fetchRequest = OCKCDPatient.fetchRequest()
        let numberOfPatients = try context.count(for: fetchRequest)
        if numberOfPatients > 0 {
            let explanation = """
            OCKStore` only supports one patient per store.
            If you would like to have more than one patient, create a new store for that patient.
            """
            throw OCKStoreError.addFailed(reason: explanation)
        }
    }
}

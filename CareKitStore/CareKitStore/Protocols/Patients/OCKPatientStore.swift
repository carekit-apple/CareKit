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

/// Any store from which a single type conforming to `OCKAnyPatient` can be queried is considered `OCKAnyReadOnlyPatientStore`.
public protocol OCKReadablePatientStore: OCKAnyReadOnlyPatientStore {
    associatedtype Patient: OCKAnyPatient & Equatable & Identifiable
    associatedtype PatientQuery: OCKAnyPatientQuery

    /// `fetchPatients` asynchronously retrieves an array of patients from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchPatients(query: PatientQuery, callbackQueue: DispatchQueue,
                       completion: @escaping OCKResultClosure<[Patient]>)

    // MARK: Implementation Provided

    /// `fetchPatient` asynchronously fetches a single patient from the store using its user-defined identifier. If a patient with the specified
    /// identifier does not exist, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - id: A unique user-defined identifier
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchPatient(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<Patient>)
}

/// Any store that can perform read and write operations on a single type conforming to `OCKAnyPatient` is considered an `OCKPatientStore`.
public protocol OCKPatientStore: OCKReadablePatientStore, OCKAnyPatientStore {

    /// `addPatients` asynchronously adds an array of patients to the store.
    ///
    /// - Parameters:
    ///   - patients: An array of patients to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addPatients(_ patients: [Patient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Patient]>?)

    /// `updatePatients` asynchronously updates an array of patients in the store.
    ///
    /// - Parameters:
    ///   - patients: An array of patients to be updated. The patients must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updatePatients(_ patients: [Patient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Patient]>?)

    /// `deletePatients` asynchronously deletes an array of patients from the store.
    ///
    /// - Parameters:
    ///   - patients: An array of patients to be deleted. The patients must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deletePatients(_ patients: [Patient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[Patient]>?)

    // MARK: Implementation Provided

    /// `addPatient` asynchronously adds a patient to the store.
    ///
    /// - Parameters:
    ///   - patient: A patient to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addPatient(_ patient: Patient, callbackQueue: DispatchQueue, completion: OCKResultClosure<Patient>?)

    /// `updatePatient` asynchronously updates a patient in the store.
    ///
    /// - Parameters:
    ///   - patient: Apatients to be updated. The patient must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updatePatient(_ patient: Patient, callbackQueue: DispatchQueue, completion: OCKResultClosure<Patient>?)

    /// `deletePatient` asynchronously deletes a patient from the store.
    ///
    /// - Parameters:
    ///   - patient: A patient to be deleted. The patient must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deletePatient(_ patient: Patient, callbackQueue: DispatchQueue, completion: OCKResultClosure<Patient>?)
}

// MARK: Singular Methods for OCKReadablePatientStore

public extension OCKReadablePatientStore {
    func fetchPatient(withID id: String, callbackQueue: DispatchQueue = .main,
                      completion: @escaping OCKResultClosure<Patient>) {
        var query = OCKPatientQuery(for: Date())
        query.limit = 1
        query.ids = [id]
        query.extendedSortDescriptors = [.effectiveDate(ascending: true)]

        fetchPatients(query: PatientQuery(query), callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No patient with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKPatientStoreProtocol

public extension OCKPatientStore {

    func addPatient(_ patient: Patient, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        addPatients([patient], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add patient: \(patient)")))
    }

    func updatePatient(_ patient: Patient, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        updatePatients([patient], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update patient: \(patient)")))
    }

    func deletePatient(_ patient: Patient, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        deletePatients([patient], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete patient: \(patient)")))
    }
}

// MARK: OCKAnyReadOnlyPatientStore implementations for OCKReadablePatientStore

public extension OCKReadablePatientStore {
    func fetchAnyPatients(query: OCKAnyPatientQuery, callbackQueue: DispatchQueue,
                          completion: @escaping OCKResultClosure<[OCKAnyPatient]>) {
        let patientQuery = PatientQuery(query)
        fetchPatients(query: patientQuery, callbackQueue: callbackQueue) { completion($0.map { $0.map { $0 as OCKAnyPatient } }) }
    }
}

// MARK: OCKAnyPatientStore implementations for OCKPatientStoreProtocol

public extension OCKPatientStore {

    func addAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?) {
        guard let patients = patients as? [Patient] else {
            let message = "Failed to add patients. Not all patients were of the correct type: \(Patient.self)"
            callbackQueue.async { completion?(.failure(.addFailed(reason: message))) }
            return
        }
        addPatients(patients, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyPatient } }) }
    }

    func updateAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?) {
        guard let patients = patients as? [Patient] else {
            let message = "Failed to update patients. Not all patients were of the correct type: \(Patient.self)"
            callbackQueue.async { completion?(.failure(.updateFailed(reason: message))) }
            return
        }
        updatePatients(patients, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyPatient } }) }
    }

    func deleteAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?) {
        guard let patients = patients as? [Patient] else {
            let message = "Failed to delete patients. Not all patients were of the correct type: \(Patient.self)"
            callbackQueue.async { completion?(.failure(.deleteFailed(reason: message))) }
            return
        }
        deletePatients(patients, callbackQueue: callbackQueue) { completion?($0.map { $0.map { $0 as OCKAnyPatient } }) }
    }
}

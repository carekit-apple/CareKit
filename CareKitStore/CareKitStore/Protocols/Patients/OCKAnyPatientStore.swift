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

/// Any store from which types conforming to `OCKAnyPatient` can be queried is considered `OCKAnyReadOnlyPatientStore`.
public protocol OCKAnyReadOnlyPatientStore: AnyObject {

    /// The delegate receives callbacks when the contents of the patient store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    var patientDelegate: OCKPatientStoreDelegate? { get set }

    /// `fetchAnyPatients` asynchronously retrieves an array of patients from the store.
    ///
    /// - Parameters:
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyPatients(query: OCKAnyPatientQuery, callbackQueue: DispatchQueue,
                          completion: @escaping OCKResultClosure<[OCKAnyPatient]>)

    // MARK: Singular Methods - Implementation Provided

    /// `fetchAnyPatient` asynchronously retrieves a single patient from the store.
    ///
    /// - Parameters:
    ///   - id: The identifier of the item to be fetched.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func fetchAnyPatient(withID id: String, callbackQueue: DispatchQueue, completion: @escaping OCKResultClosure<OCKAnyPatient>)
}

/// Any store able to write to one ore more types conforming to `OCKAnyPatient` is considered an `OCKAnyPatientStore`.
public protocol OCKAnyPatientStore: OCKAnyReadOnlyPatientStore {

    /// `addAnyPatients` asynchronously adds an array of patients to the store.
    ///
    /// - Parameters:
    ///   - patients: A array of patients to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?)

    /// `updateAnyPatients` asynchronously updates an array of patients in the store.
    ///
    /// - Parameters:
    ///   - patients: An array of patients to be updated. The patients must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?)

    /// `deleteAnyPatients` asynchronously deletes an array of patients from the store.
    ///
    /// - Parameters:
    ///   - patients: An array of patients to be deleted. The patients must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyPatients(_ patients: [OCKAnyPatient], callbackQueue: DispatchQueue, completion: OCKResultClosure<[OCKAnyPatient]>?)

    // MARK: Singular Methods - Implementation Provided

    /// `addAnyPatient` asynchronously adds a single patient to the store.
    ///
    /// - Parameters:
    ///   - patient: A single patient to be added to the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func addAnyPatient(_ patient: OCKAnyPatient, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyPatient>?)

    /// `updateAnyPatient` asynchronously updates a single patient in the store.
    ///
    /// - Parameters:
    ///   - patient: An single patient to be updated. The patients must already exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func updateAnyPatient(_ patient: OCKAnyPatient, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyPatient>?)

    /// `deleteAnyPatient` asynchronously deletes a single patient from the store.
    ///
    /// - Parameters:
    ///   - patients: A single patient to be deleted. The patients must exist in the store.
    ///   - callbackQueue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on the provided callback queue.
    func deleteAnyPatient(_ patient: OCKAnyPatient, callbackQueue: DispatchQueue, completion: OCKResultClosure<OCKAnyPatient>?)
}

// MARK: Singular Methods for OCKAnyReadOnlyPatientStore

public extension OCKAnyReadOnlyPatientStore {
    func fetchAnyPatient(withID id: String, callbackQueue: DispatchQueue = .main,
                         completion: @escaping OCKResultClosure<OCKAnyPatient>) {
        var query = OCKPatientQuery(for: Date())
        query.limit = 1
        query.extendedSortDescriptors = [.effectiveDate(ascending: true)]
        query.ids = [id]

        fetchAnyPatients(query: query, callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No patient with ID: \(id)")))
    }
}

// MARK: Singular Methods for OCKAnyPatientStore

public extension OCKAnyPatientStore {
    func addAnyPatient(_ patient: OCKAnyPatient, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyPatient>? = nil) {
        addAnyPatients([patient], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add patient: \(patient)")))
    }

    func updateAnyPatient(_ patient: OCKAnyPatient, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyPatient>? = nil) {
        updateAnyPatients([patient], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update patient: \(patient)")))
    }

    func deleteAnyPatient(_ patient: OCKAnyPatient, callbackQueue: DispatchQueue = .main, completion: OCKResultClosure<OCKAnyPatient>? = nil) {
        deleteAnyPatients([patient], callbackQueue: callbackQueue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete patient: \(patient)")))
    }
}

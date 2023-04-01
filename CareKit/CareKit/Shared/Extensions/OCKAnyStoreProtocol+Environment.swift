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

import CareKitStore
import Foundation
import SwiftUI


private let missingStoreFailureMsg = "A CareKit store needs to be injected into the environment"

// The store needs to be passed through the environment for the `Fetched` dynamic
// property. Using environment values over environment objects is preferred here
// because our store is not an observable object that publishes changes.
public extension EnvironmentValues {

    /// A repository for CareKit information.
    var careStore: OCKAnyStoreProtocol {
        get { self[CareStoreKey.self] }
        set { self[CareStoreKey.self] = newValue }
    }
}

private struct CareStoreKey: EnvironmentKey {

    /// The default store provides an empty store implementation. A concrete implementation
    /// should always be injected into the environment.
    static let defaultValue: OCKAnyStoreProtocol = FatalCareStore()
}

/// A store implementation that fatal errors when CRUD methods are performed.
private class FatalCareStore: OCKStoreProtocol {

    typealias OCKEvent = CareKitStore.OCKEvent<OCKTask, OCKOutcome>

    // MARK: - Care Plan

    func carePlans(matching query: OCKCarePlanQuery) -> CareStoreQueryResults<OCKCarePlan> {
        fatalError(missingStoreFailureMsg)
    }

    func fetchCarePlans(
        query: OCKCarePlanQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKCarePlan]>
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func addCarePlans(
        _ plans: [OCKCarePlan],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKCarePlan]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func updateCarePlans(
        _ plans: [OCKCarePlan],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKCarePlan]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func deleteCarePlans(
        _ plans: [OCKCarePlan],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKCarePlan]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    // MARK: - Contact

    func contacts(matching query: OCKContactQuery) -> CareStoreQueryResults<OCKContact> {
        fatalError(missingStoreFailureMsg)
    }

    func addContacts(
        _ contacts: [OCKContact],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKContact]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func updateContacts(
        _ contacts: [OCKContact],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKContact]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func deleteContacts(
        _ contacts: [OCKContact],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKContact]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func fetchContacts(
        query: OCKContactQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKContact]>
    ) {
        fatalError(missingStoreFailureMsg)
    }

    // MARK: - Patient

    func patients(matching query: OCKPatientQuery) -> CareStoreQueryResults<OCKPatient> {
        fatalError(missingStoreFailureMsg)
    }

    func fetchPatients(
        query: OCKPatientQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKPatient]>
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func addPatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func updatePatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func deletePatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    // MARK: - Events

    func fetchEvents(
        taskID: String,
        query: OCKEventQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKEvent]>
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func fetchEvent(
        forTask task: OCKTask,
        occurrence: Int,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<OCKEvent>
    ) {
        fatalError(missingStoreFailureMsg)
    }

    // MARK: - Tasks

    func tasks(matching query: OCKTaskQuery) -> CareStoreQueryResults<OCKTask> {
        fatalError(missingStoreFailureMsg)
    }

    func addTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKTask]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func fetchTasks(
        query: OCKTaskQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKTask]>
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func updateTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKTask]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func deleteTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKTask]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    // MARK: - Outcomes

    func outcomes(matching query: OCKOutcomeQuery) -> CareStoreQueryResults<OCKOutcome> {
        fatalError(missingStoreFailureMsg)
    }

    func addOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKOutcome]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func updateOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKOutcome]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func deleteOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKOutcome]>?
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func fetchOutcomes(
        query: OCKOutcomeQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKOutcome]>
    ) {
        fatalError(missingStoreFailureMsg)
    }

    func reset() throws {
        fatalError(missingStoreFailureMsg)
    }
}


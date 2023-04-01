/*
 Copyright (c) 2020, Apple Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of  contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN  WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

@testable import CareKit
@testable import CareKitStore
import Foundation


/// A light wrapper around an `OCKStore`.
class MockStore: OCKStoreProtocol {

    typealias OCKEvent = CareKitStore.OCKEvent<OCKTask, OCKOutcome>

    let store: OCKStore

    init(name: String) {
        self.store = OCKStore(name: name, type: .inMemory)
    }

    /// If this property is set, all store CRUD methods will fail.
    var errorOverride: OCKStoreError?

    // MARK: - Care Plan

    func carePlans(matching query: OCKCarePlanQuery) -> CareStoreQueryResults<OCKCarePlan> {
        store.carePlans(matching: query)
    }

    func fetchCarePlans(
        query: OCKCarePlanQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKCarePlan]>
    ) {
        if let error = errorOverride {
            completion(.failure(error))
        } else {
            store.fetchCarePlans(query: query, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func addCarePlans(
        _ plans: [OCKCarePlan],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKCarePlan]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.addCarePlans(plans, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func updateCarePlans(
        _ plans: [OCKCarePlan],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKCarePlan]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.updateCarePlans(plans, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func deleteCarePlans(
        _ plans: [OCKCarePlan],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKCarePlan]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.deleteCarePlans(plans, callbackQueue: callbackQueue, completion: completion)
        }
    }

    // MARK: - Contact

    func contacts(matching query: OCKContactQuery) -> CareStoreQueryResults<OCKContact> {
        store.contacts(matching: query)
    }

    func addContacts(
        _ contacts: [OCKContact],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKContact]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.addContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func updateContacts(
        _ contacts: [OCKContact],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKContact]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.updateContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func deleteContacts(
        _ contacts: [OCKContact],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKContact]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.deleteContacts(contacts, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func fetchContacts(
        query: OCKContactQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKContact]>
    ) {
        if let error = errorOverride {
            completion(.failure(error))
        } else {
            store.fetchContacts(query: query, callbackQueue: callbackQueue, completion: completion)
        }
    }

    // MARK: - Patient

    func patients(matching query: OCKPatientQuery) -> CareStoreQueryResults<OCKPatient> {
        store.patients(matching: query)
    }

    func fetchPatients(
        query: OCKPatientQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKPatient]>
    ) {
        if let error = errorOverride {
            completion(.failure(error))
        } else {
            store.fetchPatients(query: query, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func addPatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.addPatients(patients, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func updatePatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.updatePatients(patients, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func deletePatients(
        _ patients: [OCKPatient],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKPatient]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.deletePatients(patients, callbackQueue: callbackQueue, completion: completion)
        }
    }

    // MARK: - Tasks

    func tasks(matching query: OCKTaskQuery) -> CareStoreQueryResults<OCKTask> {
        store.tasks(matching: query)
    }

    func fetchEvents(
        query: OCKEventQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[Event]>) {

        if let error = errorOverride {
            completion(.failure(error))
        } else {
            store.fetchEvents(query: query, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func fetchEvent(
        forTask task: OCKTask,
        occurrence: Int,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<OCKEvent>
    ) {
        if let error = errorOverride {
            completion(.failure(error))
        } else {
            store.fetchEvent(forTask: task, occurrence: occurrence, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func addTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKTask]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.addTasks(tasks, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func fetchTasks(
        query: OCKTaskQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKTask]>
    ) {
        if let error = errorOverride {
            completion(.failure(error))
        } else {
            store.fetchTasks(query: query, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func updateTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKTask]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.updateTasks(tasks, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func deleteTasks(
        _ tasks: [OCKTask],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKTask]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.deleteTasks(tasks, callbackQueue: callbackQueue, completion: completion)
        }
    }

    // MARK: - Outcomes

    func outcomes(matching query: OCKOutcomeQuery) -> CareStoreQueryResults<OCKOutcome> {
        store.outcomes(matching: query)
    }

    func fetchOutcomes(
        query: OCKOutcomeQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKOutcome]>
    ) {
        if let error = errorOverride {
            completion(.failure(error))
        } else {
            store.fetchOutcomes(query: query, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func addOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKOutcome]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.addOutcomes(outcomes, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func updateOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKOutcome]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.updateOutcomes(outcomes, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func deleteOutcomes(
        _ outcomes: [OCKOutcome],
        callbackQueue: DispatchQueue,
        completion: OCKResultClosure<[OCKOutcome]>?
    ) {
        if let error = errorOverride {
            completion?(.failure(error))
        } else {
            store.deleteOutcomes(outcomes, callbackQueue: callbackQueue, completion: completion)
        }
    }

    func reset() throws {
        assertionFailure("Not implemented")
    }
}


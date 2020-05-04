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

private let backgroundQueue = DispatchQueue(label: "CareKit", qos: .background)

// WARNING: These extensions are intended for use exclusively in unit tests.

extension OCKAnyReadOnlyPatientStore {
    func fetchAnyPatientsAndWait(query: OCKAnyPatientQuery) throws -> [OCKAnyPatient] {
        try performSynchronously { self.fetchAnyPatients(query: query, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKAnyPatientStore {

    @discardableResult
    func addAnyPatientsAndWait(_ patients: [OCKAnyPatient]) throws -> [OCKAnyPatient] {
        try performSynchronously { self.addAnyPatients(patients, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addAnyPatientAndWait(_ patient: OCKAnyPatient) throws -> OCKAnyPatient {
        try performSynchronously { self.addAnyPatient(patient, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKReadablePatientStore {
    func fetchPatientsAndWait(query: PatientQuery = PatientQuery()) throws -> [Patient] {
        try performSynchronously { self.fetchPatients(query: query, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func fetchPatientAndWait(id: String) throws -> Patient {
        try performSynchronously { self.fetchPatient(withID: id, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKPatientStore {
    @discardableResult
    func addPatientsAndWait(_ patients: [Patient]) throws -> [Patient] {
        try performSynchronously { self.addPatients(patients, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addPatientAndWait(_ patient: Patient) throws -> Patient {
        try performSynchronously { self.addPatient(patient, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updatePatientsAndWait(_ patients: [Patient]) throws -> [Patient] {
        try performSynchronously { self.updatePatients(patients, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updatePatientAndWait(_ patient: Patient) throws -> Patient {
        try performSynchronously { self.updatePatient(patient, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deletePatientsAndWait(_ patients: [Patient]) throws -> [Patient] {
        try performSynchronously { self.deletePatients(patients, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deletePatientAndWait(_ patient: Patient) throws -> Patient {
        try performSynchronously { self.deletePatient(patient, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKReadableCarePlanStore {
    func fetchCarePlansAndWait(query: PlanQuery = PlanQuery()) throws -> [Plan] {
        try performSynchronously { self.fetchCarePlans(query: query, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func fetchCarePlanAndWait(id: String) throws -> Plan? {
        try performSynchronously { self.fetchCarePlan(withID: id, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKCarePlanStore {
    @discardableResult
    func addCarePlansAndWait(_ plans: [Plan]) throws -> [Plan] {
        try performSynchronously { self.addCarePlans(plans, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addCarePlanAndWait(_ plan: Plan) throws -> Plan {
        try performSynchronously { self.addCarePlan(plan, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateCarePlansAndWait(_ plans: [Plan]) throws -> [Plan] {
        try performSynchronously { self.updateCarePlans(plans, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateCarePlanAndWait(_ plan: Plan) throws -> Plan {
        try performSynchronously { self.updateCarePlan(plan, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteCarePlansAndWait(_ plans: [Plan]) throws -> [Plan] {
        try performSynchronously { self.deleteCarePlans(plans, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteCarePlanAndWait(_ plan: Plan) throws -> Plan {
        try performSynchronously { self.deleteCarePlan(plan, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKReadableContactStore {
    func fetchContactAndWait(id: String) throws -> Contact? {
        try performSynchronously { self.fetchContact(withID: id, callbackQueue: backgroundQueue, completion: $0) }
    }

    func fetchContactsAndWait(query: ContactQuery = ContactQuery()) throws -> [Contact] {
        try performSynchronously { self.fetchContacts(query: query, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKContactStore {
    @discardableResult
    func addContactsAndWait(_ contacts: [Contact]) throws -> [Contact] {
        return try performSynchronously { self.addContacts(contacts, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addContactAndWait(_ contact: Contact) throws -> Contact {
        try performSynchronously { self.addContact(contact, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateContactsAndWait(_ contacts: [Contact]) throws -> [Contact] {
        try performSynchronously { self.updateContacts(contacts, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateContactAndWait(_ contact: Contact) throws -> Contact {
        try performSynchronously { self.updateContact(contact, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteContactsAndWait(_ contacts: [Contact]) throws -> [Contact] {
        try performSynchronously { self.deleteContacts(contacts, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteContactAndWait(_ contact: Contact) throws -> Contact {
        try performSynchronously { self.deleteContact(contact, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKReadableTaskStore {
    func fetchTasksAndWait(query: TaskQuery = TaskQuery()) throws -> [Task] {
        try performSynchronously { self.fetchTasks(query: query, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKTaskStore {
    @discardableResult
    func addTasksAndWait(_ tasks: [Task]) throws -> [Task] {
        try performSynchronously { self.addTasks(tasks, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addTaskAndWait(_ task: Task) throws -> Task {
        try performSynchronously { self.addTask(task, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateTasksAndWait(_ tasks: [Task]) throws -> [Task] {
        try performSynchronously { self.updateTasks(tasks, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateTaskAndWait(_ task: Task) throws -> Task {
        try performSynchronously { self.updateTask(task, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteTasksAndWait(_ tasks: [Task]) throws -> [Task] {
        try performSynchronously { self.deleteTasks(tasks, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteTaskAndWait(_ task: Task) throws -> Task {
        try performSynchronously { self.deleteTask(task, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKReadableOutcomeStore {
    func fetchOutcomesAndWait(query: OutcomeQuery = OutcomeQuery()) throws -> [Outcome] {
        try performSynchronously { self.fetchOutcomes(query: query, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKOutcomeStore {
    @discardableResult
    func addOutcomesAndWait(_ outcomes: [Outcome]) throws -> [Outcome] {
        try performSynchronously { self.addOutcomes(outcomes, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addOutcomeAndWait(_ outcome: Outcome) throws -> Outcome {
        try performSynchronously { self.addOutcome(outcome, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateOutcomesAndWait(_ outcomes: [Outcome]) throws -> [Outcome] {
        try performSynchronously { self.updateOutcomes(outcomes, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateOutcomeAndWait(_ outcome: Outcome) throws -> Outcome {
        try performSynchronously { self.updateOutcome(outcome, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteOutcomesAndWait(_ outcomes: [Outcome]) throws -> [Outcome] {
        try performSynchronously { self.deleteOutcomes(outcomes, callbackQueue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteOutcomeAndWait(_ outcome: Outcome) throws -> Outcome {
        try performSynchronously { self.deleteOutcome(outcome, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKReadOnlyEventStore {
    func fetchEventsAndWait(taskID: String, query: OCKEventQuery) throws -> [OCKEvent<Task, Outcome>] {
        try performSynchronously { self.fetchEvents(taskID: taskID, query: query, callbackQueue: backgroundQueue, completion: $0) }
    }

    func fetchEventAndWait(forTask task: Task, occurrence: Int) throws -> Event {
        try performSynchronously { self.fetchEvent(forTask: task, occurrence: occurrence, callbackQueue: backgroundQueue, completion: $0) }
    }

    // MARK: Adherence

    func fetchAdherenceAndWait(query: OCKAdherenceQuery) throws -> [OCKAdherence] {
        try performSynchronously { self.fetchAdherence(query: query, callbackQueue: backgroundQueue, completion: $0) }
    }

    // MARK: Insights

    func fetchInsightsAndWait(query: OCKInsightQuery) throws -> [Double] {
        try performSynchronously { self.fetchInsights(query: query, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKAnyTaskStore {
    @discardableResult
    func addAnyTaskAndWait(_ task: OCKAnyTask) throws -> OCKAnyTask {
        try performSynchronously { self.addAnyTask(task, callbackQueue: backgroundQueue, completion: $0) }
    }
}

extension OCKStore {

    func mergeRevisionAndWait(_ revision: OCKRevisionRecord) throws {
        try performSynchronously {
            self.mergeRevision(revision, completion: $0)
        }
    }

    func syncAndWait(mode: OCKStore.SynchronizationPolicy = .mergeDeviceRecordsWithRemote) throws {
        try performSynchronously {
            self.synchronize(policy: mode, completion: $0)
        }
    }
}

private func performSynchronously<T>(
    _ closure: @escaping (@escaping (Result<T, OCKStoreError>) -> Void) -> Void) throws -> T {

    let timeout: TimeInterval = 10.0
    let dispatchGroup = DispatchGroup()
    var closureResult: Result<T, OCKStoreError> = .failure(.timedOut(
        reason: "Timed out after \(timeout) seconds."))
    dispatchGroup.enter()
    DispatchQueue.global(qos: .background).async {
        closure { result in
            closureResult = result
            dispatchGroup.leave()
        }
    }
    _ = dispatchGroup.wait(timeout: .now() + timeout)
    return try closureResult.get()
}

private func performSynchronously(
    _ closure: @escaping (@escaping (Error?) -> Void) -> Void) throws {

    let group = DispatchGroup()
    group.enter()

    var syncError: Error?

    DispatchQueue.global(qos: .background).async {
        closure({ error in
            syncError = error
            group.leave()
        })
    }

    group.wait()

    if let error = syncError {
        throw error
    }
}

extension OCKCoreDataTaskStoreProtocol {
    @discardableResult
    func addUpdateOrDeleteTasksAndWait(addOrUpdate tasksToAddOrUpdate: [Task],
                                       delete tasksToDelete: [Task]) throws -> ([Task], [Task], [Task]) {
        try performSynchronously {
            self.addUpdateOrDeleteTasks(
                addOrUpdate: tasksToAddOrUpdate,
                delete: tasksToDelete,
                callbackQueue: backgroundQueue, completion: $0)
        }
    }
}

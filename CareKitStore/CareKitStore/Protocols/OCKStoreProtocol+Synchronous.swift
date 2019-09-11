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

// This is helper method wraps stores' asychronous methods to make them synchronous.
internal func performSynchronously<T>(_ closure: (@escaping (Result<T, OCKStoreError>) -> Void) -> Void) throws -> T {
    let timeout: TimeInterval = 10.0
    let dispatchGroup = DispatchGroup()
    var closureResult: Result<T, OCKStoreError> = .failure(.timedOut(reason: "Timed out after \(timeout) seconds."))
    dispatchGroup.enter()
    closure { result in
        closureResult = result
        dispatchGroup.leave()
    }
    _ = dispatchGroup.wait(timeout: .now() + timeout)
    return try closureResult.get()
}

private let backgroundQueue = DispatchQueue(label: "CareKit", qos: .background)

internal extension OCKStoreProtocol {
    // MARK: Patients

    func fetchPatientsAndWait(_ anchor: OCKPatientAnchor? = nil, query: OCKPatientQuery? = nil) throws -> [Patient] {
        return try performSynchronously { fetchPatients(anchor, query: query, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func fetchPatientAndWait(identifier: String) throws -> Patient {
        return try performSynchronously { fetchPatient(withIdentifier: identifier, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addPatientsAndWait(_ patients: [Patient]) throws -> [Patient] {
        return try performSynchronously { addPatients(patients, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addPatientAndWait(_ patient: Patient) throws -> Patient {
        return try performSynchronously { addPatient(patient, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updatePatientsAndWait(_ patients: [Patient]) throws -> [Patient] {
        return try performSynchronously { updatePatients(patients, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updatePatientAndWait(_ patient: Patient) throws -> Patient {
        return try performSynchronously { updatePatient(patient, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deletePatientsAndWait(_ patients: [Patient]) throws -> [Patient] {
        return try performSynchronously { deletePatients(patients, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deletePatientAndWait(_ patient: Patient) throws -> Patient {
        return try performSynchronously { deletePatient(patient, queue: backgroundQueue, completion: $0) }
    }

    // MARK: Care Plans

    func fetchCarePlansAndWait(_ anchor: OCKCarePlanAnchor? = nil, query: OCKCarePlanQuery? = nil) throws -> [Plan] {
        return try performSynchronously { fetchCarePlans(anchor, query: query, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func fetchCarePlanAndWait(identifier: String) throws -> Plan? {
        return try performSynchronously { fetchCarePlan(withIdentifier: identifier, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addCarePlansAndWait(_ plans: [Plan]) throws -> [Plan] {
        return try performSynchronously { addCarePlans(plans, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addCarePlanAndWait(_ plan: Plan) throws -> Plan {
        return try performSynchronously { addCarePlan(plan, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateCarePlansAndWait(_ plans: [Plan]) throws -> [Plan] {
        return try performSynchronously { updateCarePlans(plans, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateCarePlanAndWait(_ plan: Plan) throws -> Plan {
        return try performSynchronously { updateCarePlan(plan, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteCarePlansAndWait(_ plans: [Plan]) throws -> [Plan] {
        return try performSynchronously { deleteCarePlans(plans, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteCarePlanAndWait(_ plan: Plan) throws -> Plan {
        return try performSynchronously { deleteCarePlan(plan, queue: backgroundQueue, completion: $0) }
    }

    // MARK: Contacts
    func fetchContactAndWait(identifier: String) throws -> Contact? {
        return try performSynchronously { fetchContact(withIdentifier: identifier, queue: backgroundQueue, completion: $0) }
    }

    func fetchContactsAndWait(_ anchor: OCKContactAnchor? = nil, query: OCKContactQuery? = nil) throws -> [Contact] {
        return try performSynchronously { fetchContacts(anchor, query: query, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addContactsAndWait(_ contacts: [Contact]) throws -> [Contact] {
        return try performSynchronously { addContacts(contacts, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addContactAndWait(_ contact: Contact) throws -> Contact {
        return try performSynchronously { addContact(contact, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateContactsAndWait(_ contacts: [Contact]) throws -> [Contact] {
        return try performSynchronously { updateContacts(contacts, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateContactAndWait(_ contact: Contact) throws -> Contact {
        return try performSynchronously { updateContact(contact, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteContactsAndWait(_ contacts: [Contact]) throws -> [Contact] {
        return try performSynchronously { deleteContacts(contacts, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteContactAndWait(_ contact: Contact) throws -> Contact {
        return try performSynchronously { deleteContact(contact, queue: backgroundQueue, completion: $0) }
    }

    // MARK: Tasks

    func fetchTasksAndWait(_ anchor: OCKTaskAnchor? = nil, query: OCKTaskQuery? = nil) throws -> [Task] {
        return try performSynchronously { fetchTasks(anchor, query: query, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addTasksAndWait(_ tasks: [Task]) throws -> [Task] {
        return try performSynchronously { addTasks(tasks, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addTaskAndWait(_ task: Task) throws -> Task {
        return try performSynchronously { addTask(task, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateTasksAndWait(_ tasks: [Task]) throws -> [Task] {
        return try performSynchronously { updateTasks(tasks, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateTaskAndWait(_ task: Task) throws -> Task {
        return try performSynchronously { updateTask(task, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteTasksAndWait(_ tasks: [Task]) throws -> [Task] {
        return try performSynchronously { deleteTasks(tasks, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteTaskAndWait(_ task: Task) throws -> Task {
        return try performSynchronously { deleteTask(task, queue: backgroundQueue, completion: $0) }
    }

    // MARK: Outcomes

    func fetchOutcomesAndWait(_ anchor: OCKOutcomeAnchor? = nil, query: OCKOutcomeQuery? = nil) throws -> [Outcome] {
        return try performSynchronously { fetchOutcomes(anchor, query: query, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addOutcomesAndWait(_ outcomes: [Outcome]) throws -> [Outcome] {
        return try performSynchronously { addOutcomes(outcomes, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func addOutcomeAndWait(_ outcome: Outcome) throws -> Outcome {
        return try performSynchronously { addOutcome(outcome, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateOutcomesAndWait(_ outcomes: [Outcome]) throws -> [Outcome] {
        return try performSynchronously { updateOutcomes(outcomes, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func updateOutcomeAndWait(_ outcome: Outcome) throws -> Outcome {
        return try performSynchronously { updateOutcome(outcome, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteOutcomesAndWait(_ outcomes: [Outcome]) throws -> [Outcome] {
        return try performSynchronously { deleteOutcomes(outcomes, queue: backgroundQueue, completion: $0) }
    }

    @discardableResult
    func deleteOutcomeAndWait(_ outcome: Outcome) throws -> Outcome {
        return try performSynchronously { deleteOutcome(outcome, queue: backgroundQueue, completion: $0) }
    }

    // MARK: Events

    func fetchEventAndWait(taskVersionID: OCKLocalVersionID, occurenceIndex: Int) throws -> OCKEvent<Task, Outcome> {
        return try performSynchronously {
            fetchEvent(withTaskVersionID: taskVersionID, occurenceIndex: occurenceIndex, queue: backgroundQueue, completion: $0)
        }
    }

    func fetchEventsAndWait(taskIdentifier: String, query: OCKEventQuery) throws -> [OCKEvent<Task, Outcome>] {
        return try performSynchronously {
            fetchEvents(taskIdentifier: taskIdentifier, query: query, queue: backgroundQueue, completion: $0)
        }
    }

    // MARK: Adherence

    func fetchAdherenceAndWait(forTasks identifiers: [String]? = nil, query: OCKAdherenceQuery<Event>) throws -> [OCKAdherence] {
        return try performSynchronously {
            fetchAdherence(forTasks: identifiers, query: query, queue: backgroundQueue, completion: $0)
        }
    }

    // MARK: Insights

    func fetchInsightsAndWait(forTask identifier: String, query: OCKInsightQuery<Event>) throws -> [Double] {
        return try performSynchronously {
            fetchInsights(forTask: identifier, query: query, queue: backgroundQueue, completion: $0)
        }
    }
}

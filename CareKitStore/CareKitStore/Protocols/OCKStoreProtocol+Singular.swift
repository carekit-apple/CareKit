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

public extension OCKStoreProtocol {
    // MARK: Patients

    func fetchPatient(withIdentifier identifier: String, queue: DispatchQueue = .main,
                      completion: @escaping OCKResultClosure<Patient>) {
        var query = OCKPatientQuery(for: Date())
        query.limit = 1
        query.sortDescriptors = [.effectiveDate(ascending: true)]
        fetchPatients(.patientIdentifiers([identifier]), query: query, queue: queue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No patient with identifier: \(identifier)")))
    }

    func addPatient(_ patient: Patient, queue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        addPatients([patient], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add patient: \(patient)")))
    }

    func updatePatient(_ patient: Patient, queue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        updatePatients([patient], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update patient: \(patient)")))
    }

    func deletePatient(_ patient: Patient, queue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        deletePatients([patient], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete patient: \(patient)")))
    }

    // MARK: CarePlans

    func fetchCarePlan(withIdentifier identifier: String, queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Plan>) {
        var query = OCKCarePlanQuery(for: Date())
        query.limit = 1
        query.sortDescriptors = [.effectiveDate(ascending: true)]
        fetchCarePlans(.carePlanIdentifiers([identifier]), query: query, queue: queue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No care plan with identifier: \(identifier)")))
    }

    func addCarePlan(_ plan: Plan, queue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        addCarePlans([plan], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add care plan: \(plan)")))
    }

    func updateCarePlan(_ plan: Plan, queue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        updateCarePlans([plan], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update care plan: \(plan)")))
    }

    func deleteCarePlan(_ plan: Plan, queue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        deleteCarePlans([plan], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete care plan: \(plan)")))
    }

    // MARK: Contacts

    func fetchContact(withIdentifier identifier: String, queue: DispatchQueue = .main,
                      completion: @escaping OCKResultClosure<Contact>) {
        var query = OCKContactQuery(for: Date())
        query.limit = 1
        query.sortDescriptors = [.effectiveDate(ascending: true)]
        fetchContacts(.contactIdentifier([identifier]), query: query, queue: queue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No contact with identifier: \(identifier)")))
    }

    func addContact(_ contact: Contact, queue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        addContacts([contact], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add contact: \(contact)")))
    }

    func updateContact(_ contact: Contact, queue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        updateContacts([contact], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update contact: \(contact)")))
    }

    func deleteContact(_ contact: Contact, queue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        deleteContacts([contact], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete contact: \(contact)")))
    }

    // MARK: Tasks

    func fetchTask(withIdentifier identifier: String, queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Task>) {
        var query = OCKTaskQuery(for: Date())
        query.sortDescriptors = [.effectiveDate(ascending: true)]
        query.limit = 1
        fetchTasks(.taskIdentifiers([identifier]), query: query, queue: queue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No task with identifier: \(identifier)")))
    }

    func fetchTask(withVersionID versionID: OCKLocalVersionID, queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Task>) {
        fetchTasks(.taskVersions([versionID]), query: nil, queue: queue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No task with versionID: \(versionID)")))
    }

    func addTask(_ task: Task, queue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        addTasks([task], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add task \(task)")))
    }

    func updateTask(_ task: Task, queue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        updateTasks([task], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update task: \(task)")))
    }

    func deleteTask(_ task: Task, queue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        deleteTasks([task], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete task: \(task)")))
    }

    // MARK: Outcomes

    func fetchOutcome(_ anchor: OCKOutcomeAnchor?, query: OCKOutcomeQuery?,
                      queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Outcome>) {
        fetchOutcomes(anchor, query: query, queue: queue, completion:
            chooseFirst(then: completion, replacementError: .fetchFailed(reason: "No matching outcome found")))
    }

    func addOutcome(_ outcome: Outcome, queue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        addOutcomes([outcome], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .addFailed(reason: "Failed to add outcome: \(outcome)")))
    }

    func updateOutcome(_ outcome: Outcome, queue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        updateOutcomes([outcome], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .updateFailed(reason: "Failed to update outcome: \(outcome)")))
    }

    func deleteOutcome(_ outcome: Outcome, queue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        deleteOutcomes([outcome], queue: queue, completion:
            chooseFirst(then: completion, replacementError: .deleteFailed(reason: "Failed to delete outcome: \(outcome)")))
    }
}

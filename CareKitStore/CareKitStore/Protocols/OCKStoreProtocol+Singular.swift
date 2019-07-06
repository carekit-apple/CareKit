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
                      completion: @escaping OCKResultClosure<Patient?>) {
        fetchPatients(.patientIdentifiers([identifier]), query: nil, queue: queue, completion: makeNonOptionalResultClosure(completion))
    }
    
    func addPatient(_ patient: Patient, queue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        addPatients([patient], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func updatePatient(_ patient: Patient, queue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        updatePatients([patient], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func deletePatient(_ patient: Patient, queue: DispatchQueue = .main, completion: OCKResultClosure<Patient>? = nil) {
        deletePatients([patient], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    // MARK: CarePlans
    
    func fetchCarePlan(withIdentifier identifier: String, queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Plan?>) {
        fetchCarePlans(.carePlanIdentifiers([identifier]), query: nil, queue: queue, completion: makeNonOptionalResultClosure(completion))
    }
    
    func addCarePlan(_ plan: Plan, queue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        addCarePlans([plan], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func updateCarePlan(_ plan: Plan, queue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        updateCarePlans([plan], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func deleteCarePlan(_ plan: Plan, queue: DispatchQueue = .main, completion: OCKResultClosure<Plan>? = nil) {
        deleteCarePlans([plan], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    // MARK: Contacts
    
    func fetchContact(withIdentifier identifier: String, queue: DispatchQueue = .main,
                      completion: @escaping OCKResultClosure<Contact?>) {
        fetchContacts(.contactIdentifier([identifier]), query: nil, queue: queue, completion: makeNonOptionalResultClosure(completion))
    }
    
    func addContact(_ contact: Contact, queue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        addContacts([contact], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func updateContact(_ contact: Contact, queue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        updateContacts([contact], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func deleteContact(_ contact: Contact, queue: DispatchQueue = .main, completion: OCKResultClosure<Contact>? = nil) {
        deleteContacts([contact], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    // MARK: Tasks
    
    func fetchTask(withIdentifier identifier: String, queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Task?>) {
        fetchTasks(.taskIdentifiers([identifier]), query: nil, queue: queue, completion: makeNonOptionalResultClosure(completion))
    }
    
    func fetchTask(withVersionID versionID: OCKLocalVersionID, queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Task?>) {
        fetchTasks(.taskVersions([versionID]), query: nil, queue: queue, completion: makeNonOptionalResultClosure(completion))
    }
    
    func addTask(_ task: Task, queue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        addTasks([task], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func updateTask(_ task: Task, queue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        updateTasks([task], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func deleteTask(_ task: Task, queue: DispatchQueue = .main, completion: OCKResultClosure<Task>? = nil) {
        deleteTasks([task], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    // MARK: Outcomes
    
    func fetchOutcome(_ anchor: OCKOutcomeAnchor?, query: OCKOutcomeQuery?,
                      queue: DispatchQueue = .main, completion: @escaping OCKResultClosure<Outcome?>) {
        fetchOutcomes(anchor, query: query, queue: queue, completion: { completion($0.map { $0.first }) })
    }
    
    func addOutcome(_ outcome: Outcome, queue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        addOutcomes([outcome], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func updateOutcome(_ outcome: Outcome, queue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        updateOutcomes([outcome], queue: queue, completion: makePluralResultClosure(completion))
    }
    
    func deleteOutcome(_ outcome: Outcome, queue: DispatchQueue = .main, completion: OCKResultClosure<Outcome>? = nil) {
        deleteOutcomes([outcome], queue: queue, completion: makePluralResultClosure(completion))
    }
}

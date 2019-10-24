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

@testable import CareKitStore
import Foundation

struct MockPatient: OCKPatientConvertible, Equatable {
    static var count = 0
    var identifier: String
    var versionID: OCKLocalVersionID?
    var effectiveDate = Date()
    var name: String?
    var deletedDate: Date?

    init() {
        identifier = "\(MockPatient.count)"
        versionID = nil
        MockPatient.count += 1
    }

    init(_ value: OCKPatient) {
        self = MockPatient()
    }

    func convert() -> OCKPatient {
        var patient = OCKPatient(identifier: identifier, givenName: "Bergermeister", familyName: "Meisterberger")
        patient.versionID = versionID
        return patient
    }
}

struct MockPlan: OCKCarePlanConvertible, Equatable {
    static var count = 0
    var identifier: String
    var versionID: OCKLocalVersionID?
    var patientID: OCKLocalVersionID?
    var effectiveDate = Date()
    var name: String?
    var deletedDate: Date?

    init() {
        identifier = "\(MockPlan.count)"
        versionID = nil
        patientID = nil
        MockPlan.count += 1
    }

    init(_ value: OCKCarePlan) {
        self = MockPlan()
    }

    func convert() -> OCKCarePlan {
        var plan = OCKCarePlan(identifier: identifier, title: "MockCarePlan", patientID: patientID ?? OCKLocalVersionID("\(MockPatient.count)"))
        plan.versionID = versionID ?? OCKLocalVersionID("abc123")
        return plan
    }
}

struct MockContact: OCKContactConvertible, Equatable {
    static var count = 0
    var identifier: String
    var versionID: OCKLocalVersionID?
    var effectiveDate = Date()
    var planID: OCKLocalVersionID?
    var name: String?
    var deletedDate: Date?

    init() {
        identifier = "\(MockContact.count)"
        versionID = nil
        planID = nil
        MockContact.count += 1
    }

    init(_ value: OCKContact) {
        self = MockContact()
    }

    func convert() -> OCKContact {
        var contact = OCKContact(identifier: "MockContact", givenName: "Mock", familyName: "Mock", carePlanID: nil)
        contact.versionID = versionID
        return contact
    }
}

struct MockTask: OCKTaskConvertible, Equatable {
    static var count = 0
    var identifier: String
    var versionID: OCKLocalVersionID?
    var effectiveDate = Date()
    var carePlanID: OCKLocalVersionID?
    var title: String?
    var deletedDate: Date?

    init() {
        identifier = "\(MockTask.count)"
        versionID = nil
        MockTask.count += 1
    }

    init(_ value: OCKTask) {
        self = MockTask()
    }

    func convert() -> OCKTask {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        var task = OCKTask(identifier: identifier, title: "Meals",
                           carePlanID: carePlanID ?? OCKLocalVersionID("\(MockPatient.count)"), schedule: schedule)
        task.versionID = versionID
        return task
    }
}

struct MockOutcome: OCKOutcomeConvertible, Equatable {
    static var count = 0
    var identifier: String
    var localDatabaseID: OCKLocalVersionID?
    var taskID: OCKLocalVersionID?
    var value: String?

    init() {
        identifier = "\(MockOutcome.count)"
        localDatabaseID = OCKLocalVersionID("versionID: \(MockOutcome.count)")
        MockOutcome.count += 1
    }

    init(_ value: OCKOutcome) {
        self = MockOutcome()
    }

    func convert() -> OCKOutcome {
        return OCKOutcome(taskID: taskID ?? OCKLocalVersionID("\(MockTask.count)"), taskOccurenceIndex: 0, values: [])
    }
}

struct MockConfiguration: Equatable {}

final class MockStore: OCKStoreProtocol {
    static func == (lhs: MockStore, rhs: MockStore) -> Bool {
        return true
    }

    typealias Patient = MockPatient
    typealias Plan = MockPlan
    typealias Contact = MockContact
    typealias Task = MockTask
    typealias Outcome = MockOutcome

    weak var delegate: OCKStoreDelegate?

    var patients = [MockPatient]()
    var plans = [MockPlan]()
    var contacts = [MockContact]()
    var tasks = [MockTask]()
    var outcomes = [MockOutcome]()
    var adherence = [1.0, 2.0, 3.0]

    var numberOfTimesPatientsWereFetched = 0
    var numberOfTimesCarePlansWereFetched = 0
    var numberOfTimesContactsWereFetched = 0
    var numberOfTimesTasksWereFetched = 0
    var numberOfTimesOutcomesWereFetched = 0

    var numberOfTimesPatientsWereUpdated = 0
    var numberOfTimesCarePlansWereUpdated = 0
    var numberOfTimesContactsWereUpdated = 0
    var numberOfTimesTasksWereUpdated = 0
    var numberOfTimesOutcomesWereUpdated = 0

    // MARK: Patients

    func fetchPatients(_ anchor: OCKPatientAnchor?, query: OCKPatientQuery?, queue: DispatchQueue = .main,
                       completion: @escaping (Result<[MockPatient], OCKStoreError>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.numberOfTimesPatientsWereFetched += 1
            completion(.success(self.patients))
        }
    }

    func addPatients(_ patients: [MockPatient], queue: DispatchQueue = .main, completion: ((Result<[MockPatient], OCKStoreError>) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let newPatients = patients.map { patient -> MockPatient in
                var patient = patient
                patient.versionID = patient.versionID ?? OCKLocalVersionID(UUID().uuidString)
                return patient
            }
            self.patients.append(contentsOf: newPatients)
            self.delegate?.store(self, didAddPatients: newPatients)
            completion?(.success(newPatients))
        }
    }

    func updatePatients(_ patients: [MockPatient], queue: DispatchQueue = .main, completion: ((Result<[MockPatient], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            for patient in patients {
                if let index = self.patients.firstIndex(where: { $0.identifier == patient.identifier }) {
                    self.patients[index] = patient
                    self.numberOfTimesPatientsWereUpdated += 1
                }
            }
            completion?(.success(patients))
        }
    }

    func deletePatients(_ patients: [MockPatient], queue: DispatchQueue = .main, completion: ((Result<[MockPatient], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
        }
        self.patients = []
        completion?(.success(patients))
    }

    // MARK: Care Plans

    func fetchCarePlans(_ anchor: OCKCarePlanAnchor?, query: OCKCarePlanQuery?, queue: DispatchQueue = .main,
                        completion: @escaping (Result<[MockPlan], OCKStoreError>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.numberOfTimesCarePlansWereFetched += 1
            completion(.success(self.plans))
        }
    }

    func addCarePlans(_ plans: [MockPlan], queue: DispatchQueue = .main,
                      completion: ((Result<[MockPlan], OCKStoreError>) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let plans = plans.map { plan -> MockPlan in
                var plan = plan
                plan.versionID = plan.versionID ?? OCKLocalVersionID(UUID().uuidString)
                return plan
            }
            self.plans.append(contentsOf: plans)
            completion?(.success(plans))
        }
    }

    func updateCarePlans(_ plans: [MockPlan], queue: DispatchQueue = .main, completion: ((Result<[MockPlan], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            for plan in plans {
                if let index = self.plans.firstIndex(where: { $0.identifier == plan.identifier }) {
                    self.plans[index] = plan
                    self.numberOfTimesCarePlansWereUpdated += 1
                }
            }
            completion?(.success(plans))
        }
    }

    func deleteCarePlans(_ plans: [MockPlan], queue: DispatchQueue = .main, completion: ((Result<[MockPlan], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.plans = []
            completion?(.success(plans))
        }
    }

    // MARK: Contacts

    func fetchContacts(_ anchor: OCKContactAnchor?, query: OCKContactQuery?, queue: DispatchQueue = .main,
                       completion: @escaping (Result<[MockContact], OCKStoreError>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.numberOfTimesContactsWereFetched += 1
            completion(.success(self.contacts))
        }
    }

    func addContacts(_ contacts: [MockContact], queue: DispatchQueue = .main, completion: ((Result<[MockContact], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.contacts.append(contentsOf: contacts)
            completion?(.success(contacts))
        }
    }

    func updateContacts(_ contacts: [MockContact], queue: DispatchQueue = .main, completion: ((Result<[MockContact], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            for contact in contacts {
                if let index = self.contacts.firstIndex(where: { $0.identifier == contact.identifier }) {
                    self.contacts[index] = contact
                    self.numberOfTimesContactsWereUpdated += 1
                }
            }
            completion?(.success(contacts))
        }
    }

    func deleteContacts(_ contacts: [MockContact], queue: DispatchQueue = .main, completion: ((Result<[MockContact], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.contacts = []
            completion?(.success(contacts))
        }
    }

    // MARK: Tasks

    func fetchTasks(_ anchor: OCKTaskAnchor? = nil, query: OCKTaskQuery?, queue: DispatchQueue = .main,
                    completion: @escaping (Result<[MockTask], OCKStoreError>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.numberOfTimesTasksWereFetched += 1
            completion(.success(self.tasks))
        }
    }

    func addTasks(_ tasks: [MockTask], queue: DispatchQueue = .main, completion: ((Result<[MockTask], OCKStoreError>) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let tasks = tasks.map { task -> MockTask in
                var task = task
                task.versionID = task.versionID ?? OCKLocalVersionID(UUID().uuidString)
                return task
            }
            self.tasks.append(contentsOf: tasks)
            completion?(.success(tasks))
        }
    }

    func updateTasks(_ tasks: [MockTask], queue: DispatchQueue = .main, completion: ((Result<[MockTask], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            for task in tasks {
                if let index = tasks.firstIndex(where: { $0.identifier == task.identifier }) {
                    self.tasks[index] = task
                    self.numberOfTimesTasksWereUpdated += 1
                }
            }
            completion?(.success(tasks))
        }
    }

    func deleteTasks(_ tasks: [MockTask], queue: DispatchQueue = .main, completion: ((Result<[MockTask], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.tasks = []
            completion?(.success(tasks))
        }
    }

    // MARK: Outcomes

    func fetchOutcomes(_ anchor: OCKOutcomeAnchor?, query: OCKOutcomeQuery?, queue: DispatchQueue = .main,
                       completion: @escaping (Result<[MockOutcome], OCKStoreError>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.numberOfTimesOutcomesWereFetched += 1
            completion(.success(self.outcomes))
        }
    }

    func addOutcomes(_ outcomes: [MockOutcome], queue: DispatchQueue = .main,
                     completion: ((Result<[MockOutcome], OCKStoreError>) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            let outcomes = outcomes.map { outcome -> MockOutcome in
                var outcome = outcome
                outcome.localDatabaseID = outcome.localDatabaseID ?? OCKLocalVersionID(UUID().uuidString)
                return outcome
            }
            self.outcomes.append(contentsOf: outcomes)
            completion?(.success(outcomes))
        }
    }

    func updateOutcomes(_ outcomes: [MockOutcome], queue: DispatchQueue = .main, completion: ((Result<[MockOutcome], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            for outcome in outcomes {
                if let index = outcomes.firstIndex(where: { $0.identifier == outcome.identifier }) {
                    self.outcomes[index] = outcome
                    self.numberOfTimesOutcomesWereUpdated += 1
                }
            }
            completion?(.success(outcomes))
        }
    }

    func deleteOutcomes(_ outcomes: [MockOutcome], queue: DispatchQueue = .main, completion: ((Result<[MockOutcome], OCKStoreError>) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.outcomes = []
            completion?(.success(outcomes))
        }
    }

    func fetchAdherence(forTasks identifiers: [String]? = nil, query: OCKAdherenceQuery<Event>, queue: DispatchQueue = .main,
                        completion: @escaping OCKResultClosure<[Double]>) {
        DispatchQueue.global(qos: .background).async {
            completion(.success(self.adherence))
        }
    }
}

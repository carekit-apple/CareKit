/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
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
import Combine
import Foundation


/// An `OCKSynchronizedStoreManager` wraps any store that conforms to `OCKStore` and provides synchronization to CareKit view
/// controllers by listening in on the store's activity by setting itself as the store delegate.
@available(*, unavailable, message: "OCKSynchronizedStoreManager and its related types are no longer available as a mechanism to synchronize with the CareKit store. As a replacement, see the asynchronous streams available directly on a CareKit store. For example, to monitor changes to tasks, see `OCKStore.tasks(query:)`.")
open class OCKSynchronizedStoreManager:
OCKPatientStoreDelegate, OCKCarePlanStoreDelegate, OCKContactStoreDelegate, OCKTaskStoreDelegate, OCKOutcomeStoreDelegate, OCKResetDelegate {


    /// The underlying database.
    public let store: OCKAnyStoreProtocol

    internal lazy var subject = PassthroughSubject<OCKStoreNotification, Never>()
    public private(set) lazy var notificationPublisher = subject.share().eraseToAnyPublisher()

    /// Initialize by wrapping a store.
    ///
    /// - Parameters:
    ///   - store: Any object that conforms to `OCKStoreProtocol`.
    ///
    /// - SeeAlso: `OCKStore`
    public init(wrapping store: OCKAnyStoreProtocol) {
        self.store = store
    }

    // MARK: OCKStoreDelegate Patients

    open func patientStore(_ store: OCKAnyReadOnlyPatientStore, didAddPatients patients: [OCKAnyPatient]) {
        dispatchPatientNotifications(category: .add, patients: patients)
    }

    open func patientStore(_ store: OCKAnyReadOnlyPatientStore, didUpdatePatients patients: [OCKAnyPatient]) {
        dispatchPatientNotifications(category: .update, patients: patients)
    }

    open func patientStore(_ store: OCKAnyReadOnlyPatientStore, didDeletePatients patients: [OCKAnyPatient]) {
        dispatchPatientNotifications(category: .delete, patients: patients)
    }

    private func dispatchPatientNotifications(category: OCKStoreNotificationCategory, patients: [OCKAnyPatient]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            patients.forEach {
                let notifications = OCKPatientNotification(patient: $0, category: category, storeManager: self)
                self.subject.send(notifications)
            }
        }
    }

    // MARK: OCKStoreDelegate CarePlans

    open func carePlanStore(_ store: OCKAnyReadOnlyCarePlanStore, didAddCarePlans carePlans: [OCKAnyCarePlan]) {
        dispatchCarePlanNotifications(category: .add, plans: carePlans)
    }

    open func carePlanStore(_ store: OCKAnyReadOnlyCarePlanStore, didUpdateCarePlans carePlans: [OCKAnyCarePlan]) {
        dispatchCarePlanNotifications(category: .update, plans: carePlans)
    }

    open func carePlanStore(_ store: OCKAnyReadOnlyCarePlanStore, didDeleteCarePlans carePlans: [OCKAnyCarePlan]) {
        dispatchCarePlanNotifications(category: .delete, plans: carePlans)
    }

    private func dispatchCarePlanNotifications(category: OCKStoreNotificationCategory, plans: [OCKAnyCarePlan]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            plans.forEach {
                let notification = OCKCarePlanNotification(carePlan: $0, category: category, storeManager: self)
                self.subject.send(notification)
            }
        }
    }

    // MARK: OCKStoreDelegate Contacts

    open func contactStore(_ store: OCKAnyReadOnlyContactStore, didAddContacts contacts: [OCKAnyContact]) {
        dispatchContactNotifications(category: .add, contacts: contacts)
    }

    open func contactStore(_ store: OCKAnyReadOnlyContactStore, didUpdateContacts contacts: [OCKAnyContact]) {
        dispatchContactNotifications(category: .update, contacts: contacts)
    }

    open func contactStore(_ store: OCKAnyReadOnlyContactStore, didDeleteContacts contacts: [OCKAnyContact]) {
        dispatchContactNotifications(category: .delete, contacts: contacts)
    }

    private func dispatchContactNotifications(category: OCKStoreNotificationCategory, contacts: [OCKAnyContact]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            contacts.forEach {
                let notification = OCKContactNotification(contact: $0, category: category, storeManager: self)
                self.subject.send(notification)
            }
        }
    }

    // MARK: OCKStoreDelegate Tasks

    open func taskStore(_ store: OCKAnyReadOnlyTaskStore, didAddTasks tasks: [OCKAnyTask]) {
        dispatchTaskNotifications(category: .add, tasks: tasks)
    }

    open func taskStore(_ store: OCKAnyReadOnlyTaskStore, didUpdateTasks tasks: [OCKAnyTask]) {
        dispatchTaskNotifications(category: .update, tasks: tasks)
    }

    open func taskStore(_ store: OCKAnyReadOnlyTaskStore, didDeleteTasks tasks: [OCKAnyTask]) {
        dispatchTaskNotifications(category: .delete, tasks: tasks)
    }

    private func dispatchTaskNotifications(category: OCKStoreNotificationCategory, tasks: [OCKAnyTask]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tasks.forEach {
                let notification = OCKTaskNotification(task: $0, category: category, storeManager: self)
                self.subject.send(notification)
            }
        }
    }

    // MARK: OCKStoreDelegate Outcomes

    open func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, didAddOutcomes outcomes: [OCKAnyOutcome]) {
        dispatchOutcomeNotifications(category: .add, outcomes: outcomes)
    }

    open func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, didUpdateOutcomes outcomes: [OCKAnyOutcome]) {
        dispatchOutcomeNotifications(category: .update, outcomes: outcomes)
    }

    open func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, didDeleteOutcomes outcomes: [OCKAnyOutcome]) {
        dispatchOutcomeNotifications(category: .delete, outcomes: outcomes)
    }

    open func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, didEncounterUnknownChange change: String) {
        DispatchQueue.main.async { self.subject.send(OCKUnknownChangeNotification(.outcomes, change)) }
    }

    private func dispatchOutcomeNotifications(category: OCKStoreNotificationCategory, outcomes: [OCKAnyOutcome]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            outcomes.forEach {
                let notification = OCKOutcomeNotification(outcome: $0, category: category, storeManager: self)
                self.subject.send(notification)
            }
        }
    }

    // MARK: OCKResetDelegate

    open func storeDidReset(_ store: OCKAnyResettableStore) {
        DispatchQueue.main.async { [subject] in
            for entity in OCKUnknownChangeNotification.Entity.allCases {
                let notification = OCKUnknownChangeNotification(entity, "Reset")
                subject.send(notification)
            }
        }
    }
}

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

import CareKitStore
import Combine
import Foundation

/// An `OCKSynchronizedStoreManager` wraps any store that conforms to `OCKStore` and provides synchronization to CareKit view
/// controllers by listening in on the store's activity by setting itself as the store delegate.
open class OCKSynchronizedStoreManager<Store: OCKStoreProtocol>: Equatable, OCKStoreDelegate {
    public static func == (lhs: OCKSynchronizedStoreManager<Store>, rhs: OCKSynchronizedStoreManager<Store>) -> Bool {
        return lhs.store == rhs.store
    }

    /// The underlying database.
    public let store: Store

    internal lazy var subject = PassthroughSubject<OCKStoreNotification, Never>()
    internal private (set) lazy var notificationPublisher = subject.share()

    /// Initialize by wrapping a store.
    ///
    /// - Parameters:
    ///   - store: Any object that conforms to `OCKStoreProtocol`.
    ///
    /// - SeeAlso: `OCKStore`
    public init(wrapping store: Store) {
        self.store = store
        self.store.delegate = self
    }

    // MARK: OCKStoreDelegate Patients

    public func store<S>(_ store: S, didAddPatients patients: [S.Patient]) where S: OCKStoreProtocol {
        dispatchPatientNotifications(store: store, category: .add, patients: patients)
    }

    public func store<S>(_ store: S, didUpdatePatients patients: [S.Patient]) where S: OCKStoreProtocol {
        dispatchPatientNotifications(store: store, category: .update, patients: patients)
    }

    public func store<S>(_ store: S, didDeletePatients patients: [S.Patient]) where S: OCKStoreProtocol {
        dispatchPatientNotifications(store: store, category: .delete, patients: patients)
    }

    private func dispatchPatientNotifications<S: OCKStoreProtocol>(store: S, category: OCKStoreNotificationCategory, patients: [S.Patient]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for patient in patients.compactMap({ $0 as? Store.Patient }) {
                let notification = OCKPatientNotification<Store>(storeManager: self, patient: patient, category: category)
                self.subject.send(notification)
            }
        }
    }

    // MARK: OCKStoreDelegate CarePlans

    public func store<S>(_ store: S, didAddCarePlans carePlans: [S.Plan]) where S: OCKStoreProtocol {
        dispatchCarePlanNotifications(store: store, category: .add, plans: carePlans)
    }

    public func store<S>(_ store: S, didUpdateCarePlans carePlans: [S.Plan]) where S: OCKStoreProtocol {
        dispatchCarePlanNotifications(store: store, category: .update, plans: carePlans)
    }

    public func store<S>(_ store: S, didDeleteCarePlans carePlans: [S.Plan]) where S: OCKStoreProtocol {
        dispatchCarePlanNotifications(store: store, category: .delete, plans: carePlans)
    }

    private func dispatchCarePlanNotifications<S: OCKStoreProtocol>(store: S, category: OCKStoreNotificationCategory, plans: [S.Plan]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for plan in plans.compactMap({ $0 as? Store.Plan }) {
                let notification = OCKCarePlanNotification<Store>(storeManager: self, carePlan: plan, category: category)
                self.subject.send(notification)
            }
        }
    }

    // MARK: OCKStoreDelegate Contacts

    public func store<S>(_ store: S, didAddContacts contacts: [S.Contact]) where S: OCKStoreProtocol {
        dispatchContactNotifications(store: store, category: .add, contacts: contacts)
    }

    public func store<S>(_ store: S, didUpdateContacts contacts: [S.Contact]) where S: OCKStoreProtocol {
        dispatchContactNotifications(store: store, category: .update, contacts: contacts)
    }

    public func store<S>(_ store: S, didDeleteContacts contacts: [S.Contact]) where S: OCKStoreProtocol {
        dispatchContactNotifications(store: store, category: .delete, contacts: contacts)
    }

    private func dispatchContactNotifications<S: OCKStoreProtocol>(store: S, category: OCKStoreNotificationCategory, contacts: [S.Contact]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for contact in contacts.compactMap({ $0 as? Store.Contact }) {
                let notification = OCKContactNotification<Store>(storeManager: self, contact: contact, category: category)
                self.subject.send(notification)
            }
        }
    }

    // MARK: OCKStoreDelegate Tasks

    public func store<S>(_ store: S, didAddTasks tasks: [S.Task]) where S: OCKStoreProtocol {
        dispatchTaskNotifications(store: store, category: .add, tasks: tasks)
    }

    public func store<S>(_ store: S, didUpdateTasks tasks: [S.Task]) where S: OCKStoreProtocol {
        dispatchTaskNotifications(store: store, category: .update, tasks: tasks)
    }

    public func store<S>(_ store: S, didDeleteTasks tasks: [S.Task]) where S: OCKStoreProtocol {
        dispatchTaskNotifications(store: store, category: .delete, tasks: tasks)
    }

    private func dispatchTaskNotifications<S: OCKStoreProtocol>(store: S, category: OCKStoreNotificationCategory, tasks: [S.Task]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for task in tasks.compactMap({ $0 as? Store.Task }) {
                let notification = OCKTaskNotification<Store>(storeManager: self, task: task, category: category)
                self.subject.send(notification)
            }
        }
    }

    // MARK: OCKStoreDelegate Outcomes

    public func store<S>(_ store: S, didAddOutcomes outcomes: [S.Outcome]) where S: OCKStoreProtocol {
        dispatchOutcomeNotifications(store: store, category: .add, outcomes: outcomes)
    }

    public func store<S>(_ store: S, didUpdateOutcomes outcomes: [S.Outcome]) where S: OCKStoreProtocol {
        dispatchOutcomeNotifications(store: store, category: .update, outcomes: outcomes)
    }

    public func store<S>(_ store: S, didDeleteOutcomes outcomes: [S.Outcome]) where S: OCKStoreProtocol {
        dispatchOutcomeNotifications(store: store, category: .delete, outcomes: outcomes)
    }

    private func dispatchOutcomeNotifications<S: OCKStoreProtocol>(store: S, category: OCKStoreNotificationCategory, outcomes: [S.Outcome]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for outcome in outcomes.compactMap({ $0 as? Store.Outcome }) {
                let notification = OCKOutcomeNotification<Store>(storeManager: self, outcome: outcome, category: category)
                self.subject.send(notification)
            }
        }
    }
}

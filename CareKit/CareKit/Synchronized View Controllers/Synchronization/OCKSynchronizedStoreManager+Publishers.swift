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

extension OCKSynchronizedStoreManager {
    // MARK: Patients
    func publisher(forPatient patient: Store.Patient,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<Store.Patient, Never> {
        let presentValuePublisher = Future<Store.Patient, Never>({ completion in
            self.store.fetchPatient(withIdentifier: patient.identifier) { result in
                completion(.success((try? result.get()) ?? patient))
            }
        })

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKPatientNotification<Store> }
            .filter { $0.patient.isAssociated(with: patient) && categories.contains($0.category) }
            .map { $0.patient }
            .prepend(presentValuePublisher))
    }

    // MARK: CarePlans
    func publisher(forCarePlan plan: Store.Plan,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<Store.Plan, Never> {
        let presentValuePublisher = Future<Store.Plan, Never> { completion in
            self.store.fetchCarePlan(withIdentifier: plan.identifier) { result in
                completion(.success((try? result.get()) ?? plan))
            }
        }

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKCarePlanNotification<Store> }
            .filter { $0.carePlan.isAssociated(with: plan) && categories.contains($0.category) }
            .map { $0.carePlan }
            .prepend(presentValuePublisher))
    }

    // MARK: Contacts
    func contactsPublisher(categories: [OCKStoreNotificationCategory]) -> AnyPublisher<Store.Contact, Never> {
        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKContactNotification<Store> }
            .filter { categories.contains($0.category) }
            .map { $0.contact })
    }

    func publisher(forContact contact: Store.Contact,
                   categories: [OCKStoreNotificationCategory],
                   fetchImmediately: Bool = true) -> AnyPublisher<Store.Contact, Never> {
        let presentValuePublisher = Future<Store.Contact, Never>({ completion in
            self.store.fetchContact(withIdentifier: contact.identifier) { result in
                completion(.success((try? result.get()) ?? contact))
            }
        })

        let changePublisher = notificationPublisher
            .compactMap { $0 as? OCKContactNotification<Store> }
            .filter { $0.contact.isAssociated(with: contact) && categories.contains($0.category) }
            .map { $0.contact }

        return fetchImmediately ? AnyPublisher(changePublisher.prepend(presentValuePublisher)) : AnyPublisher(changePublisher)
    }

    // MARK: Tasks

    func publisher(forTask task: Store.Task, categories: [OCKStoreNotificationCategory],
                   fetchImmediately: Bool = true) -> AnyPublisher<Store.Task, Never> {
        let presentValuePublisher = Future<Store.Task, Never>({ completion in
            self.store.fetchTask(withIdentifier: task.identifier) { result in
                completion(.success((try? result.get()) ?? task))
            }
        })

        let publisher = notificationPublisher
            .compactMap { $0 as? OCKTaskNotification<Store> }
            .filter { $0.task.isAssociated(with: task) && categories.contains($0.category) }
            .map { $0.task }

        return fetchImmediately ? AnyPublisher(publisher.append(presentValuePublisher)) : AnyPublisher(publisher)
    }

    func publisher(forEventsBelongingToTask task: Store.Task,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<Store.Event, Never> {
        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification<Store> }
            .filter { self.taskIsParent(task, ofOurcome: $0.outcome) && categories.contains($0.category) }
            .map { self.makeEvent(task: task, outcome: $0.outcome, keepOutcome: $0.category != .delete) })
    }

    private func taskIsParent(_ task: Store.Task, ofOurcome outcome: Store.Outcome) -> Bool {
        guard let taskID = outcome.convert().taskID else { return false }
        return task.localDatabaseID == taskID
    }

    private func makeEvent(task: Store.Task, outcome: Store.Outcome, keepOutcome: Bool) -> Store.Event {
        guard let scheduleEvent = task.convert().schedule.event(forOccurenceIndex: outcome.convert().taskOccurenceIndex) else {
            fatalError("The outcome had an index of \(outcome.convert().taskOccurenceIndex), but the task's schedule doesn't have that many events.")
        }
        return Store.Event(task: task, outcome: keepOutcome ? outcome : nil, scheduleEvent: scheduleEvent)
    }

    // MARK: Events
    func publisher(forEvent event: Store.Event, categories: [OCKStoreNotificationCategory]) -> AnyPublisher<Store.Event, Never> {
        guard let taskID = event.task.localDatabaseID else {
            fatalError("Cannot create a publisher for an event with a task that has not been persisted.")
        }
        let presentValuePublisher = Future<Store.Event, Never>({ completion in
            self.store.fetchEvent(withTaskVersionID: taskID, occurenceIndex: event.scheduleEvent.occurence, queue: .main) { result in
                completion(.success((try? result.get()) ?? event))
            }
        })

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification<Store> }
            .filter { self.outcomeMatchesEvent(outcome: $0.outcome, event: event) }
            .map { self.makeEvent(task: event.task, outcome: $0.outcome, keepOutcome: $0.category != .delete) }
            .prepend(presentValuePublisher))
    }

    private func outcomeMatchesEvent(outcome: Store.Outcome, event: Store.Event) -> Bool {
        guard let taskID = outcome.convert().taskID else {
            fatalError("Notifications should always contain outcomes with non-nil local database IDs")
        }
        return event.task.localDatabaseID == taskID &&
            event.scheduleEvent.occurence == outcome.convert().taskOccurenceIndex
    }
}

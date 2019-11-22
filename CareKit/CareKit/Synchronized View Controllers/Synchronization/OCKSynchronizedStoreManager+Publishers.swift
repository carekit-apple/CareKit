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

    func publisher(forPatient patient: OCKAnyPatient,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyPatient, Never> {
        let presentValuePublisher = Future<OCKAnyPatient, Never>({ completion in
            self.store.fetchAnyPatient(withID: patient.id) { result in
                completion(.success((try? result.get()) ?? patient))
            }
        })

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKPatientNotification }
            .filter { $0.patient.id == patient.id && categories.contains($0.category) }
            .map { $0.patient }
            .prepend(presentValuePublisher))
    }

    // MARK: CarePlans

    func publisher(forCarePlan plan: OCKAnyCarePlan,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyCarePlan, Never> {
        let presentValuePublisher = Future<OCKAnyCarePlan, Never> { completion in
            self.store.fetchAnyCarePlan(withID: plan.id) { result in
                completion(.success((try? result.get()) ?? plan))
            }
        }

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKCarePlanNotification }
            .filter { $0.carePlan.id == plan.id && categories.contains($0.category) }
            .map { $0.carePlan }
            .prepend(presentValuePublisher))
    }

    // MARK: Contacts

    func contactsPublisher(categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyContact, Never> {
        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKContactNotification }
            .filter { categories.contains($0.category) }
            .map { $0.contact })
    }

    func publisher(forContactID id: String,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyContact, Never> {
        return notificationPublisher
            .compactMap { $0 as? OCKContactNotification }
            .filter { $0.contact.id == id && categories.contains($0.category) }
            .map { $0.contact }
            .eraseToAnyPublisher()
    }

    func publisher(forContact contact: OCKAnyContact,
                   categories: [OCKStoreNotificationCategory],
                   fetchImmediately: Bool = true) -> AnyPublisher<OCKAnyContact, Never> {
        let presentValuePublisher = Future<OCKAnyContact, Never>({ completion in
            self.store.fetchAnyContact(withID: contact.id) { result in
                completion(.success((try? result.get()) ?? contact))
            }
        })

        let changePublisher = notificationPublisher
            .compactMap { $0 as? OCKContactNotification }
            .filter { $0.contact.id == contact.id && categories.contains($0.category) }
            .map { $0.contact }

        return fetchImmediately ? AnyPublisher(changePublisher.prepend(presentValuePublisher)) : AnyPublisher(changePublisher)
    }

    // MARK: Tasks

    func publisher(forTask task: OCKAnyTask, categories: [OCKStoreNotificationCategory],
                   fetchImmediately: Bool = true) -> AnyPublisher<OCKAnyTask, Never> {
        let presentValuePublisher = Future<OCKAnyTask, Never>({ completion in
            self.store.fetchAnyTask(withID: task.id) { result in
                completion(.success((try? result.get()) ?? task))
            }
        })

        let publisher = notificationPublisher
            .compactMap { $0 as? OCKTaskNotification }
            .filter { $0.task.id == task.id && categories.contains($0.category) }
            .map { $0.task }

        return fetchImmediately ? AnyPublisher(publisher.append(presentValuePublisher)) : AnyPublisher(publisher)
    }

    func publisher(forEventsBelongingToTask task: OCKAnyTask,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyEvent, Never> {
        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification }
            .filter { $0.outcome.belongs(to: task) && categories.contains($0.category) }
            .map { self.makeEvent(task: task, outcome: $0.outcome, keepOutcome: $0.category != .delete) })
    }

    func publisher(forEventsBelongingToTask task: OCKAnyTask, query: OCKEventQuery,
                   categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyEvent, Never> {

        let validIndices = task.schedule.events(from: query.dateInterval.start, to: query.dateInterval.end)
            .map { $0.occurrence }

        return publisher(forEventsBelongingToTask: task, categories: categories)
            .filter { validIndices.contains($0.scheduleEvent.occurrence) }
            .eraseToAnyPublisher()
    }

    private func makeEvent(task: OCKAnyTask, outcome: OCKAnyOutcome, keepOutcome: Bool) -> OCKAnyEvent {
        guard let scheduleEvent = task.schedule.event(forOccurrenceIndex: outcome.taskOccurrenceIndex) else {
            fatalError("The outcome had an index of \(outcome.taskOccurrenceIndex), but the task's schedule doesn't have that many events.")
        }
        return OCKAnyEvent(task: task, outcome: keepOutcome ? outcome : nil, scheduleEvent: scheduleEvent)
    }

    // MARK: Events

    func publisher(forEvent event: OCKAnyEvent, categories: [OCKStoreNotificationCategory]) -> AnyPublisher<OCKAnyEvent, Never> {
        let presentValuePublisher = Future<OCKAnyEvent, Never>({ completion in
            self.store.fetchAnyEvent(forTask: event.task, occurrence: event.scheduleEvent.occurrence, callbackQueue: .main) { result in
                completion(.success((try? result.get()) ?? event))
            }
        })

        return AnyPublisher(notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification }
            .filter { self.outcomeMatchesEvent(outcome: $0.outcome, event: event) }
            .map { self.makeEvent(task: event.task, outcome: $0.outcome, keepOutcome: $0.category != .delete) }
            .prepend(presentValuePublisher))
    }

    private func outcomeMatchesEvent(outcome: OCKAnyOutcome, event: OCKAnyEvent) -> Bool {
        outcome.belongs(to: event.task) && event.scheduleEvent.occurrence == outcome.taskOccurrenceIndex
    }
}

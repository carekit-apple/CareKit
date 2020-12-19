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
import CareKitUI
import UIKit

public extension OCKTaskControllerProtocol {

    func setEvent(atIndexPath indexPath: IndexPath, isComplete: Bool, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        let event: OCKAnyEvent
        do {
            _ = try validatedViewModel()
            event = try validatedEvent(forIndexPath: indexPath)
        } catch {
            completion?(.failure(error))
            return
        }

        // If the event is complete, create an outcome with a `true` value
        if isComplete {
            do {
                let outcome = try makeOutcomeFor(event: event, withValues: [.init(true)])
                store.addAnyOutcome(outcome) { result in
                    switch result {
                    case .failure(let error): completion?(.failure(error))
                    case .success(let outcome): completion?(.success(outcome))
                    }
                }
            } catch {
                completion?(.failure(error))
            }

        // if the event is incomplete, delete the outcome
        } else {
            guard let outcome = event.outcome else { return }
            store.deleteAnyOutcome(outcome) { result in
                switch result {
                case .failure(let error): completion?(.failure(error))
                case .success(let outcome): completion?(.success(outcome))
                }
            }
        }
    }

    func appendOutcomeValue(withType underlyingType: OCKOutcomeValueUnderlyingType, at indexPath: IndexPath,
                            completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        let event: OCKAnyEvent
        do {
            _ = try validatedViewModel()
            event = try validatedEvent(forIndexPath: indexPath)
        } catch {
            completion?(.failure(error))
            return
        }

        let value = OCKOutcomeValue(underlyingType)

        // Update the outcome with the new value
        if var outcome = event.outcome {
            outcome.values.append(value)
            store.updateAnyOutcome(outcome, callbackQueue: .main) { result in
                completion?(result.mapError { $0 as Error })
            }

        // Else Save a new outcome if one does not exist
        } else {
            do {
                let outcome = try makeOutcomeFor(event: event, withValues: [value])
                store.addAnyOutcome(outcome, callbackQueue: .main) { result in
                    completion?(result.mapError { $0 as Error })
                }
            } catch {
                completion?(.failure(error))
            }
        }
    }

    func makeOutcomeFor(event: OCKAnyEvent, withValues values: [OCKOutcomeValue]) throws -> OCKAnyOutcome {
        guard
            let task = event.task as? OCKAnyVersionableTask,
            let taskID = task.uuid else { throw OCKTaskControllerError.cannotMakeOutcomeFor(event) }
        return OCKOutcome(taskUUID: taskID, taskOccurrenceIndex: event.scheduleEvent.occurrence, values: values)
    }

    func eventFor(indexPath: IndexPath) -> OCKAnyEvent? {
        return objectWillChange.value?.event(forIndexPath: indexPath)
    }

    func validatedViewModel() throws -> OCKTaskEvents {
        guard let taskEvents = objectWillChange.value else {
            throw OCKTaskControllerError.nilTaskEvent
        }
        return taskEvents
    }

    func validatedEvent(forIndexPath indexPath: IndexPath) throws -> OCKAnyEvent {
        guard let event = eventFor(indexPath: indexPath) else {
            throw OCKTaskControllerError.invalidIndexPath(indexPath)
        }
        return event
    }

    private func deleteOutcomeValue(at index: Int, for outcome: OCKAnyOutcome, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?) {
        // delete the whole outcome if there is only one outcome value remaining
        guard outcome.values.count > 1 else {
            store.deleteAnyOutcome(outcome, callbackQueue: .main) { result in
                completion?(result.mapError { $0 as Error })
            }
            return
        }

        // Else delete the value from the outcome
        var newOutcome = outcome
        newOutcome.values.remove(at: index)
        store.updateAnyOutcome(newOutcome, callbackQueue: .main) { result in
            completion?(result.mapError { $0 as Error })
        }
    }
    
    func initiateDeletionForOutcomeValue(atIndex index: Int, eventIndexPath: IndexPath,
                                         deletionCompletion: ((Result<OCKAnyOutcome, Error>) -> Void)?) throws -> UIAlertController {
        _ = try validatedViewModel()
        let event = try validatedEvent(forIndexPath: eventIndexPath)

        // Make sure there is an outcome value to delete
        guard
            let outcome = event.outcome,
            index < outcome.values.count else {
                throw OCKTaskControllerError.noOutcomeValueForEvent(event, index)
            }

        // Make an action sheet to delete the outcome value
        let actionSheet = UIAlertController(title: loc("LOG_ENTRY"), message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: loc("CANCEL"), style: .default, handler: nil)
        let delete = UIAlertAction(title: loc("DELETE"), style: .destructive) { [weak self] _ in
            self?.deleteOutcomeValue(at: index, for: outcome, completion: deletionCompletion)
        }
        [delete, cancel].forEach { actionSheet.addAction($0) }
        return actionSheet
    }

    func initiateDetailsViewController(forIndexPath indexPath: IndexPath) throws -> OCKDetailViewController {
        _ = try validatedViewModel()
        let task = try validatedEvent(forIndexPath: indexPath).task

        let detailViewController = OCKDetailViewController()
        detailViewController.detailView.titleLabel.text = task.title
        detailViewController.detailView.instructionsLabel.text = task.instructions
        return detailViewController
    }
}

enum OCKTaskControllerError: Error, LocalizedError {
    case nilTaskEvent
    case invalidIndexPath(_ indexPath: IndexPath)
    case noOutcomeValueForEvent(_ event: OCKAnyEvent, _ index: Int)
    case cannotMakeOutcomeFor(_ event: OCKAnyEvent)

    var errorDescription: String? {
        switch self {
        case .nilTaskEvent: return "Task events view model is nil"
        case let .noOutcomeValueForEvent(event, index): return "Event has no outcome value at index \(index): \(event)"
        case .invalidIndexPath(let indexPath): return "Invalid index path \(indexPath)"
        case .cannotMakeOutcomeFor(let event): return "Cannot make outcome for event: \(event)"
        }
    }
}

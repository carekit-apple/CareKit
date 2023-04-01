/*
 Copyright (c) 2020, Apple Inc. All rights reserved.

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
import Foundation
import os.log
import SwiftUI


extension OCKAnyEventStore {

    @available(iOS 15, *)
    @available(watchOS 8, *)
    func toggleBooleanOutcome(for event: OCKAnyEvent) async throws -> OCKAnyOutcome {
        return try await withCheckedThrowingContinuation { continuation in
            toggleBooleanOutcome(for: event, completion: continuation.resume)
        }
    }

    func toggleBooleanOutcome(
        for event: OCKAnyEvent,
        completion: @escaping OCKResultClosure<OCKAnyOutcome> = { _ in }
    ) {
        // Retrieve the event from the store so that
        // we modify the outcome for the data at the
        // source of truth.
        fetch(event: event) { result in
            switch result {

            case let .failure(error):
                error.log("Failed to fetch event while toggling event's boolean outcome")
                completion(.failure(error))

            case let .success(event):
                // Mark the event as incomplete
                if let outcome = event.outcome {
                    self.deleteAnyOutcome(outcome) { result in
                        result.error?.log("Failed to delete outcome while toggling event's boolean outcome")
                        completion(result)
                    }

                // Else mark the event as completed
                } else {
                    let outcome = OCKOutcome(
                        taskUUID: event.task.uuid,
                        taskOccurrenceIndex: event.scheduleEvent.occurrence,
                        values: [OCKOutcomeValue(true)]
                    )
                    self.addAnyOutcome(outcome) { result in
                        result.error?.log("Failed add an outcome while toggling event's boolean outcome")
                        completion(result)
                    }
                }
            }
        }
    }

    func append(
        outcomeValue: OCKOutcomeValueUnderlyingType,
        event: OCKAnyEvent,
        completion: @escaping OCKResultClosure<OCKAnyOutcome> = { _ in }
    ) {
        // Retrieve the event from the store so that
        // we modify the outcome for the data at the
        // source of truth.
        fetch(event: event) { result in
            switch result {

            case let .failure(error):
                error.log("Failed to fetch event while appending outcome value to event")
                completion(.failure(error))

            case let .success(event):

                // If an outcome exists, append the new outcome value
                if var outcome = event.outcome {
                    outcome.values.append(OCKOutcomeValue(outcomeValue))
                    self.updateAnyOutcome(outcome, callbackQueue: .main) { result in
                        result.error?.log("Failed to update outcome while appending outcome value to event")
                        completion(result)
                    }

                // Else if one does not exist, save a new outcome
                } else {
                    let outcome = OCKOutcome(
                        taskUUID: event.task.uuid,
                        taskOccurrenceIndex: event.scheduleEvent.occurrence,
                        values: [OCKOutcomeValue(outcomeValue)]
                    )
                    self.addAnyOutcome(outcome, callbackQueue: .main) { result in
                        result.error?.log("Failed to update outcome while appending outcome value to event")
                        completion(result)
                    }
                }
            }
        }
    }

    func deleteOutcomeValue(
        at index: Int,
        event: OCKAnyEvent,
        completion: @escaping OCKResultClosure<OCKAnyOutcome> = { _ in }
    ) {
        // Retrieve the event from the store so that
        // we modify the outcome for the data at the
        // source of truth.
        fetch(event: event) { result in
            switch result {

            case let .failure(error):
                error.log("Failed to fetch event while deleting outcome value for event")
                completion(.failure(error))

            case let .success(event):

                // Make sure there is an outcome value to delete
                guard let outcome = event.outcome else {
                    log(.error, "No outcome found for event.")
                    completion(.failure(.deleteFailed(reason: "No outcome found for event.")))
                    return
                }

                // Delete the whole outcome if there is only one outcome value remaining
                if outcome.values.count > 1 {
                    self.deleteAnyOutcome(outcome, callbackQueue: .main) { result in
                        result.error?.log("Failed to delete outcome while deleting outcome value for event")
                        completion(result)
                    }
                // Else delete the outcome value from the outcome
                } else {
                    var newOutcome = outcome
                    newOutcome.values.remove(at: index)
                    self.updateAnyOutcome(newOutcome, callbackQueue: .main) { result in
                        result.error?.log("Failed to update outcome while deleting outcome value for event")
                        completion(result)
                    }
                }
            }
        }
    }

    private func fetch(
        event: OCKAnyEvent,
        completion: @escaping OCKResultClosure<OCKAnyEvent> = { _ in }
    ) {
        fetchAnyEvent(
            forTask: event.task,
            occurrence: event.scheduleEvent.occurrence,
            callbackQueue: .main
        ) { result in
            switch result {
            case let .failure(error):
                error.log("Failed to fetch event")
                completion(.failure(error))
            case let .success(event):
                completion(.success(event))
            }
        }
    }
}

private extension Result {

    var error: Error? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }
}

private extension Error {

    func log(_ message: StaticString) {
        CareKit.log(.error, message, error: self)
    }
}

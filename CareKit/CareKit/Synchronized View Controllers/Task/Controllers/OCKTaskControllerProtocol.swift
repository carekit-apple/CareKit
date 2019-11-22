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
import UIKit

/// Describes an object capable of tracking and updating the state of a task.
public protocol OCKTaskControllerProtocol: AnyObject {

    /// A reference to a writable store.
    var store: OCKAnyOutcomeStore { get }

    /// A publisher that publishers new values when the watched task changes in the store.
    var objectWillChange: CurrentValueSubject<OCKTaskEvents?, Never> { get }

    // MARK: Implementation Provided

    /// Create a detail view that dispays information about a task.
    /// - Parameter indexPath: Index path of the event whose task should be displayed.
    func initiateDetailsViewController(forIndexPath indexPath: IndexPath) throws -> OCKDetailViewController

    /// Set the completion state for an event.
    /// - Parameters:
    ///   - indexPath: Index path of the event.
    ///   - isComplete: True if the event is complete.
    ///   - completion: Result after etting the completion for the event.
    func setEvent(atIndexPath indexPath: IndexPath, isComplete: Bool, completion: ((Result<OCKAnyOutcome, Error>) -> Void)?)

    /// Append an outcome value to an event's outcome.
    /// - Parameters:
    ///   - underlyingType: The value for the outcome value that is being created.
    ///   - indexPath: Index path of the event to which the outcome will be added.
    ///   - completion: Result after creating the outcome value.
    func appendOutcomeValue(withType underlyingType: OCKOutcomeValueUnderlyingType, at indexPath: IndexPath,
                            completion: ((Result<OCKAnyOutcome, Error>) -> Void)?)

    /// Create a view with an option to delete an outcome value.
    /// - Parameters:
    ///   - index: The index of the outcome value to delete.
    ///   - eventIndexPath: The index path of the event for which the outcome value will be deleted.
    ///   - deletionCompletion: The result from attempting to delete the outcome value.
    func initiateDeletionForOutcomeValue(atIndex index: Int, eventIndexPath: IndexPath,
                                         deletionCompletion: ((Result<OCKAnyOutcome, Error>) -> Void)?) throws -> UIAlertController

    /// Make an outcome for an event with the given outcome values.
    /// - Parameters:
    ///   - event: The event for which to create the outcome.
    ///   - values: The outcome values to attach to the outcome.
    func makeOutcomeFor(event: OCKAnyEvent, withValues values: [OCKOutcomeValue]) throws -> OCKAnyOutcome

    /// Return an event for a particular index path. Customize this method to define the indec path behavior used by other functions in this protocol.
    /// - Parameter indexPath: The index path used to locate a particular event.
    func eventFor(indexPath: IndexPath) -> OCKAnyEvent?
}

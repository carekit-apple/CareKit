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

public protocol OCKStoreCoordinatorDelegate: AnyObject, Sendable {

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func patientStore(_ store: OCKAnyReadOnlyPatientStore, shouldHandleQuery query: OCKPatientQuery) -> Bool

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - patient: The patient that needs to be written.
    func patientStore(_ store: OCKAnyPatientStore, shouldHandleWritingPatient patient: OCKAnyPatient) -> Bool

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func carePlanStore(_ store: OCKAnyReadOnlyCarePlanStore, shouldHandleQuery query: OCKCarePlanQuery) -> Bool

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - plan: The plan that needs to be written.
    func carePlanStore(_ store: OCKAnyCarePlanStore, shouldHandleWritingCarePlan plan: OCKAnyCarePlan) -> Bool

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func contactStore(_ store: OCKAnyReadOnlyContactStore, shouldHandleQuery query: OCKContactQuery) -> Bool

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - contact: The contact that needs to be written.
    func contactStore(_ store: OCKAnyReadOnlyContactStore, shouldHandleWritingContact contact: OCKAnyContact) -> Bool

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func taskStore(_ store: OCKAnyReadOnlyTaskStore, shouldHandleQuery query: OCKTaskQuery) -> Bool

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - task: The task that needs to be written.
    func taskStore(_ store: OCKAnyReadOnlyTaskStore, shouldHandleWritingTask task: OCKAnyTask) -> Bool

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, shouldHandleQuery query: OCKOutcomeQuery) -> Bool

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - outcome: The outcome that needs to be written.
    func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, shouldHandleWritingOutcome outcome: OCKAnyOutcome) -> Bool
}

public extension OCKStoreCoordinatorDelegate {

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func patientStore(_ store: OCKAnyReadOnlyPatientStore, shouldHandleQuery query: OCKPatientQuery) -> Bool {
        return true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - patient: The patient that needs to be written.
    func patientStore(_ store: OCKAnyPatientStore, shouldHandleWritingPatient patient: OCKAnyPatient) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func carePlanStore(_ store: OCKAnyReadOnlyCarePlanStore, shouldHandleQuery query: OCKCarePlanQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - plan: The plan that needs to be written.
    func carePlanStore(_ store: OCKAnyCarePlanStore, shouldHandleWritingCarePlan plan: OCKAnyCarePlan) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func contactStore(_ store: OCKAnyReadOnlyContactStore, shouldHandleQuery query: OCKContactQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - contact: The contact that needs to be written.
    func contactStore(_ store: OCKAnyReadOnlyContactStore, shouldHandleWritingContact contact: OCKAnyContact) -> Bool {
        return true
    }

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func taskStore(_ store: OCKAnyReadOnlyTaskStore, shouldHandleQuery query: OCKTaskQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - task: The task that needs to be written.
    func taskStore(_ store: OCKAnyReadOnlyTaskStore, shouldHandleWritingTask task: OCKAnyTask) -> Bool {

        #if os(iOS)
        if store is OCKHealthKitPassthroughStore && !(task is OCKHealthKitTask) { return false }
        if store is OCKStore && task is OCKHealthKitTask { return false }
        #endif

        return true
    }

    /// Determines whether or not a store is intended to handle a given query. If true is returned, the persistent store coordinator
    /// will execute the query against the store and include the result together with results from any other stores that also respond
    /// to this query.
    ///
    /// - Parameter store: A candidate store that should or should not handle the query.
    /// - Parameter query: The query that is about to be executed.
    func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, shouldHandleQuery query: OCKOutcomeQuery) -> Bool {
        true
    }

    /// Determines whether or not a store is intended to handle a certain write operation. The persistent store coordinator will call this method
    /// against all its stores in the order they were registered and execute the write on the first store that returns true for this method.
    ///
    /// - Parameters:
    ///   - store: A candidate store that should or should not handle writing.
    ///   - outcome: The outcome that needs to be written.
    func outcomeStore(_ store: OCKAnyReadOnlyOutcomeStore, shouldHandleWritingOutcome outcome: OCKAnyOutcome) -> Bool {

        #if os(iOS) || os(macOS)
        // Only the HK passthrough store should handle HK outcomes
        if outcome is OCKHealthKitOutcome || store is OCKHealthKitPassthroughStore {
            return store is OCKHealthKitPassthroughStore && outcome is OCKHealthKitOutcome
        }
        #endif
        return true
    }
}

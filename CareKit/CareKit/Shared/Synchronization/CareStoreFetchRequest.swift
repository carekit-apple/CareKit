/*
 Copyright (c) 2021, Apple Inc. All rights reserved.

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
import SwiftUI


/// A property wrapper useful for streaming data from a CareKit store.
///
/// The property wrapper offers a few initializers matching the different entities available in
/// the CareKit store. Each initializer requires a query that is used to locate the desired data.
///
///     @CareStoreFetchRequest(query: OCKTaskQuery())
///     private var tasks
///
/// CareKit stores the fetched results in the `wrappedValue` and will always stay up to date
/// with changes to the store.
///
/// The property wrapper also offers a binding to the query in the case it needs to be modified.
/// Modifying the query  triggers a new fetch request.
///
///     Button("Update Query") {
///         tasks.query = newQuery
///     }
///
/// Define the property wrapper on a `View` that contains the store in its environment.
/// You can inject the store through the environment like this:
///
///     ContentView()
///         .environment(\.careStore, store)
///
/// See the `OCKAnyStoreProtocol` and the `OCKStore` for more information about
/// creating a CareKit store.
///
/// You may need to update the query over time. For example, suppose you're using
/// the property wrapper to fetch and display tasks for "today." After midnight passes,
/// the notion of "today" changes and you need to fetch new results. To detect events such
/// as the passage of a day or a change of time zone, observe
/// [significant time change notifications](https://developer.apple.com/documentation/uikit/uiapplication/1623059-significanttimechangenotificatio).
///
/// ```swift
///     ContentView()
///         .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
///             tasks.query.dateInterval = Calendar.current.dateInterval(of: .day, for: Date())!
///     }
/// ```
///
/// If you prefer to update the query date at a very specific time interval, see [`TimelineView`](https://www.google.com/search?client=safari&rls=en&q=timelineview&ie=UTF-8&oe=UTF-8&safari_group=3).
@available(iOS 14, watchOS 7, *)
@propertyWrapper
public struct CareStoreFetchRequest<Result, Query>: DynamicProperty {


    /// Contains query information used to stream data from a CareKit store.
    public struct Configuration {

        /// The query that matches data in the store during a fetch request.
        public var query: Query
    }

    @StateObject
    private var controller: CareStoreFetchRequestController<Result, Query>

    @Environment(\.careStore)
    private var store

    /// A binding to the parameters used to fetch data from the CareKit store. Modifying
    /// the parameters execute a new fetch request.
    ///
    /// Here's an example for fetching tasks from a store:
    ///
    ///     @CareStoreFetchRequest(query: OCKTaskQuery())
    ///     private var tasks
    ///
    /// You can change the configuration dynamically:
    ///
    ///     Button("Update Query") {
    ///         tasks.query = newQuery
    ///     }
    public var projectedValue: Binding<Configuration> {
        Binding(
            get: { Configuration(query: controller.query) },
            set: { controller.update(query: $0.query) }
        )
    }

    /// The result fetched from the CareKit store.
    ///
    /// The result synchronizes with changes in the store.
    public var wrappedValue: CareStoreFetchedResults<Result, Query> {
        return controller.fetchedResults
    }

    private init(
        controller: @autoclosure @escaping () -> CareStoreFetchRequestController<Result, Query>
    ) {
        self._controller = StateObject(wrappedValue: controller())
    }

    public func update() {
        controller.streamResults(from: store)
    }
}

// MARK: - Fetching Store Entities

@available(iOS 14, watchOS 7, *)
public extension CareStoreFetchRequest where
    Result == OCKAnyTask,
    Query == OCKTaskQuery
{
    /// Creates a fetch request for task data in a store that matches the provided
    /// query.
    ///
    /// The result synchronizes with changes in the store.
    /// - Parameters:
    ///   - query: The query that matches data in the store during a fetch request.
    init(query: OCKTaskQuery) {

        self.init(
            query: query,
            getID: \.id,
            getResults: { query, store in
                return store.anyTasks(matching: query)
            }
        )
    }
}

@available(iOS 14, watchOS 7, *)
public extension CareStoreFetchRequest where
    Result == OCKAnyEvent,
    Query == OCKEventQuery
{
    /// Creates a fetch request for event data in a store that matches the provided
    /// query.
    ///
    /// The result synchronizes with changes in the store.
    /// - Parameters:
    ///   - query: The query that matches data in the store during a fetch request.
    init(query: OCKEventQuery) {

        self.init(
            query: query,
            getID: \.id,
            getResults: { query, store in
                return store.anyEvents(matching: query)
            }
        )
    }
}

@available(iOS 14, watchOS 7, *)
public extension CareStoreFetchRequest where
    Result == OCKAnyOutcome,
    Query == OCKOutcomeQuery
{
    /// Creates a fetch request for outcome data in a store that matches the provided
    /// query.
    ///
    /// The result synchronizes with changes in the store.
    /// - Parameters:
    ///   - query: The query that matches data in the store during a fetch request.
    init(query: OCKOutcomeQuery) {

        self.init(
            query: query,
            getID: \.id,
            getResults: { query, store in
                return store.anyOutcomes(matching: query)
            }
        )
    }
}

@available(iOS 14, watchOS 7, *)
public extension CareStoreFetchRequest where
    Result == OCKAnyContact,
    Query == OCKContactQuery
{
    /// Creates a fetch request for contact data in a store that matches the provided
    /// query.
    ///
    /// The result synchronizes with changes in the store.
    /// - Parameters:
    ///   - query: The query that matches data in the store during a fetch request.
    init(query: OCKContactQuery) {

        self.init(
            query: query,
            getID: \.id,
            getResults: { query, store in
                return store.anyContacts(matching: query)
            }
        )
    }
}

@available(iOS 14, watchOS 7, *)
public extension CareStoreFetchRequest where
    Result == OCKAnyPatient,
    Query == OCKPatientQuery
{
    /// Creates a fetch request for patient data in a store that matches the provided
    /// query.
    ///
    /// The result synchronizes with changes in the store.
    /// - Parameters:
    ///   - query: The query that matches data in the store during a fetch request.
    init(query: OCKPatientQuery) {

        self.init(
            query: query,
            getID: \.id,
            getResults: { query, store in
                return store.anyPatients(matching: query)
            }
        )
    }
}

@available(iOS 14, watchOS 7, *)
public extension CareStoreFetchRequest where
    Result == OCKAnyCarePlan,
    Query == OCKCarePlanQuery
{
    /// Creates a fetch request for care plan data in a store that matches the provided
    /// query.
    ///
    /// The result synchronizes with changes in the store.
    /// - Parameters:
    ///   - query: The query that matches data in the store during a fetch request.
    init(query: OCKCarePlanQuery) {

        self.init(
            query: query,
            getID: \.id,
            getResults: { query, store in
                return store.anyCarePlans(matching: query)
            }
        )
    }
}

@available(iOS 14, watchOS 7, *)
private extension CareStoreFetchRequest where Query: Equatable {

    init(
        query: Query,
        getID: @escaping (Result) -> String,
        getResults: @escaping CareStoreFetchRequestController<Result, Query>.ComputeResults
    ) {
        self.init(
            controller: CareStoreFetchRequestController(
                query: query,
                getID: getID,
                getResults: getResults
            )
        )
    }
}

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

import Foundation

/// Classes that conform to this protocol can receive callbacks from a store when its contents change.
/// The `OCKSynchronizedStoreManager` in `CareKit` makes use of this to alert views to updates.
public protocol OCKStoreDelegate: AnyObject {
    /// Called each time patients are added into the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter patients: The patients that were added.
    func store<S: OCKStoreProtocol>(_ store: S, didAddPatients patients: [S.Patient])

    /// Called each time patients are updated the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter patients: The patients that were updated.
    func store<S: OCKStoreProtocol>(_ store: S, didUpdatePatients patients: [S.Patient])

    /// Called each time patients are deleted from the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter patients: The patients that were deleted.
    func store<S: OCKStoreProtocol>(_ store: S, didDeletePatients patients: [S.Patient])

    /// Called each time care plans are added to the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter carePlans: The care plans that were added.
    func store<S: OCKStoreProtocol>(_ store: S, didAddCarePlans carePlans: [S.Plan])

    /// Called each time care plans are updated in the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter carePlans: The care plans that were updated.
    func store<S: OCKStoreProtocol>(_ store: S, didUpdateCarePlans carePlans: [S.Plan])

    /// Called each time care plans are deleted from the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter carePlans: The care plans that were deleted.
    func store<S: OCKStoreProtocol>(_ store: S, didDeleteCarePlans carePlans: [S.Plan])

    /// Called each time contacts are added to the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter contacts: The contacts that were added to the store.
    func store<S: OCKStoreProtocol>(_ store: S, didAddContacts contacts: [S.Contact])

    /// Called each time contacts are updated in the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter contacts: The contacts that were updated in the store.
    func store<S: OCKStoreProtocol>(_ store: S, didUpdateContacts contacts: [S.Contact])

    /// Called each time contacts are deleted from the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter contacts: The contacts that were deleted from the store.
    func store<S: OCKStoreProtocol>(_ store: S, didDeleteContacts contacts: [S.Contact])

    /// Called each time tasks are added to the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter tasks: The tasks that were added to the store.
    func store<S: OCKStoreProtocol>(_ store: S, didAddTasks tasks: [S.Task])

    /// Called each time tasks are updated in the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter tasks: The tasks that were updated in the store.
    func store<S: OCKStoreProtocol>(_ store: S, didUpdateTasks tasks: [S.Task])

    /// Called each time tasks are deleted from the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter tasks: The tasks that were deleted from the store.
    func store<S: OCKStoreProtocol>(_ store: S, didDeleteTasks tasks: [S.Task])

    /// Called each time outcomes are added to the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter outcomes: The outcomes that were added to the store.
    func store<S: OCKStoreProtocol>(_ store: S, didAddOutcomes outcomes: [S.Outcome])

    /// Called each time outcomes are updated in the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter outcomes: The outcomes that were updated in the store.
    func store<S: OCKStoreProtocol>(_ store: S, didUpdateOutcomes outcomes: [S.Outcome])

    /// Called each time outcomes are added to the store.
    /// - Parameter store: The store which was modified.
    /// - Parameter outcomes: The outcomes that were deleted from the store.
    func store<S: OCKStoreProtocol>(_ store: S, didDeleteOutcomes outcomes: [S.Outcome])
}

/// CareKit can support any store that conforms to this protocol. The `OCKStore` class included in CareKit is a CoreData store that the implements
/// `OCKStoreProtocol` to provide on device storage. Support for other databases such as JSON files, REST API's, websockets, and 3rd part databases
/// can be added by conforming them to `OCKStoreProtocol`.
///
/// Alternative stores may use the same types as `OCKStore`, or they may use their own types. If a conformer defines its own associated types instead
/// of using the types natively supported by CareKit, it is required that they be both initializable from, and convertible to their CareKit
/// counterparts. The associated type `Configuration` is intended to use to for passing implementation specific information. For example, when tying
/// into a web API, authentication information may be passed in through configuration arguments.
///
/// `OCKStoreProtocol` requires that a minimum level of functionality be provided, and then provides enhanced functionality via protocol extensions.
/// The methods provided by protocol extensions are naive implementations and are not efficient. Developers may wish to use the customization points
/// on `OCKStoreProtocol` to provide more efficient implementations that take advantage of the underlying database's native features.
///
/// - Remark: All methods defined in this protocol are required to be implemented as batch operations and should function as transactions.
/// If any one operation should fail, the state of the store should be returned to the state it was in before the transaction began. For example,
/// if an attempt to save an array of 10 outcomes fails on the 6th outcome, the first successfully persisted 6 outcomes must be deleted to restore
/// the store to the state it was in prior to the transaction. It is also expected that all conformers call completion blocks on their own
/// background thread.
///
/// - Note: When non-standard associated types are used, they will be passed all the way to the view layer without being converted, fully
/// preserving their typing. They will only be converted to and from native CareKit values if and when they are created or displayed by CareKit view
/// controllers. Developers wishing to display properties not present on native CareKit values must implement new logic at the view layer.
public protocol OCKStoreProtocol: AnyObject, Equatable {
    associatedtype Patient: OCKPatientConvertible & Equatable
    associatedtype Plan: OCKCarePlanConvertible & Equatable
    associatedtype Contact: OCKContactConvertible & Equatable
    associatedtype Task: OCKTaskConvertible & Equatable
    associatedtype Outcome: OCKOutcomeConvertible & Equatable
    typealias Event = OCKEvent<Task, Outcome>

    /// If set, the delegate's callback methods will be called each time data in the store changes.
    var delegate: OCKStoreDelegate? { get set }

    // MARK: Fetching

    /// `fetchPatients` asynchronously retrieves an array of patients from the store.
    ///
    /// - Parameters:
    ///   - anchor: An enumerator specifying which property to query by.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchPatients(_ anchor: OCKPatientAnchor?, query: OCKPatientQuery?, queue: DispatchQueue,
                       completion: @escaping OCKResultClosure<[Patient]>)

    /// `fetchCarePlans` asynchronously retrieves an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - anchor: An enumerator specifying which property to query by.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchCarePlans(_ anchor: OCKCarePlanAnchor?, query: OCKCarePlanQuery?, queue: DispatchQueue,
                        completion: @escaping OCKResultClosure<[Plan]>)

    /// `fetchContacts` asynchronously retrieves an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - anchor: An enumerator specifying which property to query by.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchContacts(_ anchor: OCKContactAnchor?, query: OCKContactQuery?,
                       queue: DispatchQueue, completion: @escaping OCKResultClosure<[Contact]>)

    /// `fetchTasks` asynchronously retrieves an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - anchor: An enumerator specifying which property to query by.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchTasks(_ anchor: OCKTaskAnchor?, query: OCKTaskQuery?, queue: DispatchQueue, completion: @escaping OCKResultClosure<[Task]>)

    /// `fetchOutcomes` asynchronously retrieves an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - anchor: An enumerator specifying which property to query by.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchOutcomes(_ anchor: OCKOutcomeAnchor?, query: OCKOutcomeQuery?, queue: DispatchQueue,
                       completion: @escaping OCKResultClosure<[Outcome]>)

    // MARK: Adding

    /// `addPatients` asynchronously adds an array of patients to the store.
    ///
    /// - Parameters:
    ///   - patients: An array of patients to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addPatients(_ patients: [Patient], queue: DispatchQueue, completion: OCKResultClosure<[Patient]>?)

    /// `addCarePlans` asynchronously adds an array of care plans to the store.
    ///
    /// - Parameters:
    ///   - plans: An array of plans to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addCarePlans(_ plans: [Plan], queue: DispatchQueue, completion: OCKResultClosure<[Plan]>?)

    /// `addContacts` asynchronously adds an array of contacts to the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addContacts(_ contacts: [Contact], queue: DispatchQueue, completion: OCKResultClosure<[Contact]>?)

    /// `addTasks` asynchronously adds an array of tasks to the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addTasks(_ tasks: [Task], queue: DispatchQueue, completion: OCKResultClosure<[Task]>?)

    /// `addOutcomes` asynchronously adds an array of outcomes to the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addOutcomes(_ outcomes: [Outcome], queue: DispatchQueue, completion: OCKResultClosure<[Outcome]>?)

    // MARK: Updating

    /// `updatePatients` asynchronously updates an array of patients in the store.
    ///
    /// - Parameters:
    ///   - patients: An array of patients to be updated. The patients must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updatePatients(_ patients: [Patient], queue: DispatchQueue, completion: OCKResultClosure<[Patient]>?)

    /// `updateCarePlans` asynchronously updates an array of care plans in the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to be updated. The care plans must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updateCarePlans(_ plans: [Plan], queue: DispatchQueue, completion: OCKResultClosure<[Plan]>?)

    /// `updateContacts` asynchronously updates an array of contacts in the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be updated. The contacts must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updateContacts(_ contacts: [Contact], queue: DispatchQueue, completion: OCKResultClosure<[Contact]>?)

    /// `updateTasks` asynchronously updates an array of tasks in the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of tasks to be updated. The tasks must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updateTasks(_ tasks: [Task], queue: DispatchQueue, completion: OCKResultClosure<[Task]>?)

    /// `updateOutcomes` asynchronously updates an array of outcomes in the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of outcomes to be updated. The outcomes must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updateOutcomes(_ outcomes: [Outcome], queue: DispatchQueue, completion: OCKResultClosure<[Outcome]>?)

    // MARK: Deleting

    /// `deletePatients` asynchronously deletes an array of patients from the store.
    ///
    /// - Parameters:
    ///   - patients: An array of patients to be deleted. The patients must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deletePatients(_ patients: [Patient], queue: DispatchQueue, completion: OCKResultClosure<[Patient]>?)

    /// `deleteCarePlans` asynchronously deletes an array of care plans from the store.
    ///
    /// - Parameters:
    ///   - plans: An array of care plans to be deleted. The care plans must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deleteCarePlans(_ plans: [Plan], queue: DispatchQueue, completion: OCKResultClosure<[Plan]>?)

    /// `deleteContacts` asynchronously deletes an array of contacts from the store.
    ///
    /// - Parameters:
    ///   - contacts: An array of contacts to be deleted. The contacts must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deleteContacts(_ contacts: [Contact], queue: DispatchQueue, completion: OCKResultClosure<[Contact]>?)

    /// `deleteTasks` asynchronously deletes an array of tasks from the store.
    ///
    /// - Parameters:
    ///   - tasks: An array of tasks to be deleted. The tasks must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deleteTasks(_ tasks: [Task], queue: DispatchQueue, completion: OCKResultClosure<[Task]>?)

    /// `deleteOutcomes` asynchronously deletes an array of outcomes from the store.
    ///
    /// - Parameters:
    ///   - outcomes: An array of outcomes to be deleted. The outcomes must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deleteOutcomes(_ outcomes: [Outcome], queue: DispatchQueue, completion: OCKResultClosure<[Outcome]>?)

    // MARK: Implementation Provided
    /// All methods below here are customization points. Naive implementations are provided in a protocol extension, so implementing these methods
    /// is not required to fulfill the `OCKStoreProtocol`, but developers may wish to provide a different implementation that takes advantage of
    /// their database's native features to optimize performance.

    // MARK: Events

    /// `fetchEvent` asynchronously retrieves a single event from the store.
    ///
    /// - Parameters:
    ///   - taskVersionID: The local database ID of the task for which to fetch an event.
    ///   - occurenceIndex: The Nth event to retrieve.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchEvent(withTaskVersionID taskVersionID: OCKLocalVersionID, occurenceIndex: Int,
                    queue: DispatchQueue, completion: @escaping OCKResultClosure<OCKEvent<Task, Outcome>>)

    /// `fetchEvents` retrieves all the occurences of the speficied task in the interval specified by the provided query.
    ///
    /// - Parameters:
    ///   - taskIdentifier: A user-defined unique identifier for the task.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchEvents(taskIdentifier: String, query: OCKEventQuery, queue: DispatchQueue,
                     completion: @escaping OCKResultClosure<[OCKEvent<Task, Outcome>]>)

    /// `fetchAdherence` retrieves all the events and calculates the percent of tasks completed for every day between two dates.
    ///
    /// The way completion is computed depends on how many `expectedValues` a task has. If it has no expected values,
    /// then having an outcome with at least one value will count as complete. If a task has expected values, completion
    /// will be computed as ratio of the number of outcome values to the number of expected values.
    ///
    /// - Parameters:
    ///   - identifiers: An array of user-defined unique identifier specifying the tasks across which to compute adherence
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread. In the success case, it will contain an array with one value for each day.
    func fetchAdherence(forTasks identifiers: [String]?, query: OCKAdherenceQuery<Event>,
                        queue: DispatchQueue, completion: @escaping OCKResultClosure<[OCKAdherence]>)

    /// `fetchInsights` computes a metric for a given task between two dates using the provided closure.
    ///
    /// - Parameters:
    ///   - identifier: A user-defined unique identifier for the task.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchInsights(forTask identifier: String, query: OCKInsightQuery<Event>,
                       queue: DispatchQueue, completion: @escaping OCKResultClosure<[Double]>)

    // MARK: Singular Methods

    /// `fetchPatient` asynchronously fetches a single patient from the store using its user-defined identifier. If a patient with the specified
    /// identifier does not exist, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - identifier: A unique user-defined identifier
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchPatient(withIdentifier identifier: String, queue: DispatchQueue, completion: @escaping OCKResultClosure<Patient>)

    /// `addPatient` asynchronously adds a patient to the store.
    ///
    /// - Parameters:
    ///   - patient: A patient to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addPatient(_ patient: Patient, queue: DispatchQueue, completion: OCKResultClosure<Patient>?)

    /// `updatePatient` asynchronously updates a patient in the store.
    ///
    /// - Parameters:
    ///   - patient: Apatients to be updated. The patient must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updatePatient(_ patient: Patient, queue: DispatchQueue, completion: OCKResultClosure<Patient>?)

    /// `deletePatient` asynchronously deletes a patient from the store.
    ///
    /// - Parameters:
    ///   - patient: A patient to be deleted. The patient must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deletePatient(_ patient: Patient, queue: DispatchQueue, completion: OCKResultClosure<Patient>?)

    /// `fetchCarePlan` asynchronously retrieves a care plan from the store using its user-defined unique identifier. If a care plan with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - identifier: A unique user-defined identifier
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchCarePlan(withIdentifier identifier: String, queue: DispatchQueue, completion: @escaping OCKResultClosure<Plan>)

    /// `addCarePlan` asynchronously adds a care plans to the store.
    ///
    /// - Parameters:
    ///   - plan: A care plan to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addCarePlan(_ plan: Plan, queue: DispatchQueue, completion: OCKResultClosure<Plan>?)

    /// `updateCarePlan` asynchronously updates a care plan in the store.
    ///
    /// - Parameters:
    ///   - plan: A care plan to be updated. The care plan must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updateCarePlan(_ plan: Plan, queue: DispatchQueue, completion: OCKResultClosure<Plan>?)

    /// `deleteCarePlan` asynchronously deletes a care plan from the store.
    ///
    /// - Parameters:
    ///   - plan: A care plan to be deleted. The care plan must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deleteCarePlan(_ plan: Plan, queue: DispatchQueue, completion: OCKResultClosure<Plan>?)

    /// `fetchContact` asynchronously retrieves a contact from the store using its user-defined unique identifier. If a contact with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - identifier: A unique user-defined identifier.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchContact(withIdentifier identifier: String, queue: DispatchQueue, completion: @escaping OCKResultClosure<Contact>)

    /// `addContact` asynchronously adds a contact to the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addContact(_ contact: Contact, queue: DispatchQueue, completion: OCKResultClosure<Contact>?)

    /// `updateContact` asynchronously updates a contacts in the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be updated. The contact must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updateContact(_ contact: Contact, queue: DispatchQueue, completion: OCKResultClosure<Contact>?)

    /// `deleteContact` asynchronously deletes a contact from the store.
    ///
    /// - Parameters:
    ///   - contact: A contact to be deleted. The contact must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deleteContact(_ contact: Contact, queue: DispatchQueue, completion: OCKResultClosure<Contact>?)

    // MARK: Tasks

    /// `fetchTask` asynchronously retrieves an array of tasks from the store using its user-defined unique identifier. If a task with the
    /// specified identifier is not found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - identifier: A unique user-defined identifier
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchTask(withIdentifier identifier: String, queue: DispatchQueue, completion: @escaping OCKResultClosure<Task>)

    /// `fetchTask` asynchronously retrieves an array of tasks from the store using its versioned database identifier. If a task with the
    /// specified database identifier cannot be found, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - identifier: A unique user-defined identifier
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchTask(withVersionID versionID: OCKLocalVersionID, queue: DispatchQueue, completion: @escaping OCKResultClosure<Task>)

    /// `addTask` asynchronously adds a task to the store.
    ///
    /// - Parameters:
    ///   - task: A task to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addTask(_ task: Task, queue: DispatchQueue, completion: OCKResultClosure<Task>?)

    /// `updateTask` asynchronously updates a task in the store.
    ///
    /// - Parameters:
    ///   - contact: A task to be updated. The task must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updateTask(_ task: Task, queue: DispatchQueue, completion: OCKResultClosure<Task>?)

    /// `deleteTask` asynchronously deletes a task from the store.
    ///
    /// - Parameters:
    ///   - task: A task to be deleted. The task must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deleteTask(_ task: Task, queue: DispatchQueue, completion: OCKResultClosure<Task>?)

    // MARK: Outcomes

    /// `fetchOutcome` asynchronously retrieves a single outcome from the store. If more than one outcome matches the query, only the first
    /// will be returned. If no matching outcomes exist, the completion handler will be called with an error.
    ///
    /// - Parameters:
    ///   - anchor: An enumerator specifying which property to query by.
    ///   - query: A query used to constrain the values that will be fetched.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func fetchOutcome(_ anchor: OCKOutcomeAnchor?, query: OCKOutcomeQuery?, queue: DispatchQueue,
                      completion: @escaping OCKResultClosure<Outcome>)

    /// `addOutcome` asynchronously adds an outcome to the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be added to the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func addOutcome(_ outcome: Outcome, queue: DispatchQueue, completion: OCKResultClosure<Outcome>?)

    /// `updateOutcome` asynchronously updates an outcome in the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be updated. The outcome must already exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func updateOutcome(_ outcome: Outcome, queue: DispatchQueue, completion: OCKResultClosure<Outcome>?)

    /// `deleteOutcome` asynchronously deletes an outcome from the store.
    ///
    /// - Parameters:
    ///   - outcome: An outcome to be deleted. The outcome must exist in the store.
    ///   - queue: The queue that the completion closure should be called on. In most cases this should be the main queue.
    ///   - completion: A callback that will fire on a background thread.
    func deleteOutcome(_ outcome: Outcome, queue: DispatchQueue, completion: OCKResultClosure<Outcome>?)
}

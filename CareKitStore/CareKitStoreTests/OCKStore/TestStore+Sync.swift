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

@testable import CareKitStore
import XCTest

class TestStoreSync: XCTestCase {

    var dummy: DummyEndpoint!
    var peer: OCKLocalPeer!
    var remoteStore: OCKStore!
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        let remoteDummy = DummyEndpoint()
        remoteDummy.automaticallySynchronizes = false

        dummy = DummyEndpoint()
        remoteStore = OCKStore(name: "peer", type: .inMemory, remote: remoteDummy)
        peer = OCKLocalPeer(peerStore: remoteStore)
        store = OCKStore(name: "store", type: .inMemory, remote: peer)
    }

    override func tearDown() {
        super.tearDown()

        dummy = nil
        peer = nil
        remoteStore = nil
        store = nil
    }

    func testStoreSynchronizationSucceeds() {
        store = OCKStore(name: "test", type: .inMemory, remote: dummy)
        XCTAssertNoThrow(try store.syncAndWait())
        XCTAssert(dummy.timesPullWasCalled == 1)
        XCTAssert(dummy.timesPushWasCalled == 1)
    }

    func testStoreSynchronizationFails() {
        dummy.shouldSucceed = false
        store = OCKStore(name: "test", type: .inMemory, remote: dummy)
        XCTAssertThrowsError(try store.syncAndWait())
        XCTAssert(dummy.timesPullWasCalled == 1)
        XCTAssert(dummy.timesPushWasCalled == 0)
     }

    func testSuccessfulSynchronizationIncrementsKnowledgeVector() {
        store = OCKStore(name: "test", type: .inMemory, remote: dummy)
        XCTAssert(store.context.clockTime == 0)
        XCTAssertNoThrow(try store.syncAndWait())
        XCTAssert(store.context.clockTime == 1)
    }

    func testSyncCannotBeStartedIfSyncIsAlreadyRunning() {
        dummy.delay = 5.0
        let store = OCKStore(name: "test", type: .inMemory, remote: dummy)
        store.synchronize(completion: { _ in })
        XCTAssertThrowsError(try store.syncAndWait())
    }

    func testSyncCanBeStartedIfPreviousSyncHasCompleted() {
        let store = OCKStore(name: "test", type: .inMemory, remote: dummy)
        XCTAssertNoThrow(try store.syncAndWait())
        XCTAssertNoThrow(try store.syncAndWait())
    }

    func testNonConflictingSyncAcrossStores() throws {
        peer.automaticallySynchronizes = false

        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var taskA = OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule)
        var taskB = OCKTask(id: "B", title: "B", carePlanUUID: nil, schedule: schedule)
        taskA = try remoteStore.addTaskAndWait(taskA)
        taskB = try store.addTaskAndWait(taskB)

        let outcomeA = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskUUID: try taskB.getUUID(), taskOccurrenceIndex: 0, values: [])
        try remoteStore.addOutcomeAndWait(outcomeA)
        try store.addOutcomeAndWait(outcomeB)

        XCTAssertNoThrow(try store.syncAndWait())

        let localTasks = try store.fetchTasksAndWait()
        let localOutcomes = try store.fetchOutcomesAndWait()
        let remoteTasks = try remoteStore.fetchTasksAndWait()
        let remoteOutcomes = try remoteStore.fetchOutcomesAndWait()

        XCTAssert(localTasks == remoteTasks)
        XCTAssert(localOutcomes == remoteOutcomes)
        XCTAssert(localTasks.count == 2)
        XCTAssert(localOutcomes.count == 2)
    }

    func testKeepRemoteTaskWithFirstVersionOfTasks() throws {
        peer.automaticallySynchronizes = false
        peer.conflictPolicy = .keepRemote

        let morning = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.mealTimesEachDay(start: morning, end: nil)

        var taskA = OCKTask(id: "abc", title: "A", carePlanUUID: nil, schedule: schedule)
        taskA = try remoteStore.addTaskAndWait(taskA)

        var taskB = OCKTask(id: "abc", title: "B", carePlanUUID: nil, schedule: schedule)
        taskB = try store.addTaskAndWait(taskB)

        let outcomeA = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskUUID: try taskB.getUUID(), taskOccurrenceIndex: 0, values: [])
        try remoteStore.addOutcomeAndWait(outcomeA)
        try store.addOutcomeAndWait(outcomeB)

        XCTAssertNoThrow(try store.syncAndWait())

        let localTasks = try store.fetchTasksAndWait()
        let localOutcomes = try store.fetchOutcomesAndWait()
        let remoteTasks = try remoteStore.fetchTasksAndWait()
        let remoteOutcomes = try remoteStore.fetchOutcomesAndWait()

        XCTAssert(localTasks == remoteTasks)
        XCTAssert(localOutcomes == remoteOutcomes)
        XCTAssert(localOutcomes.count == 1)
    }

    func testKeepRemoteTaskReplacingEntireLocalVersionChain() throws {
        peer.automaticallySynchronizes = false
        peer.conflictPolicy = .keepRemote

        let morning = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.mealTimesEachDay(start: morning, end: nil)

        var taskA = OCKTask(id: "abc", title: "A", carePlanUUID: nil, schedule: schedule)
        taskA = try remoteStore.addTaskAndWait(taskA)

        var taskB = OCKTask(id: "abc", title: "B", carePlanUUID: nil, schedule: schedule)
        taskB = try store.addTaskAndWait(taskB)
        let taskC = OCKTask(id: "abc", title: "C", carePlanUUID: nil, schedule: schedule.offset(by: .init(day: 2)))
        try store.updateTaskAndWait(taskC)

        let outcomeA = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskUUID: try taskB.getUUID(), taskOccurrenceIndex: 0, values: [])
        try remoteStore.addOutcomeAndWait(outcomeA)
        try store.addOutcomeAndWait(outcomeB)

        XCTAssertNoThrow(try store.syncAndWait())

        let localTasks = try store.fetchTasksAndWait()
        let localOutcomes = try store.fetchOutcomesAndWait()
        let remoteTasks = try remoteStore.fetchTasksAndWait()
        let remoteOutcomes = try remoteStore.fetchOutcomesAndWait()

        XCTAssert(localTasks == remoteTasks)
        XCTAssert(localTasks.count == 1)
        XCTAssert(localTasks.first?.title == "A")
        XCTAssert(localOutcomes == remoteOutcomes)
        XCTAssert(localOutcomes.count == 1)
    }

    // device ---B---C (keep)
    // remote ---A
    func testKeepEntireLocalTaskVersionChain() throws {
        peer.automaticallySynchronizes = false
        peer.conflictPolicy = .keepDevice

        let morning = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.mealTimesEachDay(start: morning, end: nil)

        var taskA = OCKTask(id: "abc", title: "A", carePlanUUID: nil, schedule: schedule)
        taskA = try remoteStore.addTaskAndWait(taskA)

        var taskB = OCKTask(id: "abc", title: "B", carePlanUUID: nil, schedule: schedule)
        taskB = try store.addTaskAndWait(taskB)
        var taskC = OCKTask(id: "abc", title: "C", carePlanUUID: nil, schedule: schedule.offset(by: .init(day: 2)))
        taskC = try store.updateTaskAndWait(taskC)

        let outcomeA = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])
        let outcomeB = OCKOutcome(taskUUID: try taskB.getUUID(), taskOccurrenceIndex: 0, values: [])
        try remoteStore.addOutcomeAndWait(outcomeA)
        try store.addOutcomeAndWait(outcomeB)

        try store.syncAndWait()

        let localTasks = try store.fetchTasksAndWait()
        let localOutcomes = try store.fetchOutcomesAndWait()
        let remoteTasks = try remoteStore.fetchTasksAndWait()
        let remoteOutcomes = try remoteStore.fetchOutcomesAndWait()

        XCTAssert(localTasks == remoteTasks)
        XCTAssert(localTasks.count == 2)
        XCTAssert(Set(localTasks.map { $0.title }) == Set(["B", "C"]))
        XCTAssert(localOutcomes == remoteOutcomes)
        XCTAssert(localOutcomes.count == 1)
    }

    //    /--B--C (Keep Remote)
    // A--
    //    \__D (Overwrite Local)
    func testOverwritePartialLocalTaskVersionChain() throws {
        peer.automaticallySynchronizes = false
        peer.conflictPolicy = .keepRemote

        let morning = Calendar.current.startOfDay(for: Date())
        let schedule = OCKSchedule.mealTimesEachDay(start: morning, end: nil)

        var taskA = OCKTask(id: "abc", title: "A", carePlanUUID: nil, schedule: schedule)
        taskA = try remoteStore.addTaskAndWait(taskA)

        let outcomeA = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])
        try remoteStore.addOutcomeAndWait(outcomeA)

        try store.syncAndWait()
        var localTasks = try store.fetchTasksAndWait()
        var localOutcomes = try store.fetchOutcomesAndWait()
        var remoteTasks = try remoteStore.fetchTasksAndWait()
        var remoteOutcomes = try remoteStore.fetchOutcomesAndWait()
        XCTAssert(localTasks == remoteTasks)
        XCTAssert(localOutcomes == remoteOutcomes)

        var taskB = OCKTask(id: "abc", title: "B", carePlanUUID: nil, schedule: schedule.offset(by: .init(day: 1)))
        taskB = try remoteStore.updateTaskAndWait(taskB)
        var taskC = OCKTask(id: "abc", title: "C", carePlanUUID: nil, schedule: schedule.offset(by: .init(day: 2)))
        taskC = try remoteStore.updateTaskAndWait(taskC)

        var taskD = OCKTask(id: "abc", title: "D", carePlanUUID: nil, schedule: schedule.offset(by: .init(day: 1)))
        taskD = try store.updateTaskAndWait(taskD)
        let outcomeD = OCKOutcome(taskUUID: try taskD.getUUID(), taskOccurrenceIndex: 1, values: [])
        try store.addOutcomeAndWait(outcomeD)

        try store.syncAndWait()
        localTasks = try store.fetchTasksAndWait()
        localOutcomes = try store.fetchOutcomesAndWait()
        remoteTasks = try remoteStore.fetchTasksAndWait()
        remoteOutcomes = try remoteStore.fetchOutcomesAndWait()

        XCTAssert(localTasks == remoteTasks)
        XCTAssert(localTasks.count == 3)
        XCTAssert(Set(localTasks.map { $0.title }) == Set(["A", "B", "C"]))
        XCTAssert(localOutcomes == remoteOutcomes)
        XCTAssert(localOutcomes.count == 1)
    }

    func testTombstoningOutcomePushedToRemote() throws {
        let dummy = DummyEndpoint()
        let testStore = OCKStore(name: "test", type: .inMemory, remote: dummy)
        dummy.automaticallySynchronizes = false

        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try testStore.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = try task.getUUID()

        let outcome = try testStore.addOutcomeAndWait(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [OCKOutcomeValue("test")]))
        let outcomeUUID = try outcome.getUUID()
        XCTAssertNoThrow(try testStore.syncAndWait()) //Sync original outcome

        try testStore.deleteOutcomeAndWait(outcome)
        XCTAssertNoThrow(try testStore.syncAndWait()) //Sync tombstoned outcome
        let latestRevisions = dummy.revisionsPushedInLastSynch
        XCTAssert(latestRevisions.count == 2)

        let tombstonedOutcomes = latestRevisions.compactMap { entity -> OCKOutcome? in
            switch entity {
            case .outcome(let outcome):
                return outcome
            default:
                return nil
            }
        }
        XCTAssert(tombstonedOutcomes.count == 2)

        guard let tombstonedWithSameUUID = try tombstonedOutcomes.first(where: { try $0.getUUID() == outcomeUUID }) else {
            throw OCKStoreError.invalidValue(reason: "Filter doesn't contain UUID")
        }
        XCTAssert(tombstonedWithSameUUID.values.isEmpty)
        XCTAssert(tombstonedWithSameUUID.deletedDate != nil)

        guard let tombstonedWithDifferentUUID = try tombstonedOutcomes.first(where: { try $0.getUUID() != outcomeUUID }) else {
            throw OCKStoreError.invalidValue(reason: "Filter doesn't contain UUID")
        }
        XCTAssert(tombstonedWithDifferentUUID.values.count == 1)
        XCTAssert(tombstonedWithDifferentUUID.deletedDate != nil)
    }

    func testUpdateTaskVersionPushedToRemote() throws {
        let dummy = DummyEndpoint()
        let testStore = OCKStore(name: "test", type: .inMemory, remote: dummy)
        dummy.automaticallySynchronizes = false

        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = try testStore.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = try task.getUUID()

        XCTAssertNoThrow(try testStore.syncAndWait()) //Sync original outcome

        task.instructions = "Updated instructions"
        try testStore.updateTaskAndWait(task)
        XCTAssertNoThrow(try testStore.syncAndWait()) //Sync updated outcome

        let latestRevisions = dummy.revisionsPushedInLastSynch
        XCTAssert(latestRevisions.count == 2)

        let versionedTasks = latestRevisions.compactMap { entity -> OCKTask? in
            switch entity {
            case .task(let task):
                return task
            default:
                return nil
            }
        }
        XCTAssert(versionedTasks.count == 2)

        guard let previousVersionTask = try versionedTasks.first(where: { try $0.getUUID() == taskUUID }) else {
            throw OCKStoreError.invalidValue(reason: "Filter doesn't contain UUID")
        }

        guard let currentVersionTask = try versionedTasks.first(where: { try $0.getUUID() != taskUUID }) else {
            throw OCKStoreError.invalidValue(reason: "Filter doesn't contain UUID")
        }
        XCTAssert(previousVersionTask.instructions == nil)
        XCTAssert(try previousVersionTask.getNextVersionUUID() == currentVersionTask.getUUID())

        XCTAssert(currentVersionTask.instructions != nil)
        XCTAssert(try currentVersionTask.getPreviousVersionUUID() == taskUUID)
        XCTAssertThrowsError(try currentVersionTask.getNextVersionUUID())
    }
}

class DummyEndpoint: OCKRemoteSynchronizable {

    var automaticallySynchronizes = true
    var shouldSucceed = true
    var delay: TimeInterval = 0.0
    weak var delegate: OCKRemoteSynchronizationDelegate?

    private(set) var timesPullWasCalled = 0
    private(set) var timesPushWasCalled = 0
    private(set) var timesForcePushed = 0
    private(set) var uuid = UUID()
    private(set) var dummyKnowledgeVector: OCKRevisionRecord.KnowledgeVector?
    var revisionsPushedInLastSynch = [OCKEntity]()

    var conflictPolicy = OCKMergeConflictResolutionPolicy.keepRemote
    var revision = OCKRevisionRecord(entities: [], knowledgeVector: .init())

    func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord, @escaping (Error?) -> Void) -> Void,
        completion: @escaping (Error?) -> Void) {

        timesPullWasCalled += 1
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + delay) {
            if !self.shouldSucceed {
                completion(OCKStoreError.remoteSynchronizationFailed(reason: "Failed on purpose"))
                return
            }

            guard let dummyVector = self.dummyKnowledgeVector else {
                mergeRevision(self.revision, completion)
                return
            }
            self.revision = OCKRevisionRecord(entities: [], knowledgeVector: dummyVector)
            mergeRevision(self.revision, completion)
        }
    }

    func pushRevisions(
        deviceRevision: OCKRevisionRecord,
        overwriteRemote: Bool,
        completion: @escaping (Error?) -> Void) {

        timesPushWasCalled += 1
        timesForcePushed += overwriteRemote ? 1 : 0

        //Save latest revisions
        revisionsPushedInLastSynch.removeAll()
        revisionsPushedInLastSynch.append(contentsOf: deviceRevision.entities)

        //Update KnowledgeVector
        if dummyKnowledgeVector == nil {
            dummyKnowledgeVector = .init([uuid: 0])
        }
        dummyKnowledgeVector?.increment(clockFor: uuid)
        dummyKnowledgeVector?.merge(with: deviceRevision.knowledgeVector)

        completion(nil)
    }

    func chooseConflictResolutionPolicy(
        _ conflict: OCKMergeConflictDescription,
        completion: @escaping (OCKMergeConflictResolutionPolicy) -> Void) {
        completion(conflictPolicy)
    }

    func dummyRevision() -> OCKRevisionRecord {

        var patient = OCKPatient(id: "id1", givenName: "Amy", familyName: "Frost")
        patient.uuid = UUID()
        patient.createdDate = Date()
        patient.updatedDate = patient.createdDate

        var carePlan = OCKCarePlan(id: "diabetes_type_1", title: "Diabetes Care Plan", patientUUID: nil)
        carePlan.uuid = UUID()
        carePlan.createdDate = Date()
        carePlan.updatedDate = carePlan.createdDate

        var contact = OCKContact(id: "contact", givenName: "Amy", familyName: "Frost", carePlanUUID: nil)
        contact.uuid = UUID()
        contact.createdDate = Date()
        contact.updatedDate = contact.createdDate

        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(id: "a", title: "A", carePlanUUID: nil, schedule: schedule)
        task.uuid = UUID()
        task.createdDate = Date()
        task.updatedDate = task.createdDate

        var outcome = OCKOutcome(taskUUID: task.uuid!, taskOccurrenceIndex: 0, values: [])
        outcome.uuid = UUID()
        outcome.createdDate = Date()
        outcome.updatedDate = outcome.createdDate

        let entities: [OCKEntity] = [
            .patient(patient),
            .carePlan(carePlan),
            .contact(contact),
            .task(task),
            .outcome(outcome)
        ]

        let revision = OCKRevisionRecord(entities: entities, knowledgeVector: .init())
        return revision
    }
}

final class OCKLocalPeer: OCKRemoteSynchronizable {

    weak var delegate: OCKRemoteSynchronizationDelegate?
    let peerStore: OCKStore

    init(peerStore: OCKStore) {
        self.peerStore = peerStore
    }

    var conflictPolicy: OCKMergeConflictResolutionPolicy = .keepDevice
    var automaticallySynchronizes: Bool = true

    func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord, @escaping (Error?) -> Void) -> Void,
        completion: @escaping (Error?) -> Void) {

        let clock = knowledgeVector.clock(for: peerStore.context.clockID)
        let revision = peerStore.computeRevision(since: clock)
        mergeRevision(revision, completion)
    }

    func pushRevisions(
        deviceRevision: OCKRevisionRecord,
        overwriteRemote: Bool,
        completion: @escaping (Error?) -> Void) {

        peerStore.mergeRevision(deviceRevision, completion: completion)
    }

    func chooseConflictResolutionPolicy(
        _ conflict: OCKMergeConflictDescription,
        completion: @escaping (OCKMergeConflictResolutionPolicy) -> Void) {

        completion(conflictPolicy)
    }
}

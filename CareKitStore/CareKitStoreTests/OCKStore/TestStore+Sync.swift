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
        peer.store = store
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
        let testStore = OCKStore(name: "test", type: .inMemory, remote: dummy)
        dummy.automaticallySynchronizes = false
        
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try testStore.addTaskAndWait(OCKTask(id: "A", title: "A", carePlanUUID: nil, schedule: schedule))
        let taskUUID = try task.getUUID()

        let outcome = try testStore.addOutcomeAndWait(OCKOutcome(taskUUID: taskUUID, taskOccurrenceIndex: 0, values: [OCKOutcomeValue("test")]))
        XCTAssertNoThrow(try testStore.syncAndWait()) //Sync original outcome
        
        dummy.entitiesInPushRevision.removeAll(keepingCapacity: false)
        try testStore.deleteOutcomeAndWait(outcome)
        XCTAssertNoThrow(try testStore.syncAndWait()) //Sync tombstoned outcome
        XCTAssert(dummy.entitiesInPushRevision.count == 3)
        
        let tombstonedOutcomes = dummy.entitiesInPushRevision.compactMap{
            entity -> OCKOutcome? in
            switch entity{
            case .outcome(let outcome):
                return outcome
            default:
                return nil
            }
        }
        XCTAssert(tombstonedOutcomes.count == 2)
        
        let tombstonedWithSameUUID = tombstonedOutcomes.filter({$0.uuid == outcome.uuid}).first!
        XCTAssert(tombstonedWithSameUUID.values.isEmpty)
        XCTAssert(tombstonedWithSameUUID.deletedDate != nil)
        
        let tombstonedWithDifferentUUID = tombstonedOutcomes.filter({$0.uuid != outcome.uuid}).first!
        XCTAssert(tombstonedWithDifferentUUID.values.count == 1)
        XCTAssert(tombstonedWithDifferentUUID.deletedDate != nil)
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
    var entitiesInPushRevision = [OCKEntity]()

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
            mergeRevision(self.revision, completion)
        }
    }

    func pushRevisions(
        deviceRevision: OCKRevisionRecord,
        overwriteRemote: Bool,
        completion: @escaping (Error?) -> Void) {

        entitiesInPushRevision.append(contentsOf: deviceRevision.entities)
        timesPushWasCalled += 1
        timesForcePushed += overwriteRemote ? 1 : 0
        completion(nil)
    }

    func chooseConflictResolutionPolicy(
        _ conflict: OCKMergeConflictDescription,
        completion: @escaping (OCKMergeConflictResolutionPolicy) -> Void) {
        completion(conflictPolicy)
    }

    func dummyRevision() -> OCKRevisionRecord {
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
            .task(task),
            .outcome(outcome)
        ]

        let revision = OCKRevisionRecord(entities: entities, knowledgeVector: .init())
        return revision
    }
}

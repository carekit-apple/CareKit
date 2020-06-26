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

class MockPeer: OCKWatchConnectivityPeer {
    weak var peersStore: OCKStore!

    var overrideConflictPolicy: OCKMergeConflictResolutionPolicy!

    var lastRevisionReceivedFromPeer: OCKRevisionRecord?
    var lastRevisionPushedToPeer: OCKRevisionRecord?

    override func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord, @escaping (Error?) -> Void) -> Void,
        completion: @escaping (Error?) -> Void) {

        let time = knowledgeVector.clock(for: peersStore.context.clockID)
        let revision = peersStore.computeRevision(since: time)

        lastRevisionReceivedFromPeer = revision
        mergeRevision(revision, completion)
    }

    override func pushRevisions(
        deviceRevision: OCKRevisionRecord,
        overwriteRemote: Bool,
        completion: @escaping (Error?) -> Void) {

        lastRevisionPushedToPeer = deviceRevision
        peersStore.mergeRevision(deviceRevision, completion: completion)
    }

    override func chooseConflictResolutionPolicy(
        _ conflict: OCKMergeConflictDescription,
        completion: @escaping (OCKMergeConflictResolutionPolicy) -> Void) {
        completion(overrideConflictPolicy)
    }
}

class TestWatchConnectivityPeer: XCTestCase {

    var storeA: OCKStore!
    var peerA: MockPeer!

    var storeB: OCKStore!
    var peerB: MockPeer!

    override func setUp() {
        super.setUp()

        peerA = MockPeer()
        peerB = MockPeer()

        storeA = OCKStore(name: "A", type: .inMemory, remote: peerA)
        storeB = OCKStore(name: "B", type: .inMemory, remote: peerB)

        peerA.peersStore = storeB
        peerA.automaticallySynchronizes = false
        peerA.overrideConflictPolicy = .keepDevice

        peerB.peersStore = storeA
        peerB.automaticallySynchronizes = false
        peerB.overrideConflictPolicy = .keepRemote
    }

    override func tearDown() {
        super.tearDown()
        storeA = nil
        peerA = nil

        storeB = nil
        peerB = nil
    }

    func testPushToEmptyPeer() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule)
        task = try storeA.addTaskAndWait(task)

        var outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        outcome = try storeA.addOutcomeAndWait(outcome)

        try storeA.syncAndWait()
        XCTAssert(peerA.lastRevisionReceivedFromPeer?.entities.isEmpty == true)
        XCTAssert(peerA.lastRevisionPushedToPeer?.entities.count == 2)

        let tasks = try storeB.fetchTasksAndWait()
        let outcomes = try storeB.fetchOutcomesAndWait()

        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first == task)
        XCTAssert(outcomes.count == 1)
        XCTAssert(outcomes.first == outcome)
    }

    func testPullFromPeerIntoEmptyStore() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        var task = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule)
        task = try storeA.addTaskAndWait(task)

        var outcome = OCKOutcome(taskUUID: try task.getUUID(), taskOccurrenceIndex: 0, values: [])
        outcome = try storeA.addOutcomeAndWait(outcome)

        try storeB.syncAndWait()
        XCTAssert(peerB.lastRevisionReceivedFromPeer?.entities.count == 2)

        let tasks = try storeB.fetchTasksAndWait()
        let outcomes = try storeB.fetchOutcomesAndWait()

        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first == task)
        XCTAssert(outcomes.count == 1)
        XCTAssert(outcomes.first == outcome)
    }

    func testResolveConflict() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)

        var taskA = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule)
        taskA = try storeA.addTaskAndWait(taskA)

        var taskB = OCKTask(id: "B", title: nil, carePlanUUID: nil, schedule: schedule)
        taskB = try storeB.addTaskAndWait(taskB)

        try storeA.syncAndWait()

        let tasksA = try storeA.fetchTasksAndWait()
        let tasksB = try storeB.fetchTasksAndWait()
        XCTAssert(tasksA == tasksB)
    }

    func testSyncOneSidedOutcomeAdditionThenDeletion() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        var taskA = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule)
        taskA = try storeA.addTaskAndWait(taskA)

        try storeA.syncAndWait()

        let outcomeA = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])

        try storeA.addOutcomeAndWait(outcomeA)
        try storeA.syncAndWait()
        try storeA.deleteOutcomeAndWait(outcomeA)
        try storeA.syncAndWait()
        XCTAssert(peerA.lastRevisionPushedToPeer?.entities.count == 2)

        let tasksA = try storeA.fetchTasksAndWait()
        let tasksB = try storeB.fetchTasksAndWait()
        XCTAssert(tasksA == tasksB)

        let outcomesA = try storeA.fetchOutcomesAndWait()
        let outcomesB = try storeB.fetchOutcomesAndWait()
        XCTAssert(outcomesA == outcomesB)
        XCTAssert(outcomesA.isEmpty)
    }

    func testSyncTwoSidedOutcomeAdditionThenDeletion() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        var taskA = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule)
        taskA = try storeA.addTaskAndWait(taskA)

        try storeA.syncAndWait()

        let outcomeA = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])

        try storeA.addOutcomeAndWait(outcomeA)
        try storeA.syncAndWait()

        try storeB.deleteOutcomeAndWait(outcomeA)
        try storeB.syncAndWait()

        let tasksA = try storeA.fetchTasksAndWait()
        let tasksB = try storeB.fetchTasksAndWait()
        XCTAssert(tasksA == tasksB)

        let outcomesA = try storeA.fetchOutcomesAndWait()
        let outcomesB = try storeB.fetchOutcomesAndWait()
        XCTAssert(outcomesA == outcomesB)
    }

    func testResolveLongConflictBranchKeepingLongBranch() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        var taskA = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule)
        taskA = try storeA.addTaskAndWait(taskA)
        try storeA.syncAndWait()

        let outcome = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])
        for _ in 0..<5 {
            try storeA.addOutcomeAndWait(outcome)
            try storeA.deleteOutcomeAndWait(outcome)
        }
        try storeB.addOutcomeAndWait(outcome)

        try storeA.syncAndWait()
        let outcomesA = try storeA.fetchOutcomesAndWait()
        let outcomesB = try storeB.fetchOutcomesAndWait()
        XCTAssert(outcomesA == outcomesB)
        XCTAssert(outcomesA.isEmpty)
    }

    func testResolveLongConflictBranchKeepingShortBranch() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        var taskA = OCKTask(id: "A", title: nil, carePlanUUID: nil, schedule: schedule)
        taskA = try storeA.addTaskAndWait(taskA)
        try storeA.syncAndWait()

        let outcome = OCKOutcome(taskUUID: try taskA.getUUID(), taskOccurrenceIndex: 0, values: [])
        for _ in 0..<5 {
            try storeB.addOutcomeAndWait(outcome)
            try storeB.deleteOutcomeAndWait(outcome)
        }
        try storeA.addOutcomeAndWait(outcome)

        try storeA.syncAndWait()
        let outcomesA = try storeA.fetchOutcomesAndWait()
        let outcomesB = try storeB.fetchOutcomesAndWait()
        XCTAssert(outcomesA == outcomesB)
        XCTAssert(outcomesA.count == 1)
    }

    func testDeletingTask() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)

        let taskA1 = OCKTask(id: "A", title: "A1", carePlanUUID: nil, schedule: schedule)
        try storeA.addTaskAndWait(taskA1)

        let taskA2 = OCKTask(id: "A", title: "A2", carePlanUUID: nil, schedule: schedule)
        try storeA.updateTaskAndWait(taskA2)

        try storeA.syncAndWait()
        try storeA.deleteTasksAndWait([taskA2])
        try storeA.syncAndWait()

        let tasksA = try storeA.fetchTasksAndWait()
        let tasksB = try storeB.fetchTasksAndWait()

        XCTAssert(tasksA == tasksB)
    }
}

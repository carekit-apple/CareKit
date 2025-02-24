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

class TestWatchConnectivityPeer: XCTestCase {

    private var storeA: OCKStore!
    private var peerA: MockPeer!

    private var storeB: OCKStore!
    private var peerB: MockPeer!

    override func setUp() {
        super.setUp()

        peerA = MockPeer(name: "A")
        peerB = MockPeer(name: "B")

        storeA = OCKStore(name: UUID().uuidString, type: .inMemory, remote: peerA)
        storeB = OCKStore(name: UUID().uuidString, type: .inMemory, remote: peerB)

        peerA.peersStore = storeB
        peerA.automaticallySynchronizes = false

        peerB.peersStore = storeA
        peerB.automaticallySynchronizes = false
    }

    func testWatchConnectivityPeers() throws {
        let uuidA = storeA.context.clockID
        let uuidB = storeB.context.clockID

        // 1. Sync a task to from A to B, at B's request.
        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil)
        var taskA = OCKTask(id: "A", title: "A1", carePlanUUID: nil, schedule: schedule)

        try storeA.addTaskAndWait(taskA)
        try storeB.syncAndWait()

        let stateA1 = OCKRevisionRecord.KnowledgeVector([uuidA: 3, uuidB: 2])
        let stateB1 = OCKRevisionRecord.KnowledgeVector([uuidA: 1, uuidB: 3])

        let tasksA1 = try storeA.fetchTasksAndWait()
        let tasksB1 = try storeA.fetchTasksAndWait()

        XCTAssertEqual(tasksA1.count, 1)
        XCTAssertEqual(tasksB1.count, 1)
        XCTAssertEqual(storeA.context.knowledgeVector, stateA1)
        XCTAssertEqual(storeB.context.knowledgeVector, stateB1)

        // 2. Create conflicting updates on A and B, then sync again.
        //    A goes first, resolves the conflict, and sends the patch to B.
        //
        //    Both store should end with the original version, both conflicted
        //    versions, and the final non-conflicted version, totally 4 tasks.
        taskA.title = "A2"
        try storeA.updateTaskAndWait(taskA)

        taskA.title = "B2"
        try storeB.updateTaskAndWait(taskA)

        try storeA.syncAndWait()

        let stateA2 = OCKRevisionRecord.KnowledgeVector([uuidA: 5, uuidB: 3])
        let stateB2 = OCKRevisionRecord.KnowledgeVector([uuidA: 4, uuidB: 5])

        let tasksA2 = try storeA.fetchTasksAndWait()
        let tasksB2 = try storeB.fetchTasksAndWait()

        XCTAssertEqual(tasksA2.count, 4)
        XCTAssertEqual(tasksB2.count, 4)
        XCTAssertEqual(storeA.context.knowledgeVector, stateA2)
        XCTAssertEqual(storeB.context.knowledgeVector, stateB2)
    }
}

private final class MockPeer: OCKWatchConnectivityPeer {

    weak var peersStore: OCKStore!

    let name: String

    init(name: String) {
        self.name = name
    }

    override func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord) -> Void,
        completion: @escaping (Error?) -> Void) {

        do {
            let revisions = try peersStore.computeRevisions(since: knowledgeVector)
            revisions.forEach(mergeRevision)

            let catchUp = OCKRevisionRecord(
                entities: [],
                knowledgeVector: peersStore.context.knowledgeVector
            )
            mergeRevision(catchUp)

            peersStore.context.knowledgeVector.increment(clockFor: peersStore.context.clockID)
            completion(nil)

        } catch {
            completion(error)
        }
    }

    override func pushRevisions(
        deviceRevisions: [OCKRevisionRecord],
        deviceKnowledge: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping (Error?) -> Void) {

        deviceRevisions.forEach(peersStore.mergeRevision)
        let catchUp = OCKRevisionRecord(entities: [], knowledgeVector: deviceKnowledge)
        peersStore.mergeRevision(catchUp)

        peersStore.context.knowledgeVector.increment(clockFor: peersStore.context.clockID)
        self.peersStore.resolveConflicts(completion: completion)
    }
}

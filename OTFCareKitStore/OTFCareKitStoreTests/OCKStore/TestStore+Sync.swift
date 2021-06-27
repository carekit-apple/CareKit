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

@testable import OTFCareKitStore
import XCTest

final class TestStoreSynchronization: XCTestCase {

    func testMergeConflictResolution() throws {

        // 1. Setup the a server with two sync'd stores
        let server = SimulatedServer()

        let remoteA = SimulatedRemote(name: "A", server: server)
        let remoteB = SimulatedRemote(name: "B", server: server)

        let storeA = OCKStore(name: "A", type: .inMemory, remote: remoteA)
        let storeB = OCKStore(name: "B", type: .inMemory, remote: remoteB)

        let uuidA = storeA.context.clockID
        let uuidB = storeB.context.clockID

        let startKnowledgeA = OCKRevisionRecord.KnowledgeVector([uuidA: 1])
        let startKnowledgeB = OCKRevisionRecord.KnowledgeVector([uuidB: 1])

        XCTAssert(startKnowledgeA == storeA.context.knowledgeVector)
        XCTAssert(startKnowledgeB == storeB.context.knowledgeVector)
        XCTAssert(server.revisions.isEmpty)

        // 2. Sync the first version of a task from A to B.
        let schedule = OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil)
        var task = OCKTask(id: "a", title: "A", carePlanUUID: nil, schedule: schedule)
        task = try storeA.addTasksAndWait([task]).first!

        try storeA.syncAndWait()
        try storeB.syncAndWait()

        let firstTasksA = try storeA.fetchTasksAndWait()
        let firstTasksB = try storeB.fetchTasksAndWait()

        let firstKnowledgeA = OCKRevisionRecord.KnowledgeVector([
            uuidA: 3 // +1 post pull, +1 post push
        ])

        let firstKnowledgeB = OCKRevisionRecord.KnowledgeVector([
            uuidA: 2, // latest value on server from A
            uuidB: 3  // +1 post pull, +1 post push
        ])

        let firstRevisionStamp = OCKRevisionRecord.KnowledgeVector([
            uuidA: 2  // Latest value on server
        ])

        XCTAssert(firstTasksA.count == 1, "Expected 1, got \(firstTasksA.count)")
        XCTAssert(firstTasksB.count == 1, "Expected 1, got \(firstTasksB.count)")
        XCTAssert(firstKnowledgeA == storeA.context.knowledgeVector)
        XCTAssert(firstKnowledgeB == storeB.context.knowledgeVector)
        XCTAssert(firstRevisionStamp == server.revisions.last?.stamp)
        XCTAssert(server.revisions.count == 1)

        // 2. Create conflicting updates in both stores.
        //    Neither store will have a conflict yet.
        var taskA = try storeA.fetchTasksAndWait().first!
        taskA.title = "A2"
        try storeA.updateTasksAndWait([taskA])

        var taskB = try storeB.fetchTasksAndWait().first!
        taskB.title = "B2"
        try storeB.updateTasksAndWait([taskB])

        // 3. Sync storeA: Put the new version on the server
        //    Sync storeB: Resolve the conflict locally and push to server
        try storeA.syncAndWait()
        try storeB.syncAndWait()

        // 4. Check that A has only it's two local versions
        //    Check that B has the original, both conflicts, and the resolution
        let midTasksA = try storeA.fetchTasksAndWait()
        let midTasksB = try storeB.fetchTasksAndWait()

        let midKnowledgeA = OCKRevisionRecord.KnowledgeVector([
            uuidA: 5, // +1 post pull, +1 post push
            uuidB: 2  // latest value on server from B
        ])

        let midKnowledgeB = OCKRevisionRecord.KnowledgeVector([
            uuidA: 4, // latest value on server from A
            uuidB: 5  // +1 post pull, +1 post push
        ])

        let midRevisionStamp = OCKRevisionRecord.KnowledgeVector([
            uuidA: 4,  // B's knowledge of A when it pushed
            uuidB: 4   // B's clock when it pushed
        ])

        XCTAssert(midTasksA.count == 2, "Expected 2, but got \(midTasksA.count)")
        XCTAssert(midTasksB.count == 4, "Expected 4, but got \(midTasksB.count)")
        XCTAssert(midKnowledgeA == storeA.context.knowledgeVector)
        XCTAssert(midKnowledgeB == storeB.context.knowledgeVector)
        XCTAssert(midRevisionStamp == server.revisions.last?.stamp)
        XCTAssert(server.revisions.count == 3)

        // 5. Sync storeA: Pull updates from the server (conflict + resolution)
        //    Sync storeB: Already up to date, no observable change
        try storeA.syncAndWait()
        try storeB.syncAndWait()

        let finalTasksA = try storeA.fetchTasksAndWait()
        let finalTasksB = try storeB.fetchTasksAndWait()

        let finalKnowledgeA = OCKRevisionRecord.KnowledgeVector([
            uuidA: 7, // +1 post pull, +1 post push
            uuidB: 4  // latest value on server from B
        ])

        let finalKnowledgeB = OCKRevisionRecord.KnowledgeVector([
            uuidA: 6, // latest value on server from A
            uuidB: 7  // +1 post pull, +1 post push
        ])

        let finalRevisionStamp = midRevisionStamp // No changes pushed

        XCTAssert(finalTasksA.count == 4, "Expected 4, but got \(finalTasksA.count)")
        XCTAssert(finalTasksB.count == 4, "Expected 4, but got \(finalTasksB.count)")
        XCTAssert(finalKnowledgeA == storeA.context.knowledgeVector)
        XCTAssert(finalKnowledgeB == storeB.context.knowledgeVector)
        XCTAssert(finalRevisionStamp == server.revisions.last?.stamp)
        XCTAssert(server.revisions.count == 3)
    }
}

private final class SimulatedServer {

    private(set) var revisions = [(stamp: OCKRevisionRecord.KnowledgeVector, data: Data)]()

    private var knowledge = OCKRevisionRecord.KnowledgeVector()

    func upload(
        data: Data?,
        deviceKnowledge: OCKRevisionRecord.KnowledgeVector,
        from remote: SimulatedRemote) throws {

        if let latest = revisions.last?.stamp, latest >= deviceKnowledge {
            let problem = "New knowledge on server. Pull first then try again"
            throw OCKStoreError.remoteSynchronizationFailed(reason: problem)
        }

        knowledge.merge(with: deviceKnowledge)

        if let data = data {
            revisions.append((stamp: deviceKnowledge, data: data))
        }
    }

    func updates(
        for deviceKnowledge: OCKRevisionRecord.KnowledgeVector,
        from remote: SimulatedRemote) -> (stamp: OCKRevisionRecord.KnowledgeVector, data: [Data]) {

        let newToRemote = revisions.filter { $0.stamp >= deviceKnowledge }
        let newData = newToRemote.map(\.data)

        return (stamp: knowledge, newData)
    }
}

private final class SimulatedRemote: OCKRemoteSynchronizable {

    let name: String

    let server: SimulatedServer

    weak var delegate: OCKRemoteSynchronizationDelegate?

    var automaticallySynchronizes: Bool = false

    init(name: String, server: SimulatedServer) {
        self.name = name
        self.server = server
    }

    func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord) -> Void,
        completion: @escaping (Error?) -> Void) {

        do {
            let response = server.updates(for: knowledgeVector, from: self)
            let decoder = JSONDecoder()
            let entities = try response.data.flatMap { try decoder.decode([OCKEntity].self, from: $0) }
            let revision = OCKRevisionRecord(entities: entities, knowledgeVector: response.stamp)
            mergeRevision(revision)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    func pushRevisions(
        deviceRevision: OCKRevisionRecord,
        completion: @escaping (Error?) -> Void) {

        do {
            let data = deviceRevision.entities.isEmpty ?
                nil : try! JSONEncoder().encode(deviceRevision.entities)

            let knowledge = deviceRevision.knowledgeVector

            try server.upload(data: data, deviceKnowledge: knowledge, from: self)

            completion(nil)

        } catch {
            completion(error)
        }
    }

    func chooseConflictResolution(
        conflicts: [OCKEntity], completion: @escaping OCKResultClosure<OCKEntity>) {

        let keep = conflicts.max(by: { $0.value.createdDate! > $1.value.createdDate! })!
        completion(.success(keep))
    }
}

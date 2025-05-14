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

@testable import CareKitStore
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

        XCTAssertEqual(startKnowledgeA, storeA.context.knowledgeVector)
        XCTAssertEqual(startKnowledgeB, storeB.context.knowledgeVector)
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

        let firstServerKnowledge = OCKRevisionRecord.KnowledgeVector([
            uuidA: 2, // Received from A during push
            uuidB: 2  // Received from B during push
        ])

        XCTAssertEqual(firstTasksA.count, 1, "Expected 1, got \(firstTasksA.count)")
        XCTAssertEqual(firstTasksB.count, 1, "Expected 1, got \(firstTasksB.count)")
        XCTAssertEqual(firstKnowledgeA, storeA.context.knowledgeVector)
        XCTAssertEqual(firstKnowledgeB, storeB.context.knowledgeVector)
        XCTAssertEqual(firstServerKnowledge, server.knowledgeVector)
        XCTAssertEqual(server.revisions.count, 1)

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
            uuidA: 4, // latest clock on server from A
            uuidB: 5  // +1 post pull, +1 post push
        ])

        let midServerKnowledge = OCKRevisionRecord.KnowledgeVector([
            uuidA: 4, // latest clock from A
            uuidB: 4  // latest clock from B
        ])

        XCTAssertEqual(midTasksA.count, 2, "Expected 2, but got \(midTasksA.count)")
        XCTAssertEqual(midTasksB.count, 4, "Expected 4, but got \(midTasksB.count)")
        XCTAssertEqual(midKnowledgeA, storeA.context.knowledgeVector)
        XCTAssertEqual(midKnowledgeB, storeB.context.knowledgeVector)
        XCTAssertEqual(midServerKnowledge, server.knowledgeVector)
        XCTAssertEqual(server.revisions.count, 4) // 4 versions with different vectors

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

        XCTAssertEqual(finalTasksA.count, 4, "Expected 4, but got \(finalTasksA.count)")
        XCTAssertEqual(finalTasksB.count, 4, "Expected 4, but got \(finalTasksB.count)")
        XCTAssertEqual(finalKnowledgeA, storeA.context.knowledgeVector)
        XCTAssertEqual(finalKnowledgeB, storeB.context.knowledgeVector)
        XCTAssertEqual(server.revisions.count, 4)
    }
}

private struct SimulatedPayload: Codable {
    let knowledgeVector: OCKRevisionRecord.KnowledgeVector
    let encryptedRevisions: [EncryptedRevision]
}

private struct EncryptedRevision: Codable {
    let knowledgeVector: OCKRevisionRecord.KnowledgeVector
    let encryptedData: Data
}

private final class SimulatedServer {

    private(set) var revisions = [EncryptedRevision]()

    private(set) var knowledgeVector = OCKRevisionRecord.KnowledgeVector()

    func upload(
        payload: SimulatedPayload,
        from remote: SimulatedRemote) throws {

        if let latest = revisions.last?.knowledgeVector,
           latest >= payload.knowledgeVector {

            let problem = "New knowledge on server. Pull first then try again"
            throw OCKStoreError.remoteSynchronizationFailed(reason: problem)
        }

        knowledgeVector.merge(with: payload.knowledgeVector)
        revisions.append(contentsOf: payload.encryptedRevisions)
    }

    func updates(
        for deviceKnowledge: OCKRevisionRecord.KnowledgeVector,
        from remote: SimulatedRemote) -> SimulatedPayload {

        let newToRemote = revisions.filter {
            $0.knowledgeVector >= deviceKnowledge
        }

        let payload = SimulatedPayload(
            knowledgeVector: knowledgeVector,
            encryptedRevisions: newToRemote
        )

        return payload
    }
}

private final class SimulatedRemote: OCKRemoteSynchronizable {

    let name: String

    let server: SimulatedServer

    weak var delegate: OCKRemoteSynchronizationDelegate?

    var automaticallySynchronizes = false

    init(name: String, server: SimulatedServer) {
        self.name = name
        self.server = server
    }

    func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord) -> Void,
        completion: @escaping (Error?) -> Void) {

        do {
            let payload = server.updates(for: knowledgeVector, from: self)

            let decryptor = JSONDecoder() // Simulated decryption

            let revisions = try payload.encryptedRevisions.map {
                try decryptor.decode(
                    OCKRevisionRecord.self,
                    from: $0.encryptedData
                )
            }

            let catchUp = OCKRevisionRecord(
                entities: [],
                knowledgeVector: payload.knowledgeVector
            )

            revisions.forEach(mergeRevision)
            mergeRevision(catchUp)

            completion(nil)
        } catch {
            completion(error)
        }
    }

    func pushRevisions(
        deviceRevisions: [OCKRevisionRecord],
        deviceKnowledge: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping (Error?) -> Void) {

        do {

            let encryptor = JSONEncoder() // Simulated encryption

            let encryptedRevisions = try deviceRevisions.map {
                EncryptedRevision(
                    knowledgeVector: $0.knowledgeVector,
                    encryptedData: try encryptor.encode($0)
                )
            }

            let payload = SimulatedPayload(
                knowledgeVector: deviceKnowledge,
                encryptedRevisions: encryptedRevisions
            )

            try server.upload(payload: payload, from: self)

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

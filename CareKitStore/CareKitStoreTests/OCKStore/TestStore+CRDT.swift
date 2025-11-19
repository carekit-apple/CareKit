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
import Foundation
import XCTest

/// The merge function has properties that makes the store a CRDT.
///
///  - **Idempotent**: Merging the same revision twice has no effect. `A U A = A`
///  - **Commutative**: Merge order doesn't matter. `A U B = B U A`
///  - **Associative**: Any grouping produces the same result. `A U (B U C) = (A U B) U C`
class TestStoreCRDTMergeProperties: XCTestCase {

    func testMergeIsIdempotent() async throws {
        let store = OCKStore(name: "idempotent", type: .inMemory)
        let revision = makeRevisions(count: 1).first!
        let repeated = [OCKRevisionRecord](repeating: revision, count: 10)

        for revision in repeated {
            store.mergeRevision(revision)
        }

        let patients = try await store.fetchPatients(query: OCKPatientQuery())
        XCTAssertEqual(patients.count, 1)
    }

    func testMergeIsCommutative() async throws {
        let store = OCKStore(name: "commutative", type: .inMemory)
        let revisions = makeRevisions(count: 10).shuffled()

        for revision in revisions {
            store.mergeRevision(revision)
        }

        let patients = try await store.fetchPatients(query: OCKPatientQuery())
        for i in 0..<10 {
            XCTAssertEqual(patients[i].previousVersionUUIDs.isEmpty, (i == 9))
        }
    }

    func testMergeIsAssociative() async throws {

        // Merging individually
        let storeA = OCKStore(name: "individual", type: .inMemory)
        let revisions = makeRevisions(count: 10)
        for revision in revisions {
            storeA.mergeRevision(revision)
        }

        // Group and then merge
        let empty = OCKRevisionRecord(entities: [], knowledgeVector: .init())
        let group1 = revisions[0...5].reduce(empty, merge)
        let group2 = revisions[6...9].reduce(empty, merge)

        let storeB = OCKStore(name: "batched", type: .inMemory)
        storeB.mergeRevision(group1)
        storeB.mergeRevision(group2)

        // Check that the end result is the same in both cases
        let fetchedA = try await storeA.fetchPatients(query: OCKPatientQuery())
        let fetchedB = try await storeB.fetchPatients(query: OCKPatientQuery())

        XCTAssertEqual(fetchedA.map(\.name), fetchedB.map(\.name))
        XCTAssertEqual(fetchedA.map(\.previousVersionUUIDs), fetchedB.map(\.previousVersionUUIDs))
        XCTAssertEqual(fetchedA.map(\.nextVersionUUIDs), fetchedB.map(\.nextVersionUUIDs))
    }

    private func makeRevisions(count: Int) -> [OCKRevisionRecord] {

        var revisions = [OCKRevisionRecord]()
        let uuids = Array(0..<count).map { _ in UUID() }

        for i in 0..<count {

            var patient = OCKPatient(id: "a", givenName: "Version", familyName: "\(i)")
            patient.uuid = uuids[i]
            patient.createdDate = Date()
            patient.updatedDate = Date()
            patient.effectiveDate = Date()
            patient.previousVersionUUIDs = i > 0 ? [uuids[i - 1]] : []
            patient.nextVersionUUIDs = i < count - 1 ? [uuids[i + 1]] : []

            let revision = OCKRevisionRecord(
                entities: [.patient(patient)],
                knowledgeVector: OCKRevisionRecord.KnowledgeVector([UUID(): 1])
            )

            revisions.append(revision)
        }

        return revisions
    }

    private func merge(
        _ revA: OCKRevisionRecord,
        _ revB: OCKRevisionRecord) -> OCKRevisionRecord {

        var vector = revA.knowledgeVector
        vector.merge(with: revB.knowledgeVector)

        let entities = revA.entities + revB.entities

        let merged = OCKRevisionRecord(
            entities: entities,
            knowledgeVector: vector
        )

        return merged
    }
}

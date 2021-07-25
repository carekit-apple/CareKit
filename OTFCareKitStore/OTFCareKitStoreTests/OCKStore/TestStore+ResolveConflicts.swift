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

@testable import OTFCareKitStore
import Foundation
import XCTest

class TestStoreResolveConflicts: XCTestCase {

    func testResolveMultipleConflictsCallsResolutionMethodRepeatedly() throws {

        let remote = MockRemote()
        let store = OCKStore(name: UUID().uuidString, type: .inMemory, remote: remote)
        let patientA = OCKPatient(id: "A", givenName: "a", familyName: "aa")
        let patientB = OCKPatient(id: "B", givenName: "b", familyName: "bb")
        try store.addPatientsAndWait([patientA, patientB])

        let vector = OCKRevisionRecord.KnowledgeVector([UUID(): 1])
        let conflictA = OCKPatient(id: "A", givenName: "A", familyName: "AA")
        let conflictB = OCKPatient(id: "B", givenName: "B", familyName: "BB")
        let entities = [OCKEntity.patient(conflictA), .patient(conflictB)]
        let revision = OCKRevisionRecord(entities: entities, knowledgeVector: vector)

        var timesCalled = 0

        remote.resolveConflict = { conflicts in
            timesCalled += 1
            return conflicts.first!
        }

        store.mergeRevision(revision)
        try store.resolveConflictsAndWait()
        XCTAssert(timesCalled == 2)
    }

    // swiftlint:disable identifier_name
    func testResolveConflictCanBeCalledWithMoreThanTwoConflicts() throws {
        let remote = MockRemote()
        let store = OCKStore(name: UUID().uuidString, type: .inMemory, remote: remote)
        let patientA = OCKPatient(id: "A", givenName: "a", familyName: "aa")
        try store.addPatientAndWait(patientA)

        let conflicts = Array(1...9).map { i in
            OCKPatient(id: "A", givenName: "\(i)", familyName: "")
        }
        let vector = OCKRevisionRecord.KnowledgeVector([UUID(): 1])
        let entities = conflicts.map { OCKEntity.patient($0) }
        let revision = OCKRevisionRecord(entities: entities, knowledgeVector: vector)

        remote.resolveConflict = { conflicts in
            XCTAssert(conflicts.count == 10)
            return conflicts.first!
        }

        store.mergeRevision(revision)
        try store.resolveConflictsAndWait()
    }
}

private class MockRemote: OCKRemoteSynchronizable {

    weak var delegate: OCKRemoteSynchronizationDelegate?

    var automaticallySynchronizes: Bool = false

    var resolveConflict: (([OCKEntity]) throws -> OCKEntity)!

    func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord) -> Void,
        completion: @escaping (Error?) -> Void) {
        fatalError("Not implemented")
    }

    func pushRevisions(
        deviceRevision: OCKRevisionRecord,
        completion: @escaping (Error?) -> Void) {
        fatalError("Not implemented")
    }

    func chooseConflictResolution(
        conflicts: [OCKEntity],
        completion: @escaping OCKResultClosure<OCKEntity>) {

        do {
            let result = try resolveConflict(conflicts)
            completion(.success(result))
        } catch {
            completion(.failure(.remoteSynchronizationFailed(reason: "Fail")))
        }
    }
}

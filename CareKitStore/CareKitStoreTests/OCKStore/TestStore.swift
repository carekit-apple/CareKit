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

class TestStore: XCTestCase {

    func testDeleteStore() {
        let store = OCKStore(name: UUID().uuidString, type: .onDisk())
        _ = store.context // Storage is created lazily. Access context to force file creation.

        XCTAssertTrue(FileManager.default.fileExists(atPath: store.storeURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.walFileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.shmFileURL.path))

        XCTAssertNoThrow(try store.delete())

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.storeURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.walFileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.shmFileURL.path))
    }

    func testDeleteInMemoryStore() {
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        _ = store.context // Storage is created lazily. Access context to force file creation.

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.storeURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.walFileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.shmFileURL.path))

        XCTAssertNoThrow(try store.delete())
    }

    func testRollingBackContextRollsBackKnowledgeVector() throws {
        let store = OCKStore(name: UUID().uuidString, type: .inMemory)
        
        expect(with: store.context) {
            XCTAssert(store.context.clockTime == 1)

            store.context.knowledgeVector.increment(clockFor: store.context.clockID)
            try store.context.save()
            XCTAssert(store.context.clockTime == 2)

            store.context.knowledgeVector.increment(clockFor: store.context.clockID)
            XCTAssert(store.context.clockTime == 3)

            store.context.knowledgeVector.increment(clockFor: store.context.clockID)
            store.context.rollback()
            XCTAssert(store.context.clockTime == 2)
        }
    }
}

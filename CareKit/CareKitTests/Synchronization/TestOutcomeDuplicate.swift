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

import XCTest
@testable import CareKitStore
import CoreData

class TestOutcomeDuplicate: XCTestCase {
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        context = OCKCoreDataContextFactory().makeContext()
    }

    func testDuplicateOutcomeValidation() throws {
        // Create a task 
        let task = OCKCDTask(context: context)
        task.uuid = UUID()
        task.scheduleElements = []

        // Create first outcome 
        let outcome1 = OCKCDOutcome(context: context)
        outcome1.uuid = UUID()
        outcome1.task = task
        outcome1.taskOccurrenceIndex = 0

        // Create a next version outcome 
        let outcome2 = OCKCDOutcome(context: context)
        outcome2.uuid = UUID()
        outcome2.task = task 
        outcome2.taskOccurrenceIndex = 0
        outcome1.next = [outcome2]

        // outcome1 should skip duplicate validation because it has a next version
        XCTAssertNoThrow(try outcome1.validateForInsert())

        // Save outcome1 to context
        try context.save()

        // outcome2 should check for duplicates and throw, since outcome1 exists
        outcome2.next = []
        XCTAssertThrowsError(try outcome2.validateForInsert()) { error in 
            XCTAssertEqual((error as? OCKStoreError)?.localizedDescription, "A duplicate outcome exists for this task.")
        }
    }
}

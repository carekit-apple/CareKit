/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
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

class TestStoreOutcomes: XCTestCase {
    var store: OCKStore!

    override func setUp() {
        super.setUp()
        store = OCKStore(name: "TestDatabase", type: .inMemory)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    // MARK: Relationship Validation

    func testStorePreventsMissingTaskRelationshipOnOutcomes() {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        store.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addOutcomeAndWait(outcome))
    }

    func testStoreAllowsMissingTaskRelationshipOnOutcomes() {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        XCTAssertNoThrow(try store.addOutcomeAndWait(outcome))
    }

    // MARK: Insertion

    func testAddAndFetchOutcomes() throws {
        let value = OCKOutcomeValue(42)
        var outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [value])
        outcome = try store.addOutcomeAndWait(outcome)
        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes == [outcome])
        XCTAssertNotNil(outcomes.first?.localDatabaseID)
        XCTAssertNotNil(outcomes.first?.schemaVersion)
    }

    func testTestOutcomeValueIndexIsPersisted() throws {
        var value = OCKOutcomeValue(42)
        value.index = 2
        var outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [value])
        outcome = try store.addOutcomeAndWait(outcome)
        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes.first?.values.first?.index == 2)
    }

    func testAddOutcomeToTask() throws {
        var task = OCKTask(identifier: "task", title: "My Task", carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)
        guard let taskID = task.versionID else { XCTFail("Task should have had an ID after being persisted"); return }
        var outcome = OCKOutcome(taskID: taskID, taskOccurenceIndex: 2, values: [])
        outcome = try store.addOutcomeAndWait(outcome)
        XCTAssert(outcome.taskID == taskID)
    }

    // MARK: Querying

    func testOutcomeQueryGroupIdentifier() throws {
        var task = OCKTask(identifier: "abc", title: "ABC", carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)
        let value = OCKOutcomeValue(42)
        var outcomeA = OCKOutcome(taskID: task.versionID, taskOccurenceIndex: 0, values: [value])
        outcomeA.groupIdentifier = "A"
        var outcomeB = OCKOutcome(taskID: task.versionID, taskOccurenceIndex: 1, values: [value])
        outcomeB.groupIdentifier = "B"
        try store.addOutcomesAndWait([outcomeA, outcomeB])
        var query = OCKOutcomeQuery(for: Date())
        query.groupIdentifiers = ["A"]
        let fetched = try store.fetchOutcomesAndWait(nil, query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.taskOccurenceIndex == 0)
    }

    func testBasicQueryDoesNotReturnOutcomesWithNoAssociatedTask() throws {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        try store.addOutcomeAndWait(outcome)
        let outcomes = try store.fetchOutcomesAndWait(query: OCKOutcomeQuery(start: Date(), end: Date()))
        XCTAssert(outcomes.isEmpty)
    }

    func testQueryReturnsOnlyOutcomesInTheQueryDateRange() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(identifier: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        guard let date1 = task.schedule[0]?.start.addingTimeInterval(-10) else { XCTFail("Bad date"); return }
        guard let date2 = task.schedule[1]?.start.addingTimeInterval(-10) else { XCTFail("Bad date"); return }
        let outcome1 = try store.addOutcomeAndWait(OCKOutcome(taskID: task.localDatabaseID, taskOccurenceIndex: 0, values: []))
        let outcome2 = try store.addOutcomeAndWait(OCKOutcome(taskID: task.localDatabaseID, taskOccurenceIndex: 1, values: []))
        let outcomes = try store.fetchOutcomesAndWait(.taskIdentifiers([task.identifier]), query: OCKOutcomeQuery(start: date1, end: date2))
        XCTAssert(outcomes.count == 1)
        XCTAssertTrue(outcomes.contains(outcome1))
        XCTAssertFalse(outcomes.contains(outcome2))
    }

    func testOutcomeQueryLimit() throws {
        var task = OCKTask(identifier: "A", title: "A", carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)
        let outcomeA = OCKOutcome(taskID: task.versionID, taskOccurenceIndex: 0, values: [OCKOutcomeValue(10)])
        let outcomeB = OCKOutcome(taskID: task.versionID, taskOccurenceIndex: 1, values: [OCKOutcomeValue(20)])
        try store.addOutcomesAndWait([outcomeA, outcomeB])
        var query = OCKOutcomeQuery(for: Date())
        query.limit = 1
        let fetched = try store.fetchOutcomesAndWait(nil, query: query)
        XCTAssert(fetched.count == 1)
    }

    func testQueryOutcomesByRemoteID() throws {
        var outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        outcome.remoteID = "abc"
        outcome = try store.addOutcomeAndWait(outcome)

        let fetched = try store.fetchOutcomesAndWait(.outcomeRemoteIDs(["abc"]), query: nil).first
        XCTAssert(fetched == outcome)
    }

    func testQueryOutcomeByTaskRemoteID() throws {
        var task = OCKTask(identifier: "A", title: nil, carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task.remoteID = "abc"
        task = try store.addTaskAndWait(task)

        var outcome = OCKOutcome(taskID: task.versionID, taskOccurenceIndex: 0, values: [])
        outcome = try store.addOutcomeAndWait(outcome)

        let fetched = try store.fetchOutcomesAndWait(.taskRemoteIDs(["abc"]), query: .today).first
        XCTAssert(fetched == outcome)
    }

    // MARK: Updating

    func testUpdateOutcomes() throws {
        let outcomeA = try store.addOutcomeAndWait(OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: []))
        let outcomeB = try store.updateOutcomeAndWait(outcomeA)
        XCTAssert(outcomeB.localDatabaseID == outcomeA.localDatabaseID)
    }

    func testUpdateFailsForUnsavedOutcomes() {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        XCTAssertThrowsError(try store.updateOutcomeAndWait(outcome))
    }

    // MARK: Deletion

    func testDeleteOutcome() throws {
        let outcome = try store.addOutcomeAndWait(OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: []))
        try store.deleteOutcomeAndWait(outcome)
        let fetched = try store.fetchOutcomesAndWait()
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteOutcomeFailsIfOutcomeDoesntExist() {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        XCTAssertThrowsError(try store.deleteOutcomeAndWait(outcome))
    }
}

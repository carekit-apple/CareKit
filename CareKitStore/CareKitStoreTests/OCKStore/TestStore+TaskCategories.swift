//
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

class TestStoreTaskCategories: XCTestCase {
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

    func testStoreAllowsMissingCarePlanRelationshipOnTaskCategories() {
        let taskCategory = OCKTaskCategory(id: "taskCategory", title: "Amy", carePlanID: nil)
        XCTAssertNoThrow(try store.addTaskCategoryAndWait(taskCategory))
    }

    func testStorePreventsMissingCarePlanRelationshipOnTaskCategories() {
        let taskCategory = OCKTaskCategory(id: "taskCategory", title: "Amy", carePlanID: nil)
        store.configuration.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addTaskCategoryAndWait(taskCategory))
    }

    // MARK: Insertion

    func testAddTaskCategory() throws {
        var taskCategory = OCKTaskCategory(id: "taskCategory", title: "Amy", carePlanID: nil)


        taskCategory = try store.addTaskCategoryAndWait(taskCategory)
        let fetchedTaskCategories = try store.fetchTaskCategoriesAndWait()

        XCTAssert(taskCategory.title == "Amy")
        XCTAssertNotNil(taskCategory.schemaVersion)
    }

    func testAddTaskCategoryFailsIfIdentifierAlreadyExists() throws {
        let taksCatetory1 = OCKTaskCategory(id: "taskCategory1", title: "Amy", carePlanID: nil)
        let taskCategory2 = OCKTaskCategory(id: "taskCategory2", title: "Amy2", carePlanID: nil)
        try store.addTaskCategoryAndWait(taksCatetory1)
        XCTAssertThrowsError(try store.addTaskCategoryAndWait(taskCategory2))
    }

    // MARK: Querying
    func testQueryTaskCategoriesByIdentifier() throws {
        let taskCategory1 = try store.addTaskCategoryAndWait(OCKTaskCategory(id: "taskCategory1", title: "Amy", carePlanID: nil))
        try store.addTaskCategoryAndWait(OCKTaskCategory(id: "taskCategory2", title: "Amy2", carePlanID: nil))
        let fetchedTaskCategories = try store.fetchTaskCategoriesAndWait(query: OCKTaskCategoryQuery(id: "taskCategory1"))
        XCTAssert(fetchedTaskCategories == [taskCategory1])
    }

    func testQueryTaskCategoriesByCarePlanID() throws {
        let carePlan = try store.addCarePlanAndWait(OCKCarePlan(id: "B", title: "Care Plan A", patientID: nil))
        try store.addTaskCategoryAndWait(OCKTaskCategory(id: "care plan 1", title: "Mark", familyName: "Brown", carePlanID: nil))
        var taskCategory = OCKTaskCategory(id: "care plan 2", givenName: "Amy", familyName: "Frost", carePlanID: try carePlan.getLocalID())
        taskCategory = try store.addTaskCategoryAndWait(taskCategory)
        var query = OCKTaskCategoryQuery()
        query.carePlanIDs = [carePlan.id]
        let fetchedTaskCategories = try store.fetchTaskCategoriesAndWait(query: query)
        XCTAssert(fetchedTaskCategories == [taskCategory])
    }

    func testTaskCategoriesQueryGroupIdentifiers() throws {
        var taskCategoryA = OCKTaskCategory(id: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        taskCategoryA.groupIdentifier = "Alpha"
        var taskCategoryB = OCKTaskCategory(id: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        taskCategorytB.groupIdentifier = "Beta"
        try store.addTaskCategoriesAndWait([taskCategoryA, taskCategoryB])
        var query = OCKTaskCategoryQuery(for: Date())
        query.groupIdentifiers = ["Alpha"]
        let fetched = try store.fetchTdaskCategoriesAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.groupIdentifier == "Alpha")
    }

    func testTaskCategoryQueryTags() throws {
        var taskCategoryA = OCKTaskCategory(id: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        taskCategoryA.tags = ["A"]
        var taskCategoryB = OCKTaskCategory(id: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        taskCategoryB.tags = ["B", "C"]
        var taskCategoryC = OCKTaskCategory(id: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        taskCategoryC.tags = ["C"]
        try store.addTaskCategoriesAndWait([taskCategoryA, taskCategoryB, taskCategoryC])
        var query = OCKTaskCategoryQuery(for: Date())
        query.tags = ["C"]
        let fetched = try store.fetchTaskCategoriesAndWait(query: query)
        XCTAssert(fetched.map { $0.id }.sorted() == ["B", "C"])
    }

    func testTaskCategoryQueryLimited() throws {
        let taskCategoryA = OCKTaskCategory(id: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        let taskCategoryB = OCKTaskCategory(id: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        let taskCategoryC = OCKTaskCategory(id: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        try store.addTaskCategoriesAndWait([taskCategoryA, taskCategoryB, taskCategoryC])
        var query = OCKTaskCategoryQuery(for: Date())
        query.limit = 2
        let fetched = try store.fetchTaskCategoriesAndWait(query: query)
        XCTAssert(fetched.count == 2)
    }

    func testTaskCategoryQueryOffset() throws {
        let taskCategoryA = OCKTaskCategory(id: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        let taskCategoryB = OCKTaskCategory(id: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        let taskCategoryC = OCKTaskCategory(id: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        try store.addTaskCategoriesAndWait([taskCategoryA, taskCategoryB, taskCategoryC])
        var query = OCKTaskCategoryQuery(for: Date())
        query.offset = 2
        let fetched = try store.fetchCTaskCategoriesAndWait(query: query)
        XCTAssert(fetched.count == 1)
    }

    func testTaskCategoryQuerySorted() throws {
        let taskCategoryA = OCKTaskCategory(id: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        let taskCategoryB = OCKTaskCategory(id: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        let taskCategoryC = OCKTaskCategory(id: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        try store.addTaskCategoriesAndWait([taskCategoryA, taskCategoryB, taskCategoryC])
        var query = OCKTaskCategoryQuery(for: Date())
        query.sortDescriptors = [.givenName(ascending: true)]
        let fetched = try store.fetchTaskCategoriesAndWait(query: query)
        XCTAssert(fetched.map { $0.name.givenName } == ["a", "b", "c"])
    }

    func testTaskCategoryNilQueryReturnsAllTaskCategories() throws {
        let taskCategoryA = OCKTaskCategory(id: "A", givenName: "a", familyName: "aaa", carePlanID: nil)
        let taskCategoryB = OCKTaskCategory(id: "B", givenName: "b", familyName: "bbb", carePlanID: nil)
        let taskCategoryC = OCKTaskCategory(id: "C", givenName: "c", familyName: "cccc", carePlanID: nil)
        try store.addTaskCategoriesAndWait([taskCategoryA, taskCategoryB, taskCategoryC])
        let taskCategories = try store.fetchTaskCategoriesAndWait()
        XCTAssertNotNil(taskCategories.count == 3)
    }

    func testQueryTaskCategoryByRemoteID() throws {
        var taskCategory = OCKTaskCategory(id: "A", givenName: "B", familyName: "C", carePlanID: nil)
        taskCategory.remoteID = "abc"
        taskCategory = try store.addTaskCategoryAndWait(taskCategory)
        var query = OCKTaskCategoryQuery()
        query.remoteIDs = ["abc"]
        let fetched = try store.fetchTaskCategoriesAndWait(query: query).first
        XCTAssert(fetched == taskCategory)
    }

    func testQueryTaskCategoryByCarePlanRemoteID() throws {
        var plan = OCKCarePlan(id: "D", title: "", patientID: nil)
        plan.remoteID = "abc"
        plan = try store.addCarePlanAndWait(plan)

        var taskCategory = OCKTaskCategory(id: "A", givenName: "B", familyName: "C", carePlanID: plan.localDatabaseID)
        taskCategory = try store.addTaskCategoryAndWait(taskCategory)
        var query = OCKTaskCategoryQuery(for: Date())
        query.carePlanRemoteIDs = ["abc"]
        let fetched = try store.fetchTaskCategoriesAndWait(query: query).first
        XCTAssert(fetched == taskCategory)
    }

    func testQueryTaskCategoryByCarePlanVersionID() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(id: "A", title: "B", patientID: nil))
        let planID = try plan.getLocalID()
        let taskCategory = try store.addTaskCategoryAndWait(OCKTaskCategory(id: "C", givenName: "D", familyName: "E", carePlanID: planID))
        var query = OCKTaskCategoryQuery(for: Date())
        query.carePlanVersionIDs = [planID]
        let fetched = try store.fetchTaskCategoriesAndWait(query: query).first
        XCTAssert(fetched == taskCategory)
    }

    // MARK: Versioning

    func testUpdateTaskCategoryCreatesNewVersion() throws {
        let taskCategory = try store.addTaskCategoryAndWait(OCKTaskCategory(id: "taskCategory", givenName: "John", familyName: "Appleseed", carePlanID: nil))
        let updated = try store.updateTaskCategoryAndWait(OCKTaskCategory(id: "taskCategory", givenName: "Jane", familyName: "Appleseed", carePlanID: nil))
        XCTAssert(updated.name.givenName == "Jane")
        XCTAssert(updated.localDatabaseID != taskCategory.localDatabaseID)
        XCTAssert(updated.previousVersionID == taskCategory.localDatabaseID)
    }

    func testUpdateFailsForUnsavedTaskCategories() {
        let patient = OCKTaskCategory(id: "careplan", givenName: "John", familyName: "Appleseed", carePlanID: nil)
        XCTAssertThrowsError(try store.updateTaskCategoryAndWait(patient))
    }

    func testTaskCategoryQueryOnlyReturnsLatestVersionOfATaskCategory() throws {
        let versionA = try store.addTaskCategoryAndWait(OCKTaskCategory(id: "taskCategory", givenName: "Amy", familyName: "Frost", carePlanID: nil))
        let versionB = try store.updateTaskCategoryAndWait(OCKTaskCategory(id: "taskCategory", givenName: "Mariana", familyName: "Lin", carePlanID: nil))
        let fetched = try store.fetchTaskCategoryAndWait(id: versionA.id)
        XCTAssert(fetched?.id == versionB.id)
        XCTAssert(fetched?.name == versionB.name)
    }

    func testTaskCategoryQueryOnPastDateReturnsPastVersionOfATaskCategory() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKTaskCategory(id: "A", givenName: "a", familyName: "b", carePlanID: nil)
        versionA.effectiveDate = dateA
        versionA = try store.addTaskCategoryAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKTaskCategory(id: "A", givenName: "a", familyName: "c", carePlanID: nil)
        versionB.effectiveDate = dateB
        versionB = try store.updateTaskCategoryAndWait(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(-10))
        let query = OCKTaskCategoryQuery(dateInterval: interval)
        let fetched = try store.fetchTaskCategoriesAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.name == versionA.name)
    }

    func testTaskCategoryQuerySpanningVersionsReturnsNewestVersionOnly() throws {
        let dateA = Date().addingTimeInterval(-100)
        var versionA = OCKTaskCategory(id: "A", givenName: "a", familyName: "b", carePlanID: nil)
        versionA.effectiveDate = dateA
        versionA = try store.addTaskCategoryAndWait(versionA)

        let dateB = Date().addingTimeInterval(100)
        var versionB = OCKTaskCategory(id: "A", givenName: "a", familyName: "c", carePlanID: nil)
        versionB.effectiveDate = dateB
        versionB = try store.updateTaskCategoryAndWait(versionB)

        let interval = DateInterval(start: dateA.addingTimeInterval(10), end: dateB.addingTimeInterval(10))
        let query = OCKTaskCategoryQuery(dateInterval: interval)

        let fetched = try store.fetchTaskCategoriesAndWait(query: query)
        XCTAssert(fetched.count == 1)
        XCTAssert(fetched.first?.name == versionB.name)
    }

    func testTaskCategoryQueryBeforeTaskCategoryWasCreatedReturnsNoResults() throws {
        let dateA = Date()
        try store.addTaskCategoryAndWait(OCKTaskCategory(id: "A", givenName: "a", familyName: "b", carePlanID: nil))
        let interval = DateInterval(start: dateA.addingTimeInterval(-100), end: dateA)
        let query = OCKTaskCategoryQuery(dateInterval: interval)
        let fetched = try store.fetchTaskCategoriesAndWait(query: query)
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: Deletion

    func testDeleteTaskCategory() throws {
        let taskCategory = try store.addTaskCategoryAndWait(OCKTaskCategory(id: "taskCategory", givenName: "Christopher", familyName: "Foss", carePlanID: nil))
        try store.deleteTaskCategoryAndWait(taskCategory)
        let fetched = try store.fetchTaskCategoriesAndWait()
        XCTAssert(fetched.isEmpty)
    }

    func testDeleteTaskCategoryfailsIfTaskCategoryDoesntExist() {
        let taskCategory = OCKTaskCategory(id: "taskCategory", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        XCTAssertThrowsError(try store.deleteTaskCategoryAndWait(taskCategory))
    }
}

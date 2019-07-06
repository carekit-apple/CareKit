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

import XCTest
@testable import CareKitStore

class TestCoreDataCarePlanStore: XCTestCase {
    
    var store: OCKStore!
    
    override func setUp() {
        super.setUp()
        store = OCKStore(name: "TestDatabase", type: .inMemory)
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }

    @discardableResult
    func seedDummyPatients() throws -> [OCKPatient] {
        let patientA = OCKPatient(identifier: "A", givenName: "Amy", familyName: "Frost")
        let patientB = OCKPatient(identifier: "B", givenName: "Christopher", familyName: "Foss")
        let patientC = OCKPatient(identifier: "C", givenName: "Jared", familyName: "Gosler")
        let patientD = OCKPatient(identifier: "D", givenName: "Joyce", familyName: "Sohn")
        let patientE = OCKPatient(identifier: "E", givenName: "Lauren", familyName: "Trottier")
        let patientF = OCKPatient(identifier: "F", givenName: "Mariana", familyName: "Lin")
        try store.addPatientsAndWait([patientA, patientB, patientC, patientD, patientE, patientF])
        try store.updatePatientsAndWait([patientA, patientC])
        return try store.fetchPatientsAndWait()
    }
    
    @discardableResult
    func seedDummyCarePlans() throws -> [OCKCarePlan] {
        let patients = try seedDummyPatients()
        let plan1 = OCKCarePlan(identifier: "1", title: "1", patientID: patients[0].localDatabaseID)
        let plan2 = OCKCarePlan(identifier: "2", title: "2", patientID: patients[0].localDatabaseID)
        let plan3 = OCKCarePlan(identifier: "3", title: "3", patientID: nil)
        try store.addCarePlansAndWait([plan1, plan2, plan3])
        return try store.fetchCarePlansAndWait()
    }
    
    // MARK: Allows missing relationships tests
    
    func testStorePreventsMissingPatientRelationshipOnCarePlans() {
        let plan = OCKCarePlan(identifier: "diabetes_type_1", title: "Diabetes Care Plan", patientID: nil)
        store.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addCarePlanAndWait(plan))
    }
    
    func testStoreAllowsMissingPatientRelationshipOnCarePlans() {
        let plan = OCKCarePlan(identifier: "diabetes_type_1", title: "Diabetes Care Plan", patientID: nil)
        XCTAssertNoThrow(try store.addCarePlanAndWait(plan))
    }
    
    func testStoreAllowsMissingCarePlanRelationshipOnContacts() {
        let contact = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        XCTAssertNoThrow(try store.addContactAndWait(contact))
    }
    
    func testStorePreventsMissingCarePlanRelationshipOnContacts() {
        let contact = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        store.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addContactAndWait(contact))
    }

    func testStorePreventsMissingPlanRelationshipOnTasks() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(identifier: "medicine", title: "Advil", carePlanID: nil, schedule: schedule)
        store.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addTaskAndWait(task))
    }
    
    func testStoreAllowsMissingPlanRelationshipOnTasks() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(identifier: "medicine", title: "Advil", carePlanID: nil, schedule: schedule)
        XCTAssertNoThrow(try store.addTaskAndWait(task))
    }
    
    func testStorePreventsMissingTaskRelationshipOnOutcomes() {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        store.allowsEntitiesWithMissingRelationships = false
        XCTAssertThrowsError(try store.addOutcomeAndWait(outcome))
    }
    
    func testStoreAllowsMissingTaskRelationshipOnOutcomes() {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        XCTAssertNoThrow(try store.addOutcomeAndWait(outcome))
    }
    
    // MARK: Add and Fetch tests
    func testAddAndFetchPatients() throws {
        let patient = try store.addPatientAndWait(OCKPatient(identifier: "my_id", givenName: "Amy", familyName: "Frost"))
        let patients = try store.fetchPatientsAndWait()
        XCTAssert(patients.first == patient)
    }
    
    func testAddPatientForAnyPatientBeyondTheFirstPatient() throws {
        let patient1 = OCKPatient(identifier: "id1", givenName: "Amy", familyName: "Frost")
        let patient2 = OCKPatient(identifier: "id2", givenName: "Christopher", familyName: "Foss")
        try store.addPatientAndWait(patient1)
        XCTAssertThrowsError(try store.addPatientAndWait(patient2))
    }
    
    func testAddPatientFailsIfIdentifierAlreadyExists() throws {
        let patient1 = OCKPatient(identifier: "my_id", givenName: "Amy", familyName: "Frost")
        let patient2 = OCKPatient(identifier: "my_id", givenName: "Jared", familyName: "Gosler")
        try store.addPatientAndWait(patient1)
        XCTAssertThrowsError(try store.addPatientAndWait(patient2))
    }
    
    func testAddAndFetchCarePlans() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "6789", title: "Diabetes Care Plan", patientID: nil))
        let fetchedPlans = try store.fetchCarePlansAndWait()
        XCTAssert(fetchedPlans.count == 1)
        XCTAssert(fetchedPlans.first == plan)
    }
    
    func testAddCarePlanFailsIfIdentifierAlreadyExists() throws {
        let plan1 = OCKCarePlan(identifier: "id", title: "Diabetes Care Plan", patientID: nil)
        let plan2 = OCKCarePlan(identifier: "id", title: "Obesity Care Plan", patientID: nil)
        try store.addCarePlanAndWait(plan1)
        XCTAssertThrowsError(try store.addCarePlanAndWait(plan2))
    }
    
    func testAddAndFetchContacts() throws {
        var contact = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        let address = OCKPostalAddress()
        address.state = "CO"
        address.country = "US"
        address.street = "4693 Sweetwood Drive"
        contact.address = address
        contact.messagingNumbers = [OCKLabeledValue(label: "iPhone", value: "303-555-0194")]
        contact.phoneNumbers = [OCKLabeledValue(label: "Home", value: "303-555-0108")]
        contact.emailAddresses = [OCKLabeledValue(label: "Email", value: "amy_frost44@icloud.com")]
        contact.otherContactInfo = [OCKLabeledValue(label: "Facetime", value: "303-555-0121")]
        contact.organization = "Apple Dumplings Corp."
        contact.title = "Manager of Apple Peeling"
        contact.role = "Official Taste Tester"
        
        contact = try store.addContactAndWait(contact)
        let fetchedConctacts = try store.fetchContactsAndWait()
        XCTAssert([contact] == fetchedConctacts)
        XCTAssert(contact.address?.state == "CO")
        XCTAssert(contact.address?.country == "US")
        XCTAssert(contact.address?.street == "4693 Sweetwood Drive")
        XCTAssert(contact.messagingNumbers == [OCKLabeledValue(label: "iPhone", value: "303-555-0194")])
        XCTAssert(contact.phoneNumbers == [OCKLabeledValue(label: "Home", value: "303-555-0108")])
        XCTAssert(contact.emailAddresses == [OCKLabeledValue(label: "Email", value: "amy_frost44@icloud.com")])
        XCTAssert(contact.otherContactInfo == [OCKLabeledValue(label: "Facetime", value: "303-555-0121")])
        XCTAssert(contact.organization == "Apple Dumplings Corp.")
        XCTAssert(contact.title == "Manager of Apple Peeling")
        XCTAssert(contact.role == "Official Taste Tester")
    }
    
    func testAddContactFailsIfIdentifierAlreadyExists() throws {
        let contact1 = OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil)
        let contact2 = OCKContact(identifier: "contact", givenName: "Jared", familyName: "Gosler", carePlanID: nil)
        try store.addContactAndWait(contact1)
        XCTAssertThrowsError(try store.addContactAndWait(contact2))
    }
    
    func testFetchContactsByIdentifier() throws {
        let contact1 = try store.addContactAndWait(OCKContact(identifier: "contact1", givenName: "Amy", familyName: "Frost", carePlanID: nil))
        try store.addContactAndWait(OCKContact(identifier: "contact2", givenName: "Amy", familyName: "Frost", carePlanID: nil))
        let fetchedContacts = try store.fetchContactsAndWait(.contactIdentifier(["contact1"]))
        XCTAssert(fetchedContacts == [contact1])
    }
    
    func testFetchContactsByCarePlanID() throws {
        let carePlan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "cp", title: "Care Plan", patientID: nil))
        guard let carePlanVersionID = carePlan.versionID else { XCTFail("Care Plan was missing a version identifier"); return }
        try store.addContactAndWait(OCKContact(identifier: "care plan 1", givenName: "Mark", familyName: "Brown", carePlanID: nil))
        var contact = OCKContact(identifier: "care plan 2", givenName: "Amy", familyName: "Frost", carePlanID: carePlanVersionID)
        contact = try store.addContactAndWait(contact)
        let fetchedContacts = try store.fetchContactsAndWait(.contactIdentifier([contact.identifier]))
        XCTAssert(fetchedContacts == [contact])
    }
    
    func testAddAndFetchTasks() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: today)!

        let schedule1 = OCKSchedule.mealTimesEachDay(start: lastWeek, end: nil, targetValues: [OCKOutcomeValue(11.1)])
        let task1 = OCKTask(identifier: "squats", title: "Front Squats", carePlanID: nil, schedule: schedule1)
        
        let schedule2 = OCKSchedule.mealTimesEachDay(start: tomorrow, end: nil)
        let task2 = OCKTask(identifier: "lunges", title: "Forward Lunges", carePlanID: nil, schedule: schedule2)
        try store.addTasksAndWait([task1, task2])

        let tasks = try store.fetchTasksAndWait(query: .today)
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.identifier == task1.identifier)
    }
    
    func testFetchTaskByIdentifier() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task1 = OCKTask(identifier: "squats", title: "Front Squats", carePlanID: nil, schedule: schedule)
        let task2 = OCKTask(identifier: "lunges", title: "Forward Lunges", carePlanID: nil, schedule: schedule)
        try store.addTasksAndWait([task1, task2])
        let tasks = try store.fetchTasksAndWait(.taskIdentifiers([task1.identifier]))
        XCTAssert(tasks.count == 1)
        XCTAssert(tasks.first?.identifier == task1.identifier)
    }
    
    func testAddTaskFailsIfIdentifierAlreadyExists() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(identifier: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        try store.addTaskAndWait(task)
        XCTAssertThrowsError(try store.addTaskAndWait(task))
    }
    
    func testAddAndFetchOutcomes() throws {
        let value = OCKOutcomeValue(42)
        var outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [value])
        outcome = try store.addOutcomeAndWait(outcome)
        let outcomes = try store.fetchOutcomesAndWait()
        XCTAssert(outcomes == [outcome])
    }
    
    func testAddOutcomeToTask() throws {
        var task = OCKTask(identifier: "task", title: "My Task", carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        task = try store.addTaskAndWait(task)
        guard let taskID = task.versionID else { XCTFail("Task should have had an ID after being persisted"); return }
        var outcome = OCKOutcome(taskID: taskID, taskOccurenceIndex: 2, values: [])
        outcome = try store.addOutcomeAndWait(outcome)
        XCTAssert(outcome.taskID == taskID)
    }
    
    func testFetchOutcomesWithQueryDoesntReturnOutcomesWithNoAssociatedTask() throws {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        try store.addOutcomeAndWait(outcome)
        let outcomes = try store.fetchOutcomesAndWait(query: OCKOutcomeQuery(start: Date(), end: Date()))
        XCTAssert(outcomes.isEmpty)
    }
    
    func testFetchOutcomesWithQueryReturnsOnlyOutcomesInTheQueryDateRange() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        var task = OCKTask(identifier: "exercise", title: "Push Ups", carePlanID: nil, schedule: schedule)
        task = try store.addTaskAndWait(task)
        guard let date1 = task.schedule[0]?.start.addingTimeInterval(-10) else { XCTFail("Bad date"); return }
        guard let date2 = task.schedule[1]?.start.addingTimeInterval(-10) else { XCTFail("Bad date"); return }
        let outcome1 = try store.addOutcomeAndWait(OCKOutcome(taskID: task.localDatabaseID, taskOccurenceIndex: 0, values: []))
        let outcome2 = try store.addOutcomeAndWait(OCKOutcome(taskID: task.localDatabaseID, taskOccurenceIndex: 1, values: []))
        let outcomes = try store.fetchOutcomesAndWait(.taskIdentifier(task.identifier), query: OCKOutcomeQuery(start: date1, end: date2))
        XCTAssert(outcomes.count == 1)
        XCTAssertTrue(outcomes.contains(outcome1))
        XCTAssertFalse(outcomes.contains(outcome2))
    }
    
    // MARK: Update tests
    
    func testUpdatePatients() throws {
        let patient = try store.addPatientAndWait(OCKPatient(identifier: "my_id", givenName: "Chris", familyName: "Saari"))
        let updatedPatient = try store.updatePatientAndWait(OCKPatient(identifier: "my_id", givenName: "Chris", familyName: "Sillers"))
        XCTAssert(updatedPatient.name.familyName == "Sillers")
        XCTAssert(updatedPatient.previousVersionID == patient.versionID)
    }
    
    func testUpdatePatientWithoutVersioning() throws {
        store.configuration.updatesCreateNewVersions = false
        let patient = try store.addPatientAndWait(OCKPatient(identifier: "my_id", givenName: "Chris", familyName: "Saari"))
        var updatedPatient = OCKPatient(identifier: "my_id", givenName: "Chris", familyName: "Sillers")
        updatedPatient = try store.updatePatientAndWait(updatedPatient)
        XCTAssert(updatedPatient.name.familyName == "Sillers")
        XCTAssert(updatedPatient.previousVersionID == nil)
        XCTAssert(updatedPatient.versionID == patient.versionID)
    }
    
    func testUpdateFailsForUnsavedPatient() {
        XCTAssertThrowsError(try store.updatePatientAndWait(OCKPatient(identifier: "my_id", givenName: "Christoper", familyName: "Foss")))
    }
    
    func testUpdateCarePlans() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "bronchitis", title: "Bronchitis", patientID: nil))
        let updatedPlan = try store.updateCarePlanAndWait(OCKCarePlan(identifier: "bronchitis", title: "Bronchitis Treatment", patientID: nil))
        XCTAssert(updatedPlan.title == "Bronchitis Treatment")
        XCTAssert(updatedPlan.previousVersionID == plan.localDatabaseID)
    }
    
    func testUpdateCarePlanWithoutVersioning() throws {
        store.configuration.updatesCreateNewVersions = false
        var plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "bronchitis", title: "Bronchitis", patientID: nil))
        plan.title = "Bronchitis Treatment"
        let updatedPlan = try store.updateCarePlanAndWait(plan)
        XCTAssert(updatedPlan.title == "Bronchitis Treatment")
        XCTAssert(updatedPlan.localDatabaseID == plan.localDatabaseID)
    }
    
    func testUpdateFailsForUnsavedCarePlans() {
        XCTAssertThrowsError(try store.updateCarePlanAndWait(OCKCarePlan(identifier: "bronchitis", title: "Bronchitis", patientID: nil)))
    }
    
    func testUpdateContacts() throws {
        let contact = try store.addContactAndWait(OCKContact(identifier: "contact", givenName: "John", familyName: "Appleseed", carePlanID: nil))
        let updated = try store.updateContactAndWait(OCKContact(identifier: "contact", givenName: "Jane", familyName: "Appleseed", carePlanID: nil))
        XCTAssert(updated.name.givenName == "Jane")
        XCTAssert(updated.versionID != contact.versionID)
        XCTAssert(updated.previousVersionID == contact.versionID)
    }
    
    func testUpdateContactsWithoutVersioning() throws {
        store.configuration.updatesCreateNewVersions = false
        var contact = try store.addContactAndWait(OCKContact(identifier: "contact", givenName: "John", familyName: "Appleseed", carePlanID: nil))
        contact.name.givenName = "Jane"
        let updated = try store.updateContactAndWait(contact)
        XCTAssert(updated.name.givenName == "Jane")
        XCTAssert(updated.versionID == contact.versionID)
    }
    
    func testUpdateFailsForUnsavedContacts() {
        let patient = OCKContact(identifier: "careplan", givenName: "John", familyName: "Appleseed", carePlanID: nil)
        XCTAssertThrowsError(try store.updateContactAndWait(patient))
    }
    
    func testUpdateTasks() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: schedule))
        let updatedTask = try store.updateTaskAndWait(OCKTask(identifier: "meds", title: "New Medication", carePlanID: nil, schedule: schedule))
        XCTAssert(updatedTask.title == "New Medication")
        XCTAssert(updatedTask.previousVersionID == task.localDatabaseID)
    }
    
    func testUpdateTasksWithoutVersioning() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: schedule))
        store.configuration.updatesCreateNewVersions = false
        let updatedTask = try store.updateTaskAndWait(OCKTask(identifier: "meds", title: "New Medication", carePlanID: nil, schedule: schedule))
        XCTAssert(updatedTask.title == "New Medication")
        XCTAssert(updatedTask.localDatabaseID == task.localDatabaseID)
    }
    
    func testUpdateFailsForUnsavedTasks() {
        let task = OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: .mealTimesEachDay(start: Date(), end: nil))
        XCTAssertThrowsError(try store.updateTaskAndWait(task))
    }
    
    func testUpdateOutcomes() throws {
        let outcomeA = try store.addOutcomeAndWait(OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: []))
        let outcomeB = try store.updateOutcomeAndWait(outcomeA)
        XCTAssert(outcomeB.localDatabaseID == outcomeA.localDatabaseID)
    }
    
    func testUpdateFailsForUnsavedOutcomes() {
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        XCTAssertThrowsError(try store.updateOutcomeAndWait(outcome))
    }
    
    // MARK: Delete tests
    
    func testDeletePatient() throws {
        let patient = try store.addPatientAndWait(OCKPatient(identifier: "my_id", givenName: "John", familyName: "Appleseed"))
        try store.deletePatientAndWait(patient)
        let fetched = try store.fetchPatientsAndWait()
        XCTAssert(fetched.isEmpty)
    }
    
    func testDeletePatientFailsIfPatientDoesntExist() {
        XCTAssertThrowsError(try store.deletePatientAndWait(OCKPatient(identifier: "my_id", givenName: "John", familyName: "Appleseed")))
    }
    
    func testDeleteCarePlan() throws {
        let plan = try store.addCarePlanAndWait(OCKCarePlan(identifier: "stinky_breath", title: "Gingivitus", patientID: nil))
        try store.deleteCarePlanAndWait(plan)
        let fetched = try store.fetchCarePlansAndWait()
        XCTAssert(fetched.isEmpty)
    }
    
    func testDeleteCarePlanFailsIfCarePlanDoesntExist() {
        let plan = OCKCarePlan(identifier: "stinky_breath", title: "Gingivitus", patientID: nil)
        XCTAssertThrowsError(try store.deleteCarePlanAndWait(plan))
    }
    
    func testDeleteContact() throws {
        let contact = try store.addContactAndWait(OCKContact(identifier: "contact", givenName: "Christopher", familyName: "Foss", carePlanID: nil))
        try store.deleteContactAndWait(contact)
        let fetched = try store.fetchContactsAndWait()
        XCTAssert(fetched.isEmpty)
    }
    
    func testDeleteContactfailsIfContactDoesntExist() {
        XCTAssertThrowsError(try store.deleteContactAndWait(OCKContact(identifier: "contact",
                                                                       givenName: "Amy",
                                                                       familyName: "Frost",
                                                                       carePlanID: nil)))
    }
    
    func testDeleteTask() throws {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = try store.addTaskAndWait(OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: schedule))
        try store.deleteTaskAndWait(task)
        let fetched = try store.fetchTasksAndWait()
        XCTAssert(fetched.isEmpty)
    }
    
    func testDeleteTaskFailsIfTaskDoesntExist() {
        let schedule = OCKSchedule.mealTimesEachDay(start: Date(), end: nil)
        let task = OCKTask(identifier: "meds", title: "Medication", carePlanID: nil, schedule: schedule)
        XCTAssertThrowsError(try store.deleteTaskAndWait(task))
    }
    
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
    
    // MARK: Queries Return Latest Version Only
    
    func testPatientQueryOnlyReturnsLatestVersionOfAPatient() throws {
        let versionA = try store.addPatientAndWait(OCKPatient(identifier: "A", givenName: "Jared", familyName: "Gosler"))
        let versionB = try store.updatePatientAndWait(OCKPatient(identifier: "A", givenName: "John", familyName: "Appleseed"))
        let fetched = try store.fetchPatientAndWait(identifier: versionA.identifier)
        XCTAssert(fetched == versionB)
    }
    
    func testCarePlanQueryOnlyReturnsLatestVersionOfACarePlan() throws {
        let versionA = try store.addCarePlanAndWait(OCKCarePlan(identifier: "A", title: "Amy", patientID: nil))
        let versionB = try store.updateCarePlanAndWait(OCKCarePlan(identifier: "A", title: "Jared", patientID: nil))
        let fetched = try store.fetchCarePlanAndWait(identifier: versionA.identifier)
        XCTAssert(fetched?.identifier == versionB.identifier)
        XCTAssert(fetched?.previousVersionID == versionA.localDatabaseID)
    }
    
    func testContactQueryOnlyReturnsLatestVersionOfAContact() throws {
        let versionA = try store.addContactAndWait(OCKContact(identifier: "contact", givenName: "Amy", familyName: "Frost", carePlanID: nil))
        let versionB = try store.updateContactAndWait(OCKContact(identifier: "contact", givenName: "Mariana", familyName: "Lin", carePlanID: nil))
        let fetched = try store.fetchContactAndWait(identifier: versionA.identifier)
        XCTAssert(fetched?.identifier == versionB.identifier)
        XCTAssert(fetched?.name == versionB.name)
    }
    
    // MARK: Nil Query Returns All Objects
    
    func testPatientQueryWithNilIdentifiersReturnsAllPatients() throws {
        _ = try? seedDummyPatients()
        let patients = try store.fetchPatientsAndWait()
        XCTAssert(!patients.isEmpty)
    }
    
    func testCarePlanQueryWithNilQueryReturnsAllCarePlans() throws {
        _ = try seedDummyCarePlans()
        let plans = try store.fetchCarePlansAndWait()
        XCTAssert(!plans.isEmpty)
    }
    
    // MARK: Notes
    
    func testCanAttachNotesToPatient() throws {
        var patient = OCKPatient(identifier: "Mr. John", givenName: "John", familyName: "Appleseed")
        patient.notes = [OCKNote(author: "Johnny", title: "My Diary", content: "Today I studied biochemistry!")]
        let savedPatient = try store.addPatientAndWait(patient)
        XCTAssert(savedPatient.notes?.count == 1)
    }
    
    func testCanAttachNotesToCarePlan() throws {
        var plan = OCKCarePlan(identifier: "obesity", title: "Obesity", patientID: nil)
        plan.notes = [OCKNote(author: "Mariana", title: "Refrigerator Notes", content: "Butter, milk, eggs")]
        let savedPlan = try store.addCarePlanAndWait(plan)
        XCTAssert(savedPlan.notes?.count == 1)
    }
    
    func testCanAttachNotesToTask() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 06, minutes: 0, start: Date(), end: nil, text: nil)
        var task = OCKTask(identifier: "id123", title: "prayer", carePlanID: nil, schedule: schedule)
        task.notes = [OCKNote(author: "Jared", title: "Note", content: "Made some remarks")]
        let savedTask = try store.addTaskAndWait(task)
        XCTAssert(savedTask.notes?.count == 1)
    }
    
    func testCanAttachNotesToOutcome() throws {
        var outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [])
        outcome.notes = [OCKNote(author: "Jared", title: "My Recipe", content: "Bacon, eggs, and cheese")]
        let savedOutcome = try store.addOutcomeAndWait(outcome)
        XCTAssert(savedOutcome.notes?.count == 1)
    }
    
    func testCanAttachNotesToOutcomeValues() throws {
        var value = OCKOutcomeValue(10.0)
        value.notes = [OCKNote(author: "Amy", title: "High Temperature", content: "Stopped taking medication because it gave me a fever")]
        let outcome = OCKOutcome(taskID: nil, taskOccurenceIndex: 0, values: [value])
        let savedOutcome = try store.addOutcomeAndWait(outcome)
        XCTAssertNotNil(savedOutcome.values.first?.notes?.first)
    }
    
    func testCanSaveNotesOnNotes() throws {
        var note = OCKNote(author: "Mr. A", title: "Title A", content: "Content A")
        note.notes = [OCKNote(author: "Mr. B", title: "Title B", content: "Content B")]
        var patient = OCKPatient(identifier: "johnny", givenName: "John", familyName: "Appleseed")
        patient.notes = [note]
        let savedPatient = try store.addPatientAndWait(patient)
        XCTAssertNotNil(savedPatient.notes?.first?.notes?.first)
    }
}

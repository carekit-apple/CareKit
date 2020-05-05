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

import CoreData

// This file defines the CoreData database schema used by `OCKStore`. The following diagram is provided
// to help help visualize the relationships between the major entities.
//
// Patient <-------->> Care Plan <----->> Task <------>> Outcome <---->> OutcomeValue
//        |                    |            |
//        |<----> Name         |            |<--->> ScheduleElement <--->> OutcomeValue
//                             |            |
//                             |            |<----> HealthKitLinkage
//                             |
//                             |<----->> Contact
//                                          |
//                                          |<---> Name
//                                          |<---> Address
//
// Versioned Entities:
// - Patient
// - CarePlan
// - Contact
// - Task
//

private let secureUnarchiver = "NSSecureUnarchiveFromData"
private let schemaVersion = OCKSemanticVersion(majorVersion: 2, minorVersion: 0, patchNumber: 4)

private func makeManagedObjectModel() -> NSManagedObjectModel {
    let managedObjectModel = NSManagedObjectModel()

    // Create entities and their attributes
    let patient = makePatientEntity()
    let carePlan = makeCarePlanEntity()
    let contact = makeContactEntity()
    let task = makeTaskEntity()
    let schedule = makeScheduleEntity()
    let outcome = makeOutcomeEntity()
    let outcomeValue = makeOutcomeValueEntity()
    let note = makeNoteEntity()
    let name = makePersonNameEntity()
    let address = makeAddressEntity()
    let healthLink = makeHealthKitLinkageEntity()
    let clock = makeClockEntity()

    // MARK: Patient Relationships

    let patientToCarePlan = NSRelationshipDescription()
    patientToCarePlan.name = "carePlans"
    patientToCarePlan.destinationEntity = carePlan
    patientToCarePlan.isOptional = true
    patientToCarePlan.minCount = 0
    patientToCarePlan.maxCount = 0
    patientToCarePlan.deleteRule = .cascadeDeleteRule

    let patientToName = NSRelationshipDescription()
    patientToName.name = "name"
    patientToName.destinationEntity = name
    patientToName.isOptional = false
    patientToName.minCount = 1
    patientToName.maxCount = 1
    patientToName.deleteRule = .cascadeDeleteRule

    let patientToNote = NSRelationshipDescription()
    patientToNote.name = "notes"
    patientToNote.destinationEntity = note
    patientToNote.isOptional = true
    patientToNote.minCount = 0
    patientToNote.maxCount = 0
    patientToNote.deleteRule = .cascadeDeleteRule

    let patientNextVersion = NSRelationshipDescription()
    patientNextVersion.name = "next"
    patientNextVersion.destinationEntity = patient
    patientNextVersion.isOptional = true
    patientNextVersion.minCount = 0
    patientNextVersion.maxCount = 1
    patientNextVersion.deleteRule = .cascadeDeleteRule

    let patientPrevVersion = NSRelationshipDescription()
    patientPrevVersion.name = "previous"
    patientPrevVersion.destinationEntity = patient
    patientPrevVersion.isOptional = true
    patientPrevVersion.minCount = 0
    patientPrevVersion.maxCount = 1
    patientPrevVersion.deleteRule = .nullifyDeleteRule

    // MARK: Care Plan Relationships

    let carePlanToPatient = NSRelationshipDescription()
    carePlanToPatient.name = "patient"
    carePlanToPatient.destinationEntity = patient
    carePlanToPatient.isOptional = true
    carePlanToPatient.minCount = 0
    carePlanToPatient.maxCount = 1
    carePlanToPatient.deleteRule = .nullifyDeleteRule

    let carePlanToContact = NSRelationshipDescription()
    carePlanToContact.name = "contacts"
    carePlanToContact.destinationEntity = contact
    carePlanToContact.isOptional = true
    carePlanToContact.minCount = 0
    carePlanToContact.maxCount = 0
    carePlanToContact.deleteRule = .cascadeDeleteRule

    let carePlanToTask = NSRelationshipDescription()
    carePlanToTask.name = "tasks"
    carePlanToTask.destinationEntity = task
    carePlanToTask.isOptional = true
    carePlanToTask.minCount = 0
    carePlanToTask.maxCount = 0
    carePlanToTask.deleteRule = .cascadeDeleteRule

    let carePlanToNote = NSRelationshipDescription()
    carePlanToNote.name = "notes"
    carePlanToNote.destinationEntity = note
    carePlanToNote.isOptional = true
    carePlanToNote.minCount = 0
    carePlanToNote.maxCount = 0
    carePlanToNote.deleteRule = .cascadeDeleteRule

    let carePlanNextVersion = NSRelationshipDescription()
    carePlanNextVersion.name = "next"
    carePlanNextVersion.destinationEntity = carePlan
    carePlanNextVersion.isOptional = true
    carePlanNextVersion.minCount = 0
    carePlanNextVersion.maxCount = 1
    carePlanNextVersion.deleteRule = .cascadeDeleteRule

    let carePlanPrevVersion = NSRelationshipDescription()
    carePlanPrevVersion.name = "previous"
    carePlanPrevVersion.destinationEntity = carePlan
    carePlanPrevVersion.isOptional = true
    carePlanPrevVersion.minCount = 0
    carePlanPrevVersion.maxCount = 1
    carePlanPrevVersion.deleteRule = .nullifyDeleteRule

    // MARK: Conctact Relationships

    let contactToCarePlan = NSRelationshipDescription()
    contactToCarePlan.name = "carePlan"
    contactToCarePlan.destinationEntity = carePlan
    contactToCarePlan.isOptional = true
    contactToCarePlan.minCount = 0
    contactToCarePlan.maxCount = 1
    contactToCarePlan.deleteRule = .nullifyDeleteRule

    let contactToAddress = NSRelationshipDescription()
    contactToAddress.name = "address"
    contactToAddress.destinationEntity = address
    contactToAddress.isOptional = true
    contactToAddress.minCount = 0
    contactToAddress.maxCount = 1
    contactToAddress.deleteRule = .cascadeDeleteRule

    let contactToName = NSRelationshipDescription()
    contactToName.name = "name"
    contactToName.destinationEntity = name
    contactToName.isOptional = false
    contactToName.minCount = 1
    contactToName.maxCount = 1
    contactToName.deleteRule = .denyDeleteRule

    let contactToNote = NSRelationshipDescription()
    contactToNote.name = "notes"
    contactToNote.destinationEntity = note
    contactToNote.isOptional = true
    contactToNote.minCount = 0
    contactToNote.maxCount = 0
    contactToNote.deleteRule = .cascadeDeleteRule

    let contactNextVersion = NSRelationshipDescription()
    contactNextVersion.name = "next"
    contactNextVersion.destinationEntity = contact
    contactNextVersion.isOptional = true
    contactNextVersion.minCount = 0
    contactNextVersion.maxCount = 1
    contactNextVersion.deleteRule = .cascadeDeleteRule

    let contactPrevVersion = NSRelationshipDescription()
    contactPrevVersion.name = "previous"
    contactPrevVersion.destinationEntity = contact
    contactPrevVersion.isOptional = true
    contactPrevVersion.minCount = 0
    contactPrevVersion.maxCount = 1
    contactPrevVersion.deleteRule = .nullifyDeleteRule

    // MARK: Task Relationships

    let taskToCarePlan = NSRelationshipDescription()
    taskToCarePlan.name = "carePlan"
    taskToCarePlan.destinationEntity = carePlan
    taskToCarePlan.isOptional = true
    taskToCarePlan.minCount = 0
    taskToCarePlan.maxCount = 1
    taskToCarePlan.deleteRule = .nullifyDeleteRule

    let taskToSchedule = NSRelationshipDescription()
    taskToSchedule.name = "scheduleElements"
    taskToSchedule.destinationEntity = schedule
    taskToSchedule.isOptional = false
    taskToSchedule.minCount = 1
    taskToSchedule.maxCount = 0
    taskToSchedule.deleteRule = .cascadeDeleteRule

    let taskToOutcome = NSRelationshipDescription()
    taskToOutcome.name = "outcomes"
    taskToOutcome.destinationEntity = outcome
    taskToOutcome.isOptional = true
    taskToOutcome.minCount = 0
    taskToOutcome.maxCount = 0
    taskToOutcome.deleteRule = .cascadeDeleteRule

    let taskToHealth = NSRelationshipDescription()
    taskToHealth.name = "healthKitLinkage"
    taskToHealth.destinationEntity = healthLink
    taskToHealth.isOptional = true
    taskToHealth.minCount = 0
    taskToHealth.maxCount = 1
    taskToHealth.deleteRule = .cascadeDeleteRule

    let taskToNote = NSRelationshipDescription()
    taskToNote.name = "notes"
    taskToNote.destinationEntity = note
    taskToNote.isOptional = true
    taskToNote.minCount = 0
    taskToNote.maxCount = 0
    taskToNote.deleteRule = .cascadeDeleteRule

    let taskNextVersion = NSRelationshipDescription()
    taskNextVersion.name = "next"
    taskNextVersion.destinationEntity = task
    taskNextVersion.isOptional = true
    taskNextVersion.minCount = 0
    taskNextVersion.maxCount = 1
    taskNextVersion.deleteRule = .cascadeDeleteRule

    let taskPrevVersion = NSRelationshipDescription()
    taskPrevVersion.name = "previous"
    taskPrevVersion.destinationEntity = task
    taskPrevVersion.isOptional = true
    taskPrevVersion.minCount = 0
    taskPrevVersion.maxCount = 1
    taskPrevVersion.deleteRule = .nullifyDeleteRule

    // MARK: Schedule Relationships

    let scheduleToValue = NSRelationshipDescription()
    scheduleToValue.name = "targetValues"
    scheduleToValue.destinationEntity = outcomeValue
    scheduleToValue.isOptional = true
    scheduleToValue.minCount = 0
    scheduleToValue.maxCount = 0
    scheduleToValue.deleteRule = .cascadeDeleteRule

    let scheduleToTask = NSRelationshipDescription()
    scheduleToTask.name = "task"
    scheduleToTask.destinationEntity = task
    scheduleToTask.isOptional = true
    scheduleToTask.minCount = 0
    scheduleToTask.maxCount = 1
    scheduleToTask.deleteRule = .denyDeleteRule

    let scheduleToNote = NSRelationshipDescription()
    scheduleToNote.name = "notes"
    scheduleToNote.destinationEntity = note
    scheduleToNote.isOptional = true
    scheduleToNote.minCount = 0
    scheduleToNote.maxCount = 0
    scheduleToNote.deleteRule = .cascadeDeleteRule

    // MARK: Outcome Relationships

    let outcomeToTask = NSRelationshipDescription()
    outcomeToTask.name = "task"
    outcomeToTask.destinationEntity = task
    outcomeToTask.isOptional = true
    outcomeToTask.minCount = 0
    outcomeToTask.maxCount = 1
    outcomeToTask.deleteRule = .nullifyDeleteRule

    let outcomeToValue = NSRelationshipDescription()
    outcomeToValue.name = "values"
    outcomeToValue.destinationEntity = outcomeValue
    outcomeToValue.isOptional = true
    outcomeToValue.minCount = 0
    outcomeToValue.maxCount = 0
    outcomeToValue.deleteRule = .cascadeDeleteRule

    let outcomeToNote = NSRelationshipDescription()
    outcomeToNote.name = "notes"
    outcomeToNote.destinationEntity = note
    outcomeToNote.isOptional = true
    outcomeToNote.minCount = 0
    outcomeToNote.maxCount = 0
    outcomeToNote.deleteRule = .cascadeDeleteRule

    // MARK: OutcomeValue Relationships

    let outcomeValueToOutcome = NSRelationshipDescription()
    outcomeValueToOutcome.name = "outcome"
    outcomeValueToOutcome.destinationEntity = outcome
    outcomeValueToOutcome.isOptional = true
    outcomeValueToOutcome.minCount = 0
    outcomeValueToOutcome.maxCount = 1
    outcomeValueToOutcome.deleteRule = .nullifyDeleteRule

    let outcomeValueToSchedule = NSRelationshipDescription()
    outcomeValueToSchedule.name = "scheduleElement"
    outcomeValueToSchedule.destinationEntity = schedule
    outcomeValueToSchedule.isOptional = true
    outcomeValueToSchedule.minCount = 0
    outcomeValueToSchedule.maxCount = 1
    outcomeValueToSchedule.deleteRule = .nullifyDeleteRule

    let outcomeValueToNote = NSRelationshipDescription()
    outcomeValueToNote.name = "notes"
    outcomeValueToNote.destinationEntity = note
    outcomeValueToNote.isOptional = true
    outcomeValueToNote.minCount = 0
    outcomeValueToNote.maxCount = 0
    outcomeValueToNote.deleteRule = .cascadeDeleteRule

    // MARK: Note Relationships

    let noteToPatient = NSRelationshipDescription()
    noteToPatient.name = "patient"
    noteToPatient.destinationEntity = patient
    noteToPatient.isOptional = true
    noteToPatient.minCount = 0
    noteToPatient.maxCount = 1
    noteToPatient.deleteRule = .nullifyDeleteRule

    let noteToCarePlan = NSRelationshipDescription()
    noteToCarePlan.name = "plan"
    noteToCarePlan.destinationEntity = carePlan
    noteToCarePlan.isOptional = true
    noteToCarePlan.minCount = 0
    noteToCarePlan.maxCount = 1
    noteToCarePlan.deleteRule = .nullifyDeleteRule

    let noteToContact = NSRelationshipDescription()
    noteToContact.name = "contact"
    noteToContact.destinationEntity = contact
    noteToContact.isOptional = true
    noteToContact.minCount = 0
    noteToContact.maxCount = 1
    noteToContact.deleteRule = .nullifyDeleteRule

    let noteToTask = NSRelationshipDescription()
    noteToTask.name = "task"
    noteToTask.destinationEntity = task
    noteToTask.isOptional = true
    noteToTask.minCount = 0
    noteToTask.maxCount = 0
    noteToTask.deleteRule = .nullifyDeleteRule

    let noteToOutcome = NSRelationshipDescription()
    noteToOutcome.name = "outcome"
    noteToOutcome.destinationEntity = outcome
    noteToOutcome.isOptional = true
    noteToOutcome.minCount = 0
    noteToOutcome.maxCount = 1
    noteToOutcome.deleteRule = .nullifyDeleteRule

    let noteToOutcomeValue = NSRelationshipDescription()
    noteToOutcomeValue.name = "response"
    noteToOutcomeValue.destinationEntity = outcomeValue
    noteToOutcomeValue.isOptional = true
    noteToOutcomeValue.minCount = 0
    noteToOutcomeValue.maxCount = 1
    noteToOutcomeValue.deleteRule = .nullifyDeleteRule

    let noteToSchedule = NSRelationshipDescription()
    noteToSchedule.name = "scheduleElement"
    noteToSchedule.destinationEntity = schedule
    noteToSchedule.isOptional = true
    noteToSchedule.minCount = 0
    noteToSchedule.maxCount = 1
    noteToSchedule.deleteRule = .nullifyDeleteRule

    let noteToChildNote = NSRelationshipDescription()
    noteToChildNote.name = "notes"
    noteToChildNote.destinationEntity = note
    noteToChildNote.isOptional = true
    noteToChildNote.minCount = 0
    noteToChildNote.maxCount = 0
    noteToChildNote.deleteRule = .cascadeDeleteRule

    let noteToParentNote = NSRelationshipDescription()
    noteToParentNote.name = "parentNote"
    noteToParentNote.destinationEntity = note
    noteToParentNote.isOptional = true
    noteToParentNote.minCount = 0
    noteToParentNote.maxCount = 1
    noteToParentNote.deleteRule = .nullifyDeleteRule

    // MARK: Name Relationships

    let nameToPatient = NSRelationshipDescription()
    nameToPatient.name = "patient"
    nameToPatient.destinationEntity = patient
    nameToPatient.isOptional = true
    nameToPatient.minCount = 0
    nameToPatient.maxCount = 1
    nameToPatient.deleteRule = .denyDeleteRule

    let nameToContact = NSRelationshipDescription()
    nameToContact.name = "contact"
    nameToContact.destinationEntity = contact
    nameToContact.isOptional = true
    nameToContact.minCount = 0
    nameToContact.maxCount = 1
    nameToContact.deleteRule = .denyDeleteRule

    let nameToPhoneticName = NSRelationshipDescription()
    nameToPhoneticName.name = "phoneticRepresentation"
    nameToPhoneticName.destinationEntity = name
    nameToPhoneticName.isOptional = true
    nameToPhoneticName.minCount = 0
    nameToPhoneticName.maxCount = 1
    nameToPhoneticName.deleteRule = .cascadeDeleteRule

    let nameToParentName = NSRelationshipDescription()
    nameToParentName.name = "parent"
    nameToParentName.destinationEntity = name
    nameToParentName.isOptional = true
    nameToParentName.minCount = 0
    nameToParentName.maxCount = 1
    nameToParentName.deleteRule = .nullifyDeleteRule

    // MARK: Address Relationships

    let addressToContact = NSRelationshipDescription()
    addressToContact.name = "contact"
    addressToContact.destinationEntity = contact
    addressToContact.isOptional = false
    addressToContact.minCount = 1
    addressToContact.maxCount = 1
    addressToContact.deleteRule = .nullifyDeleteRule

    // MARK: HealthKitLinkage Relationships

    let healthToTask = NSRelationshipDescription()
    healthToTask.name = "task"
    healthToTask.destinationEntity = task
    healthToTask.isOptional = false
    healthToTask.minCount = 1
    healthToTask.maxCount = 1
    healthToTask.deleteRule = .nullifyDeleteRule

    // MARK: Inverse Relationships

    patientToCarePlan.inverseRelationship = carePlanToPatient
    patientToName.inverseRelationship = nameToPatient
    patientToNote.inverseRelationship = noteToPatient
    patientNextVersion.inverseRelationship = patientPrevVersion
    patientPrevVersion.inverseRelationship = patientNextVersion

    carePlanToPatient.inverseRelationship = patientToCarePlan
    carePlanToContact.inverseRelationship = contactToCarePlan
    carePlanToTask.inverseRelationship = taskToCarePlan
    carePlanToNote.inverseRelationship = noteToCarePlan
    carePlanNextVersion.inverseRelationship = carePlanPrevVersion
    carePlanPrevVersion.inverseRelationship = carePlanNextVersion

    contactToCarePlan.inverseRelationship = carePlanToContact
    contactToAddress.inverseRelationship = addressToContact
    contactToName.inverseRelationship = nameToContact
    contactToNote.inverseRelationship = noteToContact
    contactNextVersion.inverseRelationship = contactPrevVersion
    contactPrevVersion.inverseRelationship = contactNextVersion

    taskToCarePlan.inverseRelationship = carePlanToTask
    taskToNote.inverseRelationship = noteToTask
    taskToOutcome.inverseRelationship = outcomeToTask
    taskToHealth.inverseRelationship = healthToTask
    taskToSchedule.inverseRelationship = scheduleToTask
    taskNextVersion.inverseRelationship = taskPrevVersion
    taskPrevVersion.inverseRelationship = taskNextVersion

    outcomeToTask.inverseRelationship = taskToOutcome
    outcomeToValue.inverseRelationship = outcomeValueToOutcome
    outcomeToNote.inverseRelationship = noteToOutcome

    outcomeValueToOutcome.inverseRelationship = outcomeToValue
    outcomeValueToSchedule.inverseRelationship = scheduleToValue
    outcomeValueToNote.inverseRelationship = noteToOutcomeValue

    noteToPatient.inverseRelationship = patientToNote
    noteToCarePlan.inverseRelationship = carePlanToNote
    noteToContact.inverseRelationship = contactToNote
    noteToTask.inverseRelationship = taskToNote
    noteToOutcome.inverseRelationship = outcomeToNote
    noteToOutcomeValue.inverseRelationship = outcomeValueToNote
    noteToSchedule.inverseRelationship = scheduleToNote
    noteToChildNote.inverseRelationship = noteToParentNote
    noteToParentNote.inverseRelationship = noteToChildNote

    nameToPatient.inverseRelationship = patientToName
    nameToContact.inverseRelationship = contactToName
    nameToPhoneticName.inverseRelationship = nameToParentName
    nameToParentName.inverseRelationship = nameToPhoneticName

    scheduleToValue.inverseRelationship = outcomeValueToSchedule
    scheduleToTask.inverseRelationship = taskToSchedule
    scheduleToNote.inverseRelationship = noteToSchedule

    addressToContact.inverseRelationship = contactToAddress

    healthToTask.inverseRelationship = taskToHealth

    // Add relationship properties to entities

    patient.properties += [
        patientToCarePlan, patientToName, patientToNote,
        patientNextVersion, patientPrevVersion
    ]

    carePlan.properties += [
        carePlanToPatient, carePlanToNote, carePlanToContact,
        carePlanToTask, carePlanNextVersion, carePlanPrevVersion
    ]

    contact.properties += [
        contactToCarePlan, contactToNote, contactToName,
        contactToAddress, contactNextVersion, contactPrevVersion
    ]

    task.properties += [taskToCarePlan, taskToOutcome, taskToHealth, taskToSchedule, taskToNote, taskNextVersion, taskPrevVersion]

    outcome.properties += [outcomeToTask, outcomeToValue, outcomeToNote]

    outcomeValue.properties += [outcomeValueToOutcome, outcomeValueToSchedule, outcomeValueToNote]

    schedule.properties += [scheduleToTask, scheduleToNote, scheduleToValue]

    address.properties += [addressToContact]

    healthLink.properties += [healthToTask]

    name.properties += [nameToPatient, nameToContact, nameToPhoneticName, nameToParentName]

    note.properties += [
        noteToPatient, noteToCarePlan, noteToContact, noteToTask, noteToSchedule,
        noteToOutcome, noteToOutcomeValue, noteToChildNote, noteToParentNote
    ]

    managedObjectModel.entities = [
        patient, carePlan, contact, task, outcome,
        outcomeValue, schedule, note, name, address,
        healthLink, clock
    ]

    return managedObjectModel
}

// MARK: Entities

private func makePatientEntity() -> NSEntityDescription {
    let patientEntity = NSEntityDescription()
    patientEntity.name = String(describing: OCKCDPatient.self)
    patientEntity.managedObjectClassName = String(describing: OCKCDPatient.self)

    let birthday = NSAttributeDescription()
    birthday.name = "birthday"
    birthday.attributeType = .dateAttributeType
    birthday.isOptional = true

    let sex = NSAttributeDescription()
    sex.name = "sex"
    sex.attributeType = .stringAttributeType
    sex.isOptional = true

    let allergies = NSAttributeDescription()
    allergies.name = "allergies"
    allergies.attributeType = .transformableAttributeType
    allergies.valueTransformerName = secureUnarchiver
    allergies.isOptional = true

    patientEntity.properties = makeObjectAttributes() + makeVersionedAttributes() + [birthday, sex, allergies]
    patientEntity.uniquenessConstraints = makeUniquenessConstraints()
    return patientEntity
}

private func makeCarePlanEntity() -> NSEntityDescription {
    let planEntity = NSEntityDescription()
    planEntity.name = String(describing: OCKCDCarePlan.self)
    planEntity.managedObjectClassName = String(describing: OCKCDCarePlan.self)

    let title = NSAttributeDescription()
    title.name = "title"
    title.attributeType = .stringAttributeType
    title.isOptional = false

    planEntity.properties = makeObjectAttributes() + makeVersionedAttributes() + [title]
    planEntity.uniquenessConstraints = makeUniquenessConstraints()

    return planEntity
}

private func makeContactEntity() -> NSEntityDescription {
    let contactEntity = NSEntityDescription()
    contactEntity.name = String(describing: OCKCDContact.self)
    contactEntity.managedObjectClassName = String(describing: OCKCDContact.self)

    let organization = NSAttributeDescription()
    organization.name = "organization"
    organization.attributeType = .stringAttributeType
    organization.isOptional = true

    let title = NSAttributeDescription()
    title.name = "title"
    title.attributeType = .stringAttributeType
    title.isOptional = true

    let role = NSAttributeDescription()
    role.name = "role"
    role.attributeType = .stringAttributeType
    role.isOptional = true

    let category = NSAttributeDescription()
    category.name = "category"
    category.attributeType = .stringAttributeType
    category.isOptional = true

    let email = NSAttributeDescription()
    email.name = "emailAddressesDictionary"
    email.attributeType = .transformableAttributeType
    email.isOptional = true
    email.valueTransformerName = secureUnarchiver

    let message = NSAttributeDescription()
    message.name = "messagingNumbersDictionary"
    message.attributeType = .transformableAttributeType
    message.isOptional = true
    message.valueTransformerName = secureUnarchiver

    let phone = NSAttributeDescription()
    phone.name = "phoneNumbersDictionary"
    phone.attributeType = .transformableAttributeType
    phone.isOptional = true
    phone.valueTransformerName = secureUnarchiver

    let other = NSAttributeDescription()
    other.name = "otherContactInfoDictionary"
    other.attributeType = .transformableAttributeType
    other.isOptional = true
    other.valueTransformerName = secureUnarchiver

    contactEntity.properties = makeObjectAttributes() + makeVersionedAttributes() + [
        organization, title, role, category, email, message, phone, other
    ]
    contactEntity.uniquenessConstraints = makeUniquenessConstraints()

    return contactEntity
}

private func makeTaskEntity() -> NSEntityDescription {
    let taskEntity = NSEntityDescription()
    taskEntity.name = String(describing: OCKCDTask.self)
    taskEntity.managedObjectClassName = String(describing: OCKCDTask.self)

    let title = NSAttributeDescription()
    title.name = "title"
    title.attributeType = .stringAttributeType
    title.isOptional = true

    let instructions = NSAttributeDescription()
    instructions.name = "instructions"
    instructions.attributeType = .stringAttributeType
    instructions.isOptional = true

    let impactsAdherence = NSAttributeDescription()
    impactsAdherence.name = "impactsAdherence"
    impactsAdherence.attributeType = .booleanAttributeType
    impactsAdherence.isOptional = false
    impactsAdherence.defaultValue = true

    taskEntity.properties = makeObjectAttributes() + makeVersionedAttributes() + [
        title, instructions, impactsAdherence
    ]
    taskEntity.uniquenessConstraints = makeUniquenessConstraints()

    return taskEntity
}

private func makeScheduleEntity() -> NSEntityDescription {
    let scheduleEntity = NSEntityDescription()
    scheduleEntity.name = String(describing: OCKCDScheduleElement.self)
    scheduleEntity.managedObjectClassName = String(describing: OCKCDScheduleElement.self)

    let text = NSAttributeDescription()
    text.name = "text"
    text.attributeType = .stringAttributeType
    text.isOptional = true

    let duration = NSAttributeDescription()
    duration.name = "durationInSeconds"
    duration.attributeType = .doubleAttributeType
    duration.isOptional = false
    duration.defaultValue = 0

    let isAllDay = NSAttributeDescription()
    isAllDay.name = "isAllDay"
    isAllDay.attributeType = .booleanAttributeType
    isAllDay.isOptional = false
    isAllDay.defaultValue = false

    let start = NSAttributeDescription()
    start.name = "startDate"
    start.attributeType = .dateAttributeType
    start.isOptional = false

    let end = NSAttributeDescription()
    end.name = "endDate"
    end.attributeType = .dateAttributeType
    end.isOptional = true

    let seconds = NSAttributeDescription()
    seconds.name = "secondsInterval"
    seconds.attributeType = .integer64AttributeType
    seconds.isOptional = false
    seconds.defaultValue = 0

    let minutes = NSAttributeDescription()
    minutes.name = "minutesInterval"
    minutes.attributeType = .integer64AttributeType
    minutes.isOptional = false
    minutes.defaultValue = 0

    let hours = NSAttributeDescription()
    hours.name = "hoursInterval"
    hours.attributeType = .integer64AttributeType
    hours.isOptional = false
    hours.defaultValue = 0

    let days = NSAttributeDescription()
    days.name = "daysInterval"
    days.attributeType = .integer64AttributeType
    days.isOptional = false
    days.defaultValue = 0

    let weeks = NSAttributeDescription()
    weeks.name = "weeksInterval"
    weeks.attributeType = .integer64AttributeType
    weeks.isOptional = false
    weeks.defaultValue = 0

    let months = NSAttributeDescription()
    months.name = "monthsInterval"
    months.attributeType = .integer64AttributeType
    months.isOptional = false
    months.defaultValue = 0

    let years = NSAttributeDescription()
    years.name = "yearsInterval"
    years.attributeType = .integer64AttributeType
    years.isOptional = false
    years.defaultValue = 0

    scheduleEntity.properties = [
        text, duration, isAllDay, start, end, seconds,
        minutes, hours, days, weeks, months, years
    ]

    return scheduleEntity
}

private func makeOutcomeEntity() -> NSEntityDescription {
    let outcomeEntity = NSEntityDescription()
    outcomeEntity.name = String(describing: OCKCDOutcome.self)
    outcomeEntity.managedObjectClassName = String(describing: OCKCDOutcome.self)

    let index = NSAttributeDescription()
    index.name = "taskOccurrenceIndex"
    index.attributeType = .integer64AttributeType
    index.isOptional = false

    let date = NSAttributeDescription()
    date.name = "date"
    date.attributeType = .dateAttributeType
    date.isOptional = false

    let deletedDate = NSAttributeDescription()
    deletedDate.name = "deletedDate"
    deletedDate.attributeType = .dateAttributeType
    deletedDate.isOptional = true

    outcomeEntity.properties = makeObjectAttributes() + [index, date, deletedDate]
    outcomeEntity.uniquenessConstraints = makeUniquenessConstraints()

    return outcomeEntity
}

private func makeOutcomeValueEntity() -> NSEntityDescription {
    let valueEntity = NSEntityDescription()
    valueEntity.name = String(describing: OCKCDOutcomeValue.self)
    valueEntity.managedObjectClassName = String(describing: OCKCDOutcomeValue.self)

    let kind = NSAttributeDescription()
    kind.name = "kind"
    kind.attributeType = .stringAttributeType
    kind.isOptional = true

    let units = NSAttributeDescription()
    units.name = "units"
    units.attributeType = .stringAttributeType
    units.isOptional = true

    let index = NSAttributeDescription()
    index.name = "index"
    index.attributeType = .integer64AttributeType
    index.isOptional = true

    let type = NSAttributeDescription()
    type.name = "typeString"
    type.attributeType = .stringAttributeType
    type.isOptional = false

    let text = NSAttributeDescription()
    text.name = "textValue"
    text.attributeType = .stringAttributeType
    text.isOptional = true

    let binary = NSAttributeDescription()
    binary.name = "binaryValue"
    binary.attributeType = .binaryDataAttributeType
    binary.isOptional = true

    let bool = NSAttributeDescription()
    bool.name = "booleanValue"
    bool.attributeType = .booleanAttributeType
    bool.isOptional = true

    let integer = NSAttributeDescription()
    integer.name = "integerValue"
    integer.attributeType = .integer64AttributeType
    integer.isOptional = true

    let double = NSAttributeDescription()
    double.name = "doubleValue"
    double.attributeType = .doubleAttributeType
    double.isOptional = true

    let date = NSAttributeDescription()
    date.name = "dateValue"
    date.attributeType = .dateAttributeType
    date.isOptional = true

    valueEntity.properties = makeObjectAttributes() +
        [kind, units, index, type, text, binary, bool, integer, double, date]
    return valueEntity
}

private func makeNoteEntity() -> NSEntityDescription {
    let noteEntity = NSEntityDescription()
    noteEntity.name = String(describing: OCKCDNote.self)
    noteEntity.managedObjectClassName = String(describing: OCKCDNote.self)

    let author = NSAttributeDescription()
    author.name = "author"
    author.attributeType = .stringAttributeType
    author.isOptional = true

    let content = NSAttributeDescription()
    content.name = "content"
    content.attributeType = .stringAttributeType
    content.isOptional = true

    let title = NSAttributeDescription()
    title.name = "title"
    title.attributeType = .stringAttributeType
    title.isOptional = true

    noteEntity.properties = makeObjectAttributes() + [author, content, title]
    return noteEntity
}

private func makePersonNameEntity() -> NSEntityDescription {
    let nameEntity = NSEntityDescription()
    nameEntity.name = String(describing: OCKCDPersonName.self)
    nameEntity.managedObjectClassName = String(describing: OCKCDPersonName.self)

    let prefix = NSAttributeDescription()
    prefix.name = "namePrefix"
    prefix.attributeType = .stringAttributeType
    prefix.isOptional = true

    let given = NSAttributeDescription()
    given.name = "givenName"
    given.attributeType = .stringAttributeType
    given.isOptional = true

    let middle = NSAttributeDescription()
    middle.name = "middleName"
    middle.attributeType = .stringAttributeType
    middle.isOptional = true

    let family = NSAttributeDescription()
    family.name = "familyName"
    family.attributeType = .stringAttributeType
    family.isOptional = true

    let suffix = NSAttributeDescription()
    suffix.name = "nameSuffix"
    suffix.attributeType = .stringAttributeType
    suffix.isOptional = true

    let nickname = NSAttributeDescription()
    nickname.name = "nickname"
    nickname.attributeType = .stringAttributeType
    nickname.isOptional = true

    nameEntity.properties = [prefix, given, middle, family, suffix, nickname]
    return nameEntity
}

private func makeAddressEntity() -> NSEntityDescription {
    let addressEntity = NSEntityDescription()
    addressEntity.name = String(describing: OCKCDPostalAddress.self)
    addressEntity.managedObjectClassName = String(describing: OCKCDPostalAddress.self)

    let street = NSAttributeDescription()
    street.name = "street"
    street.attributeType = .stringAttributeType
    street.isOptional = false
    street.defaultValue = ""

    let subLocality = NSAttributeDescription()
    subLocality.name = "subLocality"
    subLocality.attributeType = .stringAttributeType
    subLocality.isOptional = false
    subLocality.defaultValue = ""

    let city = NSAttributeDescription()
    city.name = "city"
    city.attributeType = .stringAttributeType
    city.isOptional = false
    city.defaultValue = ""

    let subAdminArea = NSAttributeDescription()
    subAdminArea.name = "subAdministrativeArea"
    subAdminArea.attributeType = .stringAttributeType
    subAdminArea.isOptional = false
    subAdminArea.defaultValue = ""

    let state = NSAttributeDescription()
    state.name = "state"
    state.attributeType = .stringAttributeType
    state.isOptional = false
    state.defaultValue = ""

    let zip = NSAttributeDescription()
    zip.name = "postalCode"
    zip.attributeType = .stringAttributeType
    zip.isOptional = false
    zip.defaultValue = ""

    let country = NSAttributeDescription()
    country.name = "country"
    country.attributeType = .stringAttributeType
    country.isOptional = false
    country.defaultValue = ""

    let isoCode = NSAttributeDescription()
    isoCode.name = "isoCountryCode"
    isoCode.attributeType = .stringAttributeType
    isoCode.isOptional = false
    isoCode.defaultValue = ""

    addressEntity.properties = [street, subLocality, city, subAdminArea, state, zip, country, isoCode]

    return addressEntity
}

private func makeHealthKitLinkageEntity() -> NSEntityDescription {
    let linkEntity = NSEntityDescription()
    linkEntity.name = String(describing: OCKCDHealthKitLinkage.self)
    linkEntity.managedObjectClassName = String(describing: OCKCDHealthKitLinkage.self)

    let quanityID = NSAttributeDescription()
    quanityID.name = "quantityIdentifier"
    quanityID.attributeType = .stringAttributeType
    quanityID.isOptional = false

    let quantityType = NSAttributeDescription()
    quantityType.name = "quantityType"
    quantityType.attributeType = .stringAttributeType
    quantityType.isOptional = false

    let unit = NSAttributeDescription()
    unit.name = "unitString"
    unit.attributeType = .stringAttributeType
    unit.isOptional = false

    linkEntity.properties = [quanityID, quantityType, unit]

    return linkEntity
}

private func makeClockEntity() -> NSEntityDescription {

    let clockEntity = NSEntityDescription()
    clockEntity.name = String(describing: OCKCDClock.self)
    clockEntity.managedObjectClassName = String(describing: OCKCDClock.self)

    let uuid = NSAttributeDescription()
    uuid.name = "uuid"
    uuid.attributeType = .UUIDAttributeType
    uuid.isOptional = false

    let vectorClock = NSAttributeDescription()
    vectorClock.name = "vectorClock"
    vectorClock.attributeType = .transformableAttributeType
    vectorClock.valueTransformerName = secureUnarchiver
    vectorClock.isOptional = false

    clockEntity.properties = [uuid, vectorClock]

    return clockEntity
}
// MARK: Attributes

private func makeVersionedAttributes() -> [NSAttributeDescription] {
    let id = NSAttributeDescription()
    id.name = "id"
    id.attributeType = .stringAttributeType
    id.isOptional = false

    let deletedDate = NSAttributeDescription()
    deletedDate.name = "deletedDate"
    deletedDate.attributeType = .dateAttributeType
    deletedDate.isOptional = true

    let effectiveDate = NSAttributeDescription()
    effectiveDate.name = "effectiveDate"
    effectiveDate.attributeType = .dateAttributeType
    effectiveDate.isOptional = false

    return [id, effectiveDate, deletedDate]
}

private func makeObjectAttributes() -> [NSAttributeDescription] {
    let allowsMissingRelationships = NSAttributeDescription()
    allowsMissingRelationships.name = "allowsMissingRelationships"
    allowsMissingRelationships.attributeType = .booleanAttributeType
    allowsMissingRelationships.defaultValue = true
    allowsMissingRelationships.isOptional = false

    let asset = NSAttributeDescription()
    asset.name = "asset"
    asset.attributeType = .stringAttributeType
    asset.isOptional = true
    asset.defaultValue = nil

    let createdDate = NSAttributeDescription()
    createdDate.name = "createdDate"
    createdDate.attributeType = .dateAttributeType
    createdDate.isOptional = false

    let groupIdentifier = NSAttributeDescription()
    groupIdentifier.name = "groupIdentifier"
    groupIdentifier.attributeType = .stringAttributeType
    groupIdentifier.isOptional = true

    let uuid = NSAttributeDescription()
    uuid.name = "uuid"
    uuid.attributeType = .UUIDAttributeType
    uuid.isOptional = false

    let logicalClock = NSAttributeDescription()
    logicalClock.name = "logicalClock"
    logicalClock.attributeType = .integer64AttributeType
    logicalClock.isOptional = false

    let remoteID = NSAttributeDescription()
    remoteID.name = "remoteID"
    remoteID.attributeType = .stringAttributeType
    remoteID.isOptional = true

    let source = NSAttributeDescription()
    source.name = "source"
    source.attributeType = .stringAttributeType
    source.isOptional = true

    let tags = NSAttributeDescription()
    tags.name = "tags"
    tags.attributeType = .transformableAttributeType
    tags.valueTransformerName = secureUnarchiver
    tags.isOptional = true

    let updatedDate = NSAttributeDescription()
    updatedDate.name = "updatedDate"
    updatedDate.attributeType = .dateAttributeType
    updatedDate.isOptional = true

    let userInfo = NSAttributeDescription()
    userInfo.name = "userInfo"
    userInfo.attributeType = .transformableAttributeType
    userInfo.isOptional = true
    userInfo.valueTransformerName = secureUnarchiver

    let schema = NSAttributeDescription()
    schema.name = "schemaVersion"
    schema.attributeType = .stringAttributeType
    schema.isOptional = false
    schema.defaultValue = schemaVersion.description

    let timezone = NSAttributeDescription()
    timezone.name = "timezoneIdentifier"
    timezone.attributeType = .stringAttributeType
    timezone.isOptional = false

    return [allowsMissingRelationships, asset, createdDate, schema,
            groupIdentifier, uuid, logicalClock, remoteID, source,
            tags, updatedDate, userInfo, timezone]
}

func makeUniquenessConstraints() -> [[Any]] {
    [["uuid"]]
}

let sharedManagedObjectModel = makeManagedObjectModel()

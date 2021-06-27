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

import CoreData
import Foundation

class OCKStoreMigration2_0To2_1Policy: NSEntityMigrationPolicy {

    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager) throws {

        let dInstance = NSEntityDescription.insertNewObject(
            forEntityName: sInstance.entity.name!,
            into: manager.destinationContext
        )

        // This allows us to look up the destination instance using
        // the source instance during the relationship establishment
        // phase later on.
        manager.associate(
            sourceInstance: sInstance,
            withDestinationInstance: dInstance,
            for: mapping
        )

        // Copy all the primitive attributes from the source to the destination.
        // Almost all of the attributes have the same names. Note that this does
        // not capture any relationships - we have to tackle that separately.
        for key in sInstance.entity.attributesByName.keys {

            // `allowsMissingRelationships` was removed from all types
            if key == "allowsMissingRelationships" {
                continue
            }

            // Tags were changed from a Transformable array of strings to a set
            // of OCKCDTags.
            if key == "tags" {
                guard let tagsValue = sInstance.value(forKey: key) else {
                    continue
                }

                var tagObjects = Set<NSManagedObject>()

                for tag in tagsValue as! [String] {

                    let request = NSFetchRequest<NSManagedObject>(entityName: "OCKCDTag")
                    request.predicate = NSPredicate(format: "title == %@", tag)
                    request.fetchLimit = 1

                    let fetched = try manager.destinationContext.fetch(request)

                    if let existing = fetched.first {

                        tagObjects.insert(existing)

                    } else {

                        let object = NSEntityDescription.insertNewObject(
                            forEntityName: "OCKCDTag",
                            into: manager.destinationContext
                        )

                        object.setValue(tag, forKey: "title")

                        tagObjects.insert(object)
                    }
                }

                dInstance.setValue(tagObjects, forKey: "tags")
            }

            // Update the schema version to 2.1
            if key == "schemaVersion" {
                dInstance.setValue("2.1.0", forKey: key)
                continue
            }

            // OCKCDOutcome's `date` was renamed to `startDate`, and new
            // `endDate` and `deletedDate` attributes were added. The start
            // and end dates must be retrieved from the event associated with
            // the outcome. The deleted date will always be nil.
            if sInstance.entity.name == "OCKCDOutcome" && key == "date" {

                let task = sInstance.value(forKey: "task") as! NSManagedObject
                let elements = task.value(forKey: "scheduleElements") as! Set<NSManagedObject>
                let schedule = OCKSchedule(composing: elements.map(element))
                let occurrence = sInstance.value(forKey: "taskOccurrenceIndex") as! Int64
                let event = schedule[Int(occurrence)]

                dInstance.setValue(event.start, forKey: "startDate")
                dInstance.setValue(event.start, forKey: "effectiveDate")
                dInstance.setValue(event.end, forKey: "endDate")
                dInstance.setValue(nil, forKey: "deletedDate")

            } else {

                let value = sInstance.value(forKey: key)
                dInstance.setValue(value, forKey: key)
            }
        }

        // A `logicalClock` attribute was added to many of the objects.
        // For migration purposes, we set `logicalClock` to 0 to indicate
        // that they were the first items added to the database.
        if dInstance.entity.attributesByName.keys.contains("logicalClock") {
            dInstance.setValue(0, forKey: "logicalClock")
        }

        // A `uuid` attribute was added to many of the objects.
        // For migration purposes, we set `uuid` to a random value.
        if dInstance.entity.attributesByName.keys.contains("uuid") {
            dInstance.setValue(UUID(), forKey: "uuid")
        }
    }

    override func createRelationships(
        forDestination dInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager) throws {

        // Now we can deal with all of the relationships. Note that we can't
        // copy relationships over the same way that we did primitives. We need
        // to look up the corresponding related objects in the destination and
        // link them.
        let sInstance = manager.sourceInstances(
            forEntityMappingName: mapping.name,
            destinationInstances: [dInstance]
        ).first!

        // Add a set of knowledge elements to each entity
        let clock: NSManagedObject
        let request = NSFetchRequest<NSManagedObject>(entityName: "OCKCDClock")
        if let fetched = try manager.destinationContext.fetch(request).first {
            clock = fetched
        } else {
            let uuid = UUID()
            clock = NSEntityDescription.insertNewObject(
                forEntityName: "OCKCDClock",
                into: manager.destinationContext)
            clock.setValue([uuid: 1], forKey: "vectorClock")
            clock.setValue(uuid, forKey: "uuid")
        }
        let uuid = clock.value(forKey: "uuid") as! UUID
        let element = NSEntityDescription.insertNewObject(
            forEntityName: "OCKCDKnowledgeElement",
            into: manager.destinationContext)
        element.setValue(1, forKey: "time")
        element.setValue(uuid, forKey: "uuid")

        dInstance.setValue(Set([element]), forKey: "knowledge")

        for (key, relationship) in sInstance.entity.relationshipsByName {

            guard let sValue = sInstance.value(forKey: key) else {
                continue
            }

            let relationEntity = "\(relationship.destinationEntity!.name!)"
            let relationMapping = "\(relationEntity)To\(relationEntity)"

            // Previous and next were upgraded from 1-to-1 to many-to-many.
            if key == "next" || key == "previous" {
                let sRelation = sValue as! NSManagedObject
                let dRelation = manager.destinationInstances(
                    forEntityMappingName: relationMapping,
                    sourceInstances: [sRelation]
                )
                dInstance.setValue(Set(dRelation), forKey: key)
                continue
            }

            if relationship.isToMany {
                let sRelations = sValue as! Set<NSManagedObject>
                let dRelations = manager.destinationInstances(
                    forEntityMappingName: relationMapping,
                    sourceInstances: Array(sRelations)
                )
                dInstance.setValue(Set(dRelations), forKey: key)
            } else {
                let sRelation = sValue as! NSManagedObject
                let dRelation = manager.destinationInstances(
                    forEntityMappingName: relationMapping,
                    sourceInstances: [sRelation]
                ).first!
                dInstance.setValue(dRelation, forKey: key)
            }
        }

        // An `id` property was added on to OCKCDOutcome
        if dInstance.entity.name == "OCKCDOutcome" {
            let task = dInstance.value(forKey: "task") as! NSManagedObject
            let taskUUID = task.value(forKey: "uuid") as! UUID
            let index = dInstance.value(forKey: "taskOccurrenceIndex") as! Int64
            let id = taskUUID.uuidString + "_\(index)"
            dInstance.setValue(id, forKey: "id")
        }
    }


    private func element(from object: NSManagedObject) -> OCKScheduleElement {

        // We're only using these elements date extraction purposes, so we don't
        // need to bother with populating fields like text or target values.

        let start = object.primitiveValue(forKey: "startDate") as! Date

        let end = object.primitiveValue(forKey: "endDate") as? Date

        let duration = object.primitiveValue(forKey: "durationInSeconds") as! Double

        let interval = DateComponents(
            year: Int(object.primitiveValue(forKey: "yearsInterval") as! Int64),
            month: Int(object.primitiveValue(forKey: "monthsInterval") as! Int64),
            day: Int(object.primitiveValue(forKey: "daysInterval") as! Int64),
            hour: Int(object.primitiveValue(forKey: "hoursInterval") as! Int64),
            minute: Int(object.primitiveValue(forKey: "minutesInterval") as! Int64),
            second: Int(object.primitiveValue(forKey: "secondsInterval") as! Int64),
            weekOfYear: Int(object.primitiveValue(forKey: "weeksInterval") as! Int64)
        )
        
        let element = OCKScheduleElement(
            start: start,
            end: end,
            interval: interval,
            text: nil,
            targetValues: [],
            duration: .seconds(duration)
        )

        return element
    }
}

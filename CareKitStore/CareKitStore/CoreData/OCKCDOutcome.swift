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
import Foundation

@objc(OCKCDOutcome)
class OCKCDOutcome: OCKCDVersionedObject {
    @NSManaged var taskOccurrenceIndex: Int64
    @NSManaged var task: OCKCDTask
    @NSManaged var values: Set<OCKCDOutcomeValue>
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date
    
    convenience init(outcome: OCKOutcome, context: NSManagedObjectContext) {
        self.init(entity: Self.entity(), insertInto: context)
        self.copyVersionedValue(value: outcome, context: context)

        let task: OCKCDTask = try! context.fetchObject(uuid: outcome.taskUUID)
        let schedule = OCKSchedule(composing: task.scheduleElements.map { $0.makeValue() })
        let event = schedule[outcome.taskOccurrenceIndex]

        self.task = task
        self.taskOccurrenceIndex = Int64(outcome.taskOccurrenceIndex)
        self.startDate = event.start
        self.endDate = event.end
        self.values = Set(outcome.values.map {
            OCKCDOutcomeValue(value: $0, context: context)
        })
    }

    override func makeValue() -> OCKVersionedObjectCompatible {
        makeOutcome()
    }
    
    func makeOutcome() -> OCKOutcome {

        var outcome = OCKOutcome(
            taskUUID: task.uuid,
            taskOccurrenceIndex: Int(taskOccurrenceIndex),
            values: values.map { $0.makeValue() }
        )

        outcome.copyVersionedValues(from: self)
        
        return outcome
    }

    // Assure that any other outcomes with the same task and occurrence
    // have been deleted already.
    override func validateForInsert() throws {
        try super.validateForInsert()

        guard let context = managedObjectContext else {
            return
        }

        let request = NSFetchRequest<OCKCDObject>(entityName: entity.name!)

        request.predicate = NSPredicate(
            format: "SELF != %@ AND %K == %@ AND %K == %lld AND %K.@count == 0 AND %K == nil",
            self,
            #keyPath(OCKCDOutcome.task), task,
            #keyPath(OCKCDOutcome.taskOccurrenceIndex), taskOccurrenceIndex,
            #keyPath(OCKCDOutcome.next),
            #keyPath(OCKCDOutcome.deletedDate)
        )

        let duplicates = try context.count(for: request)

        if duplicates > 0 {
            throw OCKStoreError.addFailed(reason: "A duplicate outcome exists")
        }
    }
}

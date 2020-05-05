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
class OCKCDOutcome: OCKCDObject {
    @NSManaged var taskOccurrenceIndex: Int64
    @NSManaged var task: OCKCDTask
    @NSManaged var values: Set<OCKCDOutcomeValue>
    @NSManaged var date: Date
    @NSManaged var deletedDate: Date?

    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \OCKCDOutcome.createdDate, ascending: false)]
    }

    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateNoDuplicates()
    }

    private func validateNoDuplicates() throws {
        guard let context = managedObjectContext else { throw OCKStoreError.invalidValue(reason: "Context was nil!") }
        let predicate = NSPredicate(format: "%K == %@ AND %K == %lld AND %K == nil AND self != %@",
                                    #keyPath(OCKCDOutcome.task), task,
                                    #keyPath(OCKCDOutcome.taskOccurrenceIndex), Int64(taskOccurrenceIndex),
                                    #keyPath(OCKCDOutcome.deletedDate),
                                    self)
        let request = NSFetchRequest<OCKCDOutcome>(entityName: String(describing: OCKCDOutcome.self))
        request.predicate = predicate
        let numberOfDuplicates = try context.count(for: request)
        if numberOfDuplicates > 0 {
            throw OCKStoreError.invalidValue(reason: "Duplicate outcome!")
        }
    }
}

extension OCKCDOutcome {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        values = Set()
    }
}

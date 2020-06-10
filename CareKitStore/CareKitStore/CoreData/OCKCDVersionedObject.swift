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

class OCKCDVersionedObject: OCKCDObject {
    @NSManaged var id: String
    @NSManaged var isDirty: Bool
    @NSManaged var previous: OCKCDVersionedObject?
    @NSManaged var allowsMissingRelationships: Bool
    @NSManaged var effectiveDate: Date
    @NSManaged var deletedDate: Date?
    @NSManaged private(set) weak var next: OCKCDVersionedObject?

    var nextVersionUUID: UUID? {
        return next?.uuid
    }

    var previousVersionUUID: UUID? {
        return previous?.uuid
    }

    func validateRelationships() throws {
    }

    static var notDeletedPredicate: NSPredicate {
        NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedDate))
    }

    static func headerPredicate(for ids: [String]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.id), ids),
            headerPredicate()
        ])
    }

    static func headerPredicate() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            notDeletedPredicate,
            NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.next))
        ])
    }

    static func newestVersionPredicate(in interval: DateInterval) -> NSPredicate {
        let startsBeforeEndOfQuery = NSPredicate(format: "%K < %@",
                                                 #keyPath(OCKCDVersionedObject.effectiveDate),
                                                 interval.end as NSDate)

        let noNextVersion = NSPredicate(format: "%K == nil OR %K.effectiveDate >= %@",
                                        #keyPath(OCKCDVersionedObject.next),
                                        #keyPath(OCKCDVersionedObject.next),
                                        interval.end as NSDate)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            startsBeforeEndOfQuery,
            noNextVersion
        ])
    }
    
    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateRelationships()
    }

    override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateRelationships()
    }

    func copyVersionInfo(from other: OCKVersionedObjectCompatible) {
        id = other.id
        deletedDate = other.deletedDate
        effectiveDate = other.effectiveDate
        copyValues(from: other)
    }
}

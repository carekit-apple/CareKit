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

import Foundation
import CoreData

class OCKCDVersionedObject: OCKCDObject, OCKCDManageable, OCKVersionable {
    @NSManaged var identifier: String
    @NSManaged var previous: OCKCDVersionedObject?
    @NSManaged var allowsMissingRelationships: Bool
    @NSManaged private(set) weak var next: OCKCDVersionedObject?
    
    var nextVersionID: OCKLocalVersionID? {
        return next?.localDatabaseID
    }
    
    var previousVersionID: OCKLocalVersionID? {
        return previous?.localDatabaseID
    }
    
    func validateRelationships() throws {
        
    }
    
    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \OCKCDVersionedObject.createdAt, ascending: false)]
    }
    
    static func fetchHead<T: OCKCDVersionedObject>(identifier: String, in context: NSManagedObjectContext) -> T? {
        return fetchFromStore(in: context, where: headerPredicate(for: [identifier])) { request in
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
        }.first as? T
    }
    
    static func fetchHeads<T: OCKCDVersionedObject>(identifiers: [String], in context: NSManagedObjectContext) -> [T] {
        return fetchFromStore(in: context, where: headerPredicate(for: identifiers)) { request in
            request.fetchLimit = identifiers.count
            request.returnsObjectsAsFaults = false
        }.compactMap { $0 as? T }
    }
    
    static func headerPredicate(for identifiers: [String]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.identifier), identifiers),
            headerPredicate()
        ])
    }
    
    static func headerPredicate() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.next)),
            NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedAt))
        ])
    }
    
    static func datePredicate(after startDate: Date?) -> NSPredicate {
        guard let startDate = startDate else { return NSPredicate(value: true) }
        return NSPredicate(format: "%K <= %@", #keyPath(OCKCDVersionedObject.createdAt), startDate as NSDate)
    }
    
    static func datePredicate(before endDate: Date?) -> NSPredicate {
        guard let endDate = endDate else { return NSPredicate(value: true) }
        return NSPredicate(format: "%K >= %@", #keyPath(OCKCDVersionedObject.deletedAt), endDate as NSDate)
    }
    
    static func datePredicate(on date: Date?) -> NSPredicate {
        guard let date = date else { return NSPredicate(value: true) }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K <= %@", #keyPath(OCKCDVersionedObject.createdAt), date as NSDate),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedAt)),
                NSPredicate(format: "%K <= %@", #keyPath(OCKCDVersionedObject.deletedAt), date as NSDate)
            ])
        ])
    }
}

internal extension OCKCDVersionedObject {
    
    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateRelationships()
    }
    
    override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateRelationships()
    }
    
    func copyVersionInfo<T>(from other: T) where T: OCKVersionable & OCKObjectCompatible {
        identifier = other.identifier
        copyValues(from: other)
    }
}

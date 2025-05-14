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

import Foundation

protocol OCKQueryProtocol {

    /// An array of identifiers to match against.
    var ids: [String] { get }

    /// An array of version UUIDs to match against.
    var uuids: [UUID] { get }

    /// An array of group identifiers to match against.
    var groupIdentifiers: [String?] { get }

    /// An array of tags to match against. If an object's tags contains one or more of entries, it will match the query.
    var tags: [String] { get }

    /// An array of remoteIDs to match against. If an object's tags contains one or more of entries, it will match the query.
    /// Pass `nil` to match objects with no remoteID.
    var remoteIDs: [String?] { get }

    /// A date interval to match against. The newest version of the object available in the interval will be
    /// returned. If no interval is specified, all versions of the object will be returned.
    var dateInterval: DateInterval? { get }

    /// If set, the number of entries returned from the query will be limited to the specified value.
    var limit: Int? { get }

    /// A fetch offset to apply. Can be used in combination with `limit` to perform pagination of results.
    var offset: Int { get }
}

extension OCKQueryProtocol {

    /// A predicate for matching against common `OCKQuery` properties.
    func basicPredicate(enforceDateInterval: Bool) -> NSPredicate {
        var predicate = NSPredicate(format: "%K == nil", #keyPath(OCKCDVersionedObject.deletedDate))

        if let interval = dateInterval, enforceDateInterval {
            let intervalPredicate = OCKCDVersionedObject.newestVersionPredicate(in: interval)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, intervalPredicate])
        }

        if !ids.isEmpty {
            let idPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.id), ids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, idPredicate])
        }

        if !uuids.isEmpty {
            let objectPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.uuid), uuids)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, objectPredicate])
        }

        if !remoteIDs.isEmpty {
            predicate = predicate.including(remoteIDs, for: #keyPath(OCKCDObject.remoteID))
        }

        if !groupIdentifiers.isEmpty {
            predicate = predicate.including(
                groupIdentifiers,
                for: #keyPath(OCKCDObject.groupIdentifier))
        }

        if !tags.isEmpty {
            let tagsKey = #keyPath(OCKCDObject.tags)
            let titleKey = #keyPath(OCKCDTag.title)
            let tagPredicate = NSPredicate(
                format: "SUBQUERY(\(tagsKey), $tag, $tag.\(titleKey) IN %@).@count > 0", tags)
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, tagPredicate])
        }

        return predicate
    }

    func defaultSortDescriptors() -> [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \OCKCDObject.createdDate, ascending: false)]
    }
}

private extension NSPredicate {
    func including(_ identifiers: [String?], for keyPath: String) -> NSPredicate {
        let idPredicate = NSPredicate(format: "%K IN %@", keyPath, identifiers)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [self, idPredicate])
        let nilPredicate = NSPredicate(format: "%K == NIL", keyPath)
        let andNilPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [self, nilPredicate])
        let orNilPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicate, andNilPredicate])
        return identifiers.contains(nil) ? orNilPredicate : predicate
    }
}

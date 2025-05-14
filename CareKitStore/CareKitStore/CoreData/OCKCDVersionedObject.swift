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

import CoreData
import Foundation

class OCKCDVersionedObject: OCKCDObject {
    @NSManaged var id: String
    @NSManaged var effectiveDate: Date
    @NSManaged var deletedDate: Date?
    @NSManaged var next: Set<OCKCDVersionedObject>
    @NSManaged var previous: Set<OCKCDVersionedObject>

    var nextVersionUUIDs: [UUID] {
        return next.map(\.uuid)
    }

    var previousVersionUUIDs: [UUID] {
        return previous.map(\.uuid)
    }

    func copyVersionedValue(value: OCKVersionedObjectCompatible, context: NSManagedObjectContext) {
        id = value.id
        uuid = value.uuid
        deletedDate = value.deletedDate
        effectiveDate = value.effectiveDate
        createdDate = value.createdDate ?? createdDate
        updatedDate = value.updatedDate ?? updatedDate
        groupIdentifier = value.groupIdentifier
        tags = value.tags.map { Set($0.map { OCKCDTag.findOrCreate(title: $0, in: context) }) }
        source = value.source
        remoteID = value.remoteID
        userInfo = value.userInfo
        asset = value.asset
        timezoneIdentifier = value.timezone.identifier

        next = Set(value.nextVersionUUIDs.compactMap { uuid -> OCKCDVersionedObject? in
            let next: Self? = try? context.fetchObject(uuid: uuid)
            return next
        })

        previous = Set(value.previousVersionUUIDs.compactMap { uuid -> OCKCDVersionedObject? in
            let prev: Self? = try? context.fetchObject(uuid: uuid)
            return prev
        })

        notes = {
            guard let valueNotes = value.notes else { return nil }
            return Set(valueNotes.map {
                        OCKCDNote(note: $0, context: context)
            })
        }()
    }

    func makeValue() -> OCKVersionedObjectCompatible {
        fatalError("Must be implemented in subclasses!")
    }

    static func headerPredicate(_ values: [OCKVersionedObjectCompatible]) -> NSPredicate {
        NSPredicate(
            format: "%K.@count == 0 AND %K IN %@",
            #keyPath(OCKCDVersionedObject.next),
            #keyPath(OCKCDVersionedObject.id),
            values.map(\.id)
        )
    }

    static func newestVersionPredicate(in interval: DateInterval) -> NSPredicate {
        let startsBeforeEndOfQuery = NSPredicate(
            format: "%K < %@",
            #keyPath(OCKCDVersionedObject.effectiveDate),
            interval.end as NSDate
        )

        let noNextVersion = NSPredicate(
            format: "%K.@count == 0 OR SUBQUERY(%K, $version, $version.effectiveDate >= %@).@count > 0",
            #keyPath(OCKCDVersionedObject.next),
            #keyPath(OCKCDVersionedObject.next),
            interval.end as NSDate
        )

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            startsBeforeEndOfQuery,
            noNextVersion
        ])
    }
}

// MARK: Version Graph

extension OCKCDVersionedObject {

    /// Determines if this chain of versions should be considered deleted (not returned by queries).
    /// We find the most recent version of the object that has no conflicts, and check if its `deletedDate`
    /// is set or not. If it is set, then all previous versions of the object are considered deleted as well.
    ///
    /// A versioned object can be "undeleted" by appending a new version with a nil `deletedDate`.
    func newestVersionIsTombstone() -> Bool {
        let resolved = nonConflictedVersions()
        let last = resolved.last
        let isTombstone = last?.deletedDate != nil
        return isTombstone
    }

    /// Finds all nodes in the version graph where the `next` property is empty.
    /// This requires visiting every node in the entire version graph.
    func tips() -> Set<OCKCDVersionedObject> {
        let first = firstVersion()
        let allTips = tips(after: first)
        return allTips
    }

    /// Finds nodes in the version graph where the `next` property is empty.
    /// Only nodes newer than the provided version will be checked, which may result in some nodes being
    /// missed if the version passed in is not the very first version.
    private func tips(
        after version: OCKCDVersionedObject) -> Set<OCKCDVersionedObject> {

        if version.next.isEmpty {
            return Set([version])
        }

        let nextTips = version.next.map { $0.tips(after: $0) }
        let empty = Set<OCKCDVersionedObject>()
        let joined = nextTips.reduce(empty, { $0.union($1) })
        return joined
    }

    /// Find the first version of this object via a depth-first-search for a node with no previous nodes.
    private func firstVersion() -> OCKCDVersionedObject {

        guard let prev = previous.first else {
            return self
        }

        let first = prev.firstVersion()
        return first
    }

    /// Returns ordered array of versions of this object that do not have any conflicts.
    ///
    /// This is determined by doing a depth first walk from the first version to any tip.
    /// By counting the number of incoming and outgoing edges at each node, we can determine
    /// where there are conflicts.
    ///
    /// Any and all paths through the graph must pass through all non-conflicted nodes.
    /// Non-conflicted nodes are those at which the total number or accumulated incoming
    /// and outgoing edges sum up to 0.
    private func nonConflictedVersions() -> [OCKCDVersionedObject] {
        var current = firstVersion()
        var balance = 0
        var versions = [current]

        while let next = current.next.first {

            let incoming = next.previous.count
            let outgoing = next.next.count
            balance = outgoing - incoming

            // Include less than zero because the last node has no outgoing edge
            if balance <= 0 {
                versions.append(next)
            }

            current = next
        }

        return versions
    }
}

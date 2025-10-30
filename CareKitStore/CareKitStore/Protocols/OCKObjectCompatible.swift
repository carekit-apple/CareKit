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

protocol OCKVersionedObjectCompatible: Sendable {

    /// A human readable unique identifier. It is used strictly by the developer and will never be shown to a user.
    var id: String { get set }

    /// A universally unique identifier for this object.
    var uuid: UUID { get set }

    /// The UUID of the previous version of this object, or nil if there is no previous version.
    var previousVersionUUIDs: [UUID] { get set }

    /// The database UUID of the next version of this object, or nil if there is no next version.
    var nextVersionUUIDs: [UUID] { get set }

    /// The date at which the object was first persisted to the database.
    /// It will be nil for unpersisted values and objects.
    var createdDate: Date? { get set }

    /// The last date at which the object was updated.
    /// It will be nil for unpersisted values and objects.
    var updatedDate: Date? { get set }

    /// The date on which this object was marked deleted. Note that objects are never actually deleted,
    /// but rather they are marked deleted and will no longer be returned from queries.
    var deletedDate: Date? { get set }

    /// The date that this version of the object begins to take precedence over the previous version.
    /// Often this will be the same as the `createdDate`, but is not required to be.
    var effectiveDate: Date { get set }

    /// A user-defined group identifier that can be used both for querying and sorting results.
    /// Examples may include: "medications", "exercises", "family", "males", "diabetics", etc.
    var groupIdentifier: String? { get set }

    /// An array of user-defined tags that can be used to sort or classify objects or values.
    var tags: [String]? { get set }

    /// A unique id optionally used by a remote database. Its precise format will be
    /// determined by the remote database, but it is generally not expected to be human readable.
    var remoteID: String? { get set }

    /// A dictionary of information that can be provided by developers to support their own unique
    /// use cases.
    var userInfo: [String: String]? { get set }

    /// Specifies where this object originated from. It could contain information about the device
    /// used to record the data, its software version, or the person who recorded the data.
    var source: String? { get set }

    /// Specifies the location of some asset associated with this object. It could be the URL for
    /// an image or video, the bundle name of a audio asset, or any other representation the
    /// developer chooses.
    var asset: String? { get set }

    /// Any array of notes associated with this object.
    var notes: [OCKNote]? { get set }

    /// The semantic version of the database schema when this object was created.
    /// The value will be nil for objects that have not yet been persisted.
    var schemaVersion: OCKSemanticVersion? { get set }

    /// The timezone this record was created in.
    var timezone: TimeZone { get set }

    static func entity() -> NSEntityDescription

    func entity() -> OCKEntity
    
    func insert(context: NSManagedObjectContext) -> OCKCDVersionedObject
}

extension OCKVersionedObjectCompatible {
    mutating func copyVersionedValues(from other: OCKCDVersionedObject) {
        id = other.id
        uuid = other.uuid
        nextVersionUUIDs = other.next.map(\.uuid)
        previousVersionUUIDs = other.previous.map(\.uuid)
        createdDate = other.createdDate
        updatedDate = other.updatedDate
        deletedDate = other.deletedDate
        effectiveDate = other.effectiveDate
        groupIdentifier = other.groupIdentifier
        tags = other.tags?.map(\.title)
        source = other.source
        remoteID = other.remoteID
        userInfo = other.userInfo
        asset = other.asset
        schemaVersion = OCKSemanticVersion(other.schemaVersion)
        timezone = TimeZone(identifier: other.timezoneIdentifier)!

        notes = other.notes?.map {
            OCKNote(author: $0.author, title: $0.title, content: $0.content)
        }
    }
}

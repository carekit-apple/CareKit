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

internal protocol OCKObjectCompatible {
    /// The date at which the object was first persisted to the database.
    /// It will be nil for unpersisted values and objects.
    var createdDate: Date? { get set }

    /// The last date at which the object was updated.
    /// It will be nil for unpersisted values and objects.
    var updatedDate: Date? { get set }

    /// A user-defined group identifer that can be used both for querying and sorting results.
    /// Examples may include: "medications", "exercises", "family", "males", "diabetics", etc.
    var groupIdentifier: String? { get set }

    /// An array of user-defined tags that can be used to sort or classify objects or values.
    var tags: [String]? { get set }

    /// A unique identifier used by the local database. Its precise format will be determined
    /// by the underlying database, but it is generally not expected to be human readable.
    var internalID: OCKLocalVersionID? { get set }

    /// A unique identifier optionally used by a remote database. Its precise format will be
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
}

extension OCKObjectCompatible where Self: OCKVersionSettable {
    var internalID: OCKLocalVersionID? {
        get { return versionID }
        set { localDatabaseID = newValue }
    }
}

extension OCKObjectCompatible where Self: OCKLocalPersistable {
    var internalID: OCKLocalVersionID? {
        return localDatabaseID
    }
}

extension OCKObjectCompatible where Self: OCKLocalPersistableSettable {
    var internalID: OCKLocalVersionID? {
        get { return localDatabaseID }
        set { localDatabaseID = newValue }
    }
}

extension OCKObjectCompatible {
    mutating func copyCommonValues(from other: OCKCDObject) {
        createdDate = other.createdDate
        updatedDate = other.updatedDate
        schemaVersion = OCKSemanticVersion(other.schemaVersion)
        groupIdentifier = other.groupIdentifier
        tags = other.tags
        source = other.source
        internalID = other.localDatabaseID
        remoteID = other.remoteID
        userInfo = other.userInfo
        asset = other.asset
        notes = other.notes?.map {
            var note = OCKNote(author: $0.author, title: $0.title, content: $0.content)
            note.copyCommonValues(from: $0)
            return note
        }
    }
}

extension OCKObjectCompatible where Self: OCKVersionSettable {
    mutating func copyVersionedValues(from other: OCKCDVersionedObject) {
        deletedDate = other.deletedDate
        effectiveDate = other.effectiveDate
        versionID = other.localDatabaseID
        nextVersionID = other.next?.localDatabaseID
        previousVersionID = other.previous?.localDatabaseID
        copyCommonValues(from: other)
    }
}

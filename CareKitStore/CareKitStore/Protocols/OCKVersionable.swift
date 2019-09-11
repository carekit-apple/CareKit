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

/// Any value or object that conforms to `OCKIdentifiable` has the ability to tell if another object of the same
/// type is a different version of itself, or an entirely unrelated object.
public protocol OCKIdentifiable {
    /// `isAssociated` returns true if the other object or value represents the same entity as this object or value.
    /// For example, a versioned object like `OCKTask` will return true if compared with a previous or future version
    ///  of itself, but false if compared to any other task.
    ///
    /// - Parameter other: Any other object or value of the same type.
    /// - Returns: A boolean indicating if the two objects represent the same entity or not.
    func isAssociated(with other: Self) -> Bool
}

/// Any value or object that can be persisted to a local database is required to conform to this protocol
public protocol OCKLocalPersistable: OCKIdentifiable {
    /// A unique identifier used by the local database. It will typically be a primary key or UUID provided
    /// by the underlying database. It is not expected that it be meaningful to humans.
    var localDatabaseID: OCKLocalVersionID? { get }
}

public extension OCKLocalPersistable {
    func isAssociated(with other: Self) -> Bool {
        guard let localID = localDatabaseID else { return false }
        return localID == other.localDatabaseID
    }
}

internal protocol OCKLocalPersistableSettable: OCKLocalPersistable {
    var localDatabaseID: OCKLocalVersionID? { get set }
}

/// All value or objects that are versionable should conform to this protocol.
public protocol OCKVersionable: OCKLocalPersistable {
    /// A user-defined identifier that is the same across all versions of a versioned object or value.
    /// The identifier is generally expected to be meaningful to humans, but is not required to be.
    var identifier: String { get }

    /// The date at which this object was deleted. A nil value indicates that it has not been deleted yet.
    var deletedDate: Date? { get }

    /// The date at which this version is considered to begin taking effect
    var effectiveDate: Date { get }

    /// A database generated identifier that uniquely identifies the next version of this object or value.
    /// If there is no next version, then it will be nil.
    var nextVersionID: OCKLocalVersionID? { get }

    /// A database generated identifier that uniquely identifies the previous version of this object or value.
    /// If there is no previous version, then it will be nil.
    var previousVersionID: OCKLocalVersionID? { get }
}

public extension OCKVersionable {
    func isAssociated(with other: Self) -> Bool {
        return identifier == other.identifier
    }

    /// True if a newer version exists.
    var hasNextVersion: Bool {
        return nextVersionID != nil
    }

    /// True if a previous version exists.
    var hasPreviousVersion: Bool {
        return previousVersionID != nil
    }
}

internal protocol OCKVersionSettable: OCKVersionable, OCKLocalPersistableSettable {
    var localDatabaseID: OCKLocalVersionID? { get set }
    var deletedDate: Date? { get set }
    var effectiveDate: Date { get set }
    var nextVersionID: OCKLocalVersionID? { get set }
    var previousVersionID: OCKLocalVersionID? { get set }
}

extension OCKVersionSettable {
    public var versionID: OCKLocalVersionID? {
        get { return localDatabaseID }
        set { localDatabaseID = newValue }
    }
}

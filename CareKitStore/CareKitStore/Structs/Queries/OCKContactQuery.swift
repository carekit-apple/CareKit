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

/// A protocol that all contact queries are expected to conform to.
public protocol OCKAnyContactQuery: OCKEntityQuery {

    /// The identifiers of care plans for which contacts should match.
    var carePlanIDs: [String] { get set }

    /// The order in which the results will be sorted when returned from the query.
    var sortDescriptors: [OCKContactSortDescriptor] { get set }
}

public extension OCKAnyContactQuery {
    init(_ query: OCKAnyContactQuery) {
        if let other = query as? Self {
            self = other
            return
        }
        self = Self(query as OCKEntityQuery)
        self.carePlanIDs = query.carePlanIDs
        self.sortDescriptors = query.sortDescriptors
    }
}

/// Describes the order in which contacts can be sorted when queried.
public enum OCKContactSortDescriptor: Equatable {
    case givenName(ascending: Bool)
    case familyName(ascending: Bool)

    fileprivate var extendedVersion: OCKContactQuery.SortDescriptor {
        switch self {
        case .givenName(let ascending): return .givenName(ascending: ascending)
        case .familyName(let ascending): return .familyName(ascending: ascending)
        }
    }
}

/// A query that limits which contacts will be returned when fetching.
public struct OCKContactQuery: OCKAnyContactQuery, Equatable {

    /// Specifies the order in which query results will be sorted.
    enum SortDescriptor: Equatable {
        case givenName(ascending: Bool)
        case familyName(ascending: Bool)
        case effectiveDate(ascending: Bool)

        fileprivate var basicVersion: OCKContactSortDescriptor? {
            switch self {
            case .givenName(let ascending): return .givenName(ascending: ascending)
            case .familyName(let ascending): return .familyName(ascending: ascending)
            case .effectiveDate: return nil
            }
        }
    }

    /// Specific versions to be included in the query results.
    public var uuids: [UUID] = []

    /// The version of the care plans for which contacts should match.
    public var carePlanUUIDs: [UUID] = []

    /// The remote ID of care plans for which contacts should match.
    public var carePlanRemoteIDs: [String] = []

    /// The order in which the results will be sorted when returned from the query.
    public var sortDescriptors: [OCKContactSortDescriptor] {
        get { extendedSortDescriptors.compactMap { $0.basicVersion } }
        set { extendedSortDescriptors = newValue.map { $0.extendedVersion } }
    }

    /// The order in which the results will be sorted when returned from the query. This property supports
    /// additional sort descriptors unique to `OCKStore`.
    internal var extendedSortDescriptors: [SortDescriptor] = []

    /// An array of group identifiers to match against.
    public var groupIdentifiers: [String?] = []

    /// An array of tags to match against. If an object's tags contains one or more of entries, it will match the query.
    public var tags: [String] = []

    // MARK: OCKAnyContactQuery
    public var ids: [String] = []
    public var remoteIDs: [String?] = []
    public var carePlanIDs: [String] = []
    public var dateInterval: DateInterval?
    public var limit: Int?
    public var offset: Int = 0

    public init() { }
}

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

/// An enumerator that specifies the parameters by which outcomes can be queried.
public enum OCKOutcomeAnchor {
    case taskIdentifiers(_ identifiers: [String])
    case taskVersions(_ versionIDs: [OCKLocalVersionID])
    case taskRemoteIDs(_ remoteIDs: [String])

    case outcomeVersions(_ versionIDs: [OCKLocalVersionID])
    case outcomeRemoteIDs(_ remoteIDs: [String])
}

/// A query that limits which outcomes will be returned when fetching.
public struct OCKOutcomeQuery: OCKDateIntervalQueryable {
    public enum SortDescriptor {
        case date(ascending: Bool)
    }

    /// The earliest date at which outcomes should match.
    public var start: Date

    /// The latest date at which outcomes should match.
    public var end: Date

    /// An array of group identifiers to match against.
    public var groupIdentifiers: [String]?

    /// The maximum number of results that will be returned by the query. A nil value indicates no upper limit.
    public var limit: Int?

    /// An offset that can be used to paginate results.
    public var offset: Int?

    /// The order in which the results will be sorted when returned from the query.
    public var sortDescriptors: [SortDescriptor] = []

    /// An array of tags to match against. If an object's tags contains one or more of entries, it will match the query.
    public var tags: [String]?

    /// Initialize a new `OCKOutcomeQuery` by specifying the start and end dates.
    ///
    /// - Parameters:
    ///   - start: The earliest date at which outcomes should match.
    ///   - endDate: The latest date at which outcomes should match.
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

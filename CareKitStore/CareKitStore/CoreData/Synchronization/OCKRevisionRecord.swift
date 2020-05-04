/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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

/// Revision records are exchanged by the CareKit and a remote database during synchronization.
/// Each revision record contains an array of entities as well as a knowledge vector.
public struct OCKRevisionRecord: Equatable, Codable {

    /// The entities that were modified, in the order the were inserted into the database.
    /// The first entity is the oldest and the last entity is the newest.
    public let entities: [OCKEntity]

    /// A knowledge vector indicating the last known state of each other device
    /// by the device that authored this revision record.
    public let knowledgeVector: KnowledgeVector

    /// Create a new instance of `OCKRevisionRecord`.
    ///
    /// - Parameters:
    ///   - operation: The operation that was performed (add, update, or delete)
    ///   - entity: The entity that was modified
    ///
    /// - Note: CareKit expects that all entities be previously persisted to disk, which means
    /// that they have been assigned a permanent `uuid` as well as a `createdDate` and
    /// an `updatedDate`. Passing an entity that has not been persisted yet is considered a
    /// developer error and trigger an assert in debug builds.
    public init(entities: [OCKEntity], knowledgeVector: KnowledgeVector) {
        assert(entities.allSatisfy({ $0.uuid != nil }), "The entities' UUIDs must not be nil")
        assert(entities.allSatisfy({ $0.value.updatedDate != nil }), "The entities' createdDates must not be nil")
        self.entities = entities
        self.knowledgeVector = knowledgeVector
    }

    /// Knowledge vectors, also know as Lamport Timestamps, are used to determine the order
    /// of events in distributed systems that do not have a synchronized clock. If one knowledge
    /// vector is less than another, it means that the first event happened before the second. If
    /// one cannot be shown to be less than the other, it means the events are concurrent and
    /// require resolution.
    public struct KnowledgeVector: Codable, Equatable, Comparable {

        private(set) var processes: [UUID: Int]

        // Test seam
        init(_ processes: [UUID: Int]) {
            self.processes = processes
        }

        /// Create a new `KnowledgeVector` in which only the entry for the current
        /// process is non-zero.
        public init() {
            processes = [:]
        }

        /// Returns the clock value for the current process.
        public func clock(for uuid: UUID) -> Int {
            processes[uuid] ?? 0
        }

        /// Increment the vector entry for the current process.
        ///
        /// This method should be called each time the vector's owner completes
        /// merging a revision.
        ///
        /// ```
        /// store.mergeRevision(revision)
        /// store.vector.merge(revision.knowledgeVector)
        /// store.vector.increment()
        /// ```
        public mutating func increment(clockFor uuid: UUID) {
            let time = processes[uuid] ?? 0
            processes[uuid] = time + 1
        }

        /// Merge this vector with another.
        ///
        /// This method should be called to incorporate knowledge received
        /// from another node in the network.
        ///
        /// ```
        /// store.mergeRevision(revision)
        /// store.vector.merge(revision.knowledgeVector)
        /// store.vector.increment()
        /// ```
        public mutating func merge(with other: KnowledgeVector) {
            let allKeys = Set(Array(processes.keys) + Array(other.processes.keys))
            allKeys.forEach { key in
                let maxTime = max(processes[key] ?? 0, other.processes[key] ?? 0)
                processes[key] = maxTime
            }
        }

        /// A knowledge vector A is strictly less than another knowledge vector B if the clocks
        /// of all processes in A are less than or equal to those in B and at least one is strictly
        /// less than.
        ///
        /// If A is strictly less than B, that means B had knowledge of A, therefore changes made
        /// by B should not be considered conflicts. If A is not strictly less than B, the changes
        /// in A and B are considered concurrent, and conflicts must be resolved.
        public static func < (
            lhs: OCKRevisionRecord.KnowledgeVector,
            rhs: OCKRevisionRecord.KnowledgeVector) -> Bool {

            let allKeys = Set(Array(lhs.processes.keys) + Array(rhs.processes.keys))
            var isEqual = true

            for key in allKeys {
                if lhs.processes[key] ?? 0 > rhs.processes[key] ?? 0 {
                    return false
                }

                if isEqual && lhs.processes[key] ?? 0 < rhs.processes[key] ?? 0 {
                    isEqual = false
                }
            }

            return !isEqual
        }

        // MARK: Codable
        // The synthesized Codable implementations result in a JSON structure that
        // is not easily compatible with certain JSON parsers, so we provide an
        // alternate implementation that encodes the processes dictionary as an
        // array of objects.

        private enum Keys: CodingKey {
            case processes
        }

        private struct ClockInfo: Codable {
            let id: UUID
            let clock: Int
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            let clockInfo = try container.decode([ClockInfo].self, forKey: .processes)
            let keyValuePairs = clockInfo.map { (key: $0.id, value: $0.clock) }
            self.processes = Dictionary(uniqueKeysWithValues: keyValuePairs)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            let clockInfo = processes.map(ClockInfo.init)
            try container.encode(clockInfo, forKey: .processes)
        }
    }
}

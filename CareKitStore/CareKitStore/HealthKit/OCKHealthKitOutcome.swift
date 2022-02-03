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

import CoreData
import Foundation
import HealthKit

public struct OCKHealthKitOutcome: Codable, Equatable, Identifiable, OCKAnyOutcome {

    /// The UUID of the task to which this outcome belongs.
    public var taskUUID: UUID

    /// Denotes whether or not this outcome can be deleted from HealthKit.
    public let isOwnedByApp: Bool

    // MARK: OCKAnyOutcome
    public var id: String { taskUUID.uuidString + "_\(taskOccurrenceIndex)" }
    public var taskOccurrenceIndex: Int
    public var values: [OCKOutcomeValue]
    public var remoteID: String?
    public var groupIdentifier: String?
    public var notes: [OCKNote]?

    // MARK: OCKVersionedObjectCompatible
    public var effectiveDate: Date
    public internal(set) var deletedDate: Date?
    public internal(set) var uuid = UUID()
    public internal(set) var nextVersionUUIDs: [UUID] = []
    public internal(set) var previousVersionUUIDs: [UUID] = []
    
    // MARK: OCKObjectCompatible
    public internal(set) var createdDate: Date?
    public internal(set) var updatedDate: Date?
    public internal(set) var schemaVersion: OCKSemanticVersion?
    public var tags: [String]?
    public var source: String?
    public var userInfo: [String: String]?
    public var asset: String?
    public var timezone: TimeZone

    /// A record of the HealthKit object that this outcome is derived from. Used for targeted deletions.
    internal var healthKitUUIDs: Set<UUID>?

    /// Initialize by specifying the version of the task that owns this outcome, how many events have occurred before this outcome, and the values.
    ///
    /// - Parameters:
    ///   - taskUUID: The UUID of the task that owns this outcome. This ID can be retrieved from any task that has been queried from the store.
    ///   - taskOccurrenceIndex: The number of events that occurred before the event that owns this outcome.
    ///   - values: An array outcome values.
    public init(taskUUID: UUID, taskOccurrenceIndex: Int, values: [OCKOutcomeValue]) {
        self.taskUUID = taskUUID
        self.taskOccurrenceIndex = taskOccurrenceIndex
        self.values = values
        self.isOwnedByApp = true
        self.effectiveDate = Date()
        self.timezone = TimeZone.current
    }

    internal init(taskUUID: UUID, taskOccurrenceIndex: Int, values: [OCKOutcomeValue], isOwnedByApp: Bool, healthKitUUIDs: Set<UUID>) {
        self.taskUUID = taskUUID
        self.taskOccurrenceIndex = taskOccurrenceIndex
        self.values = values
        self.isOwnedByApp = isOwnedByApp
        self.healthKitUUIDs = healthKitUUIDs
        self.effectiveDate = Date()
        self.timezone = TimeZone.current
    }

    public func belongs(to task: OCKAnyTask) -> Bool {
        guard let task = task as? OCKHealthKitTask else { return false }
        return task.uuid == taskUUID
    }
}

extension OCKHealthKitOutcome: OCKVersionedObjectCompatible {

    static func entity() -> NSEntityDescription {
        OCKCDHealthKitOutcome.entity()
    }

    func entity() -> OCKEntity {
        .healthKitOutcome(self)
    }
    
    func insert(context: NSManagedObjectContext) -> OCKCDVersionedObject {
        OCKCDHealthKitOutcome(outcome: self, context: context)
    }
}

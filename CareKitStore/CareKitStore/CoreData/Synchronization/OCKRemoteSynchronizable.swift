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

/// Implement this protocol to listen for important events coming from an `OCKRemoteSynchronizable`.
public protocol OCKRemoteSynchronizationDelegate: AnyObject {

    /// This method will be called whenever a remote endpoint has changes that need to
    /// be reflected in the device's database.
    func didRequestSynchronization(_ remote: OCKRemoteSynchronizable)

    /// This method will be triggered by the remote to inform the user of progress.
    ///
    /// - Parameters:
    ///   - remote: The remote with which the device is synchronizing.
    ///   - progress: A value between 0.0 and 1.0 indicating progress.
    func remote(
        _ remote: OCKRemoteSynchronizable,
        didUpdateProgress progress: Double)

}

/// Implement this protocol to allow CareKitStore to synchronize against an endpoint of your choosing.
public protocol OCKRemoteSynchronizable: AnyObject {

    /// If set, the delegate will be alerted to important events delivered by the remote store.
    var delegate: OCKRemoteSynchronizationDelegate? { get set }

    /// If set to `true`, then the store will attempt to synchronize every time it is modified locally.
    var automaticallySynchronizes: Bool { get }

    /// Fetch a revision record from the server that documents the changes that have been made on
    /// the server since the last time synchronization was performed.
    ///
    /// - Parameters:
    ///   - knowledgeVector: Revisions newer than those encoded by this vector will be pulled.
    ///   - mergeRevision: A closure that can be called multiple times to merge revisions.
    ///   - completion: A closure that should be called with the results of the pull.
    ///
    /// - Warning: The `mergeRevision` closure should never be called in parallel.
    /// Wait until one merge has completed before starting another.
    func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (
            _ revision: OCKRevisionRecord,
            _ completion: @escaping (Error?) -> Void) -> Void,
        completion: @escaping (Error?) -> Void)

    /// Push a revision from a device up to the server.
    ///
    /// - Parameters:
    ///   - deviceRevision: Revision from the device to be pushed to the remote.
    ///   - overwriteRemote: If true, the contents of the remote should be completely overwritten.
    ///   - completion: A closure that should be called once the push completes.
    func pushRevisions(
        deviceRevision: OCKRevisionRecord,
        overwriteRemote: Bool,
        completion: @escaping (Error?) -> Void)

    /// This method will be called when CareKit detects a conflict between changes made to an entity in
    /// the device's local store and the changes made to the same entity on the server's store. Inspect the
    /// conflict and determine which version of the entity to keep, then call the completion closure with your
    /// chosen conflict resolution strategy.
    ///
    /// - Note: It is permissible to decide for the user, or to prompt the user to make a selection manually.
    ///
    /// - Parameters:
    ///   - conflict: A description of the conflict, including the entities that are in conflict.
    ///   - completion: A closure that should be called with the chosen resolution strategy.
    func chooseConflictResolutionPolicy(
        _ conflict: OCKMergeConflictDescription,
        completion: @escaping (OCKMergeConflictResolutionPolicy) -> Void)
}

/// Captures all possible conflict resolution policies that can be used when synchronizing the
/// contents of `OCKStore`.
public enum OCKMergeConflictResolutionPolicy: String, Equatable, Codable, CaseIterable {

    /// Keep the entity presently available locally, deleting the remote entity in conflict.
    case keepDevice

    /// Keep the entity added remotely, deleting the local conflicting entity.
    case keepRemote

    /// Causes the merge operation to fail and throw an error.
    case abortMerge
}

/// Describes a merge conflict between local and remote entities, including possible resolutions.
public struct OCKMergeConflictDescription: Equatable, Codable {

    /// The entities that are in conflict.
    public let entities: EntityPair

    /// Describes a pair of entities that are in conflict.
    public enum EntityPair: Equatable, Codable {
        case outcomes(deviceVersion: OCKOutcome, remoteVersion: OCKOutcome)
        case tasks(deviceVersion: OCKTask, remoteVersion: OCKTask)
        case carePlans(deviceVersion: OCKCarePlan, remoteVersion: OCKCarePlan)
        case contacts(deviceVersion: OCKContact, remoteVersion: OCKContact)
        case patients(deviceVersion: OCKPatient, remoteVersion: OCKPatient)
        
        private enum Keys: CodingKey {
            case device
            case remote
            case entity
        }

        private var entityType: OCKEntity.EntityType {
            switch self {
            case .outcomes: return .outcome
            case .tasks: return .task
            case .carePlans: return .carePlan
            case .contacts: return .contact
            case .patients: return .patient
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            switch try container.decode(OCKEntity.EntityType.self, forKey: .entity) {
            case .outcome:
                self = .outcomes(
                    deviceVersion: try container.decode(OCKOutcome.self, forKey: .device),
                    remoteVersion: try container.decode(OCKOutcome.self, forKey: .remote))
            case .task:
                self = .tasks(
                    deviceVersion: try container.decode(OCKTask.self, forKey: .device),
                    remoteVersion: try container.decode(OCKTask.self, forKey: .remote))
            case .carePlan:
                self = .carePlans(
                    deviceVersion: try container.decode(OCKCarePlan.self, forKey: .device),
                    remoteVersion: try container.decode(OCKCarePlan.self, forKey: .remote))
            case .contact:
                self = .contacts(
                    deviceVersion: try container.decode(OCKContact.self, forKey: .device),
                    remoteVersion: try container.decode(OCKContact.self, forKey: .remote))
            case .patient:
                self = .patients(
                    deviceVersion: try container.decode(OCKPatient.self, forKey: .device),
                    remoteVersion: try container.decode(OCKPatient.self, forKey: .remote))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encode(entityType, forKey: .entity)
            switch self {
            case let .outcomes(deviceVersion, remoteVersion):
                try container.encode(deviceVersion, forKey: .device)
                try container.encode(remoteVersion, forKey: .remote)
            case let .tasks(deviceVersion, remoteVersion):
                try container.encode(deviceVersion, forKey: .device)
                try container.encode(remoteVersion, forKey: .remote)
            case let .carePlans(deviceVersion, remoteVersion):
                try container.encode(deviceVersion, forKey: .device)
                try container.encode(remoteVersion, forKey: .remote)
            case let .contacts(deviceVersion, remoteVersion):
                try container.encode(deviceVersion, forKey: .device)
                try container.encode(remoteVersion, forKey: .remote)
            case let .patients(deviceVersion, remoteVersion):
                try container.encode(deviceVersion, forKey: .device)
                try container.encode(remoteVersion, forKey: .remote)
            }
        }
    }
}

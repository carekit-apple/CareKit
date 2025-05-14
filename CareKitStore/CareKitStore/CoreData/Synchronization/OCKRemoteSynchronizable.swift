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
    func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord) -> Void,
        completion: @escaping (Error?) -> Void)

    /// Push a revision from a device up to the server.
    ///
    /// - Parameters:
    ///   - deviceRevisions: Revisions from the device to be pushed to the remote.
    ///   - deviceKnowledge: The knowledge vector at the time of pushing the revisions.
    ///   - completion: A closure that should be called once the push completes.
    func pushRevisions(
        deviceRevisions: [OCKRevisionRecord],
        deviceKnowledge: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping (Error?) -> Void)

    /// This method will be called when CareKit detects a conflict between changes made to an entity in
    /// the device's local store and the changes made to the same entity in other device's stores. Inspect the
    /// conflicted and determine which version of the entity to keep, then call the completion closure with the
    /// chosen version.
    ///
    /// - Note: It is permissible to decide for the user, or to prompt the user to make a selection manually.
    ///
    /// - Parameters:
    ///   - conflicts: An array of the entities that are in conflict.
    ///   - completion: A closure that should be called with the version to keep.
    func chooseConflictResolution(
        conflicts: [OCKEntity],
        completion: @escaping OCKResultClosure<OCKEntity>)
}

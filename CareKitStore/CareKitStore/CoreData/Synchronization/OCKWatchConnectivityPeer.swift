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

#if canImport(WatchConnectivity)

import Foundation
import WatchConnectivity

private let revisionRequestKey = "OCKPeerRevisionRequest"
private let revisionReplyKey = "OCKPeerRevisionReply"
private let revisionPushKey = "OCKPeerRevisionPush"
private let revisionErrorKey = "OCKPeerRevisionErrorKey"

/// `OCKWatchConnectivityPeer` enables synchronizing two instances of `OCKStore`
/// where one store is part of an iPhone app and the other belongs to the watchOS companion
/// app.
///
/// The watch is capable of waking its companion app to send it messages, so the watch can
/// synchronize with the phone at any time. The phone however, cannot wake the watch, so
/// synchronizations initiated from the phone will only succeed when the companion app is in a
/// reachable state.
open class OCKWatchConnectivityPeer: OCKRemoteSynchronizable {

    struct Payload: Codable {
        let knowledgeVector: OCKRevisionRecord.KnowledgeVector
        let revisions: [OCKRevisionRecord]
    }

    public init() {}

    /// You should call this method anytime you receive a message from the companion app.
    /// CareKit will inspect the message to see if it contains any synchronization requests that
    /// require a response. If there are, the appropriate response will be returned. Be sure to
    /// pass the returned keys and values to the reply handler in `WCSessionDelegate`'s
    /// `session(_:didReceiveMessage:replyHandler:)` method.
    ///
    /// - Parameters:
    ///   - peerMessage: A message received from the peer for which a response will be created.
    ///   - store: A store from which the reply can be built.
    ///   - sendReply: A callback that will be invoked with the response when it is ready.
    public func reply(
        to peerMessage: [String: Any],
        store: OCKStore,
        sendReply: @escaping(_ message: [String: Any]) -> Void) {

        do {
            // If the peer requested the latest revision, compute and return it.
            if let data = peerMessage[revisionRequestKey] as? Data {
                let vector = try JSONDecoder().decode(OCKRevisionRecord.KnowledgeVector.self, from: data)
                let revisions = try store.computeRevisions(since: vector)
                let payload = Payload(knowledgeVector: store.context.knowledgeVector, revisions: revisions)
                let data = try JSONEncoder().encode(payload)
                sendReply([revisionReplyKey: data])
                store.context.knowledgeVector.increment(clockFor: store.context.clockID)
                return
            }

            // If the peer just pushed a revision, attempt to merge.
            // If unsuccessful, send back an error.
            if let data = peerMessage[revisionPushKey] as? Data {

                let payload = try JSONDecoder().decode(Payload.self, from: data)

                payload.revisions.forEach(store.mergeRevision)

                store.mergeRevision(
                    OCKRevisionRecord(
                        entities: [],
                        knowledgeVector: payload.knowledgeVector
                    )
                )

                sendReply([:])
            }

        } catch {
            sendReply([revisionErrorKey: error.localizedDescription])
        }
    }

    // MARK: OCKRemoteSynchronizable

    public var automaticallySynchronizes = true

    public weak var delegate: OCKRemoteSynchronizationDelegate?

    public func pullRevisions(
        since knowledgeVector: OCKRevisionRecord.KnowledgeVector,
        mergeRevision: @escaping (OCKRevisionRecord) -> Void,
        completion: @escaping (Error?) -> Void) {

        do {

            try validateSession()
            let data = try JSONEncoder().encode(knowledgeVector)

            session.sendMessage(
                [revisionRequestKey: data],
                replyHandler: { response in

                    let data = response[revisionReplyKey] as! Data

                    do {
                        let payload = try JSONDecoder().decode(Payload.self, from: data)
                        payload.revisions.forEach(mergeRevision)

                        let catchUp = OCKRevisionRecord(
                            entities: [],
                            knowledgeVector: payload.knowledgeVector
                        )

                        mergeRevision(catchUp)
                        completion(nil)
                    } catch {
                        completion(error)
                    }
                },
                errorHandler: completion)

        } catch {
            completion(error)
        }
    }

    public func pushRevisions(
        deviceRevisions: [OCKRevisionRecord],
        deviceKnowledge: OCKRevisionRecord.KnowledgeVector,
        completion: @escaping (Error?) -> Void) {

        do {

            try validateSession()

            let payload = Payload(
                knowledgeVector: deviceKnowledge,
                revisions: deviceRevisions
            )

            let data = try JSONEncoder().encode(payload)

            session.sendMessage(
                [revisionPushKey: data],
                replyHandler: { message in

                    if let problem = message[revisionErrorKey] as? String {
                        let error = OCKStoreError.remoteSynchronizationFailed(reason: problem)
                        completion(error)
                    } else {
                        completion(nil)
                    }
                },
                errorHandler: completion)

        } catch {
            completion(error)
        }
    }

    public func chooseConflictResolution(
        conflicts: [OCKEntity], completion: @escaping OCKResultClosure<OCKEntity>) {

        // Last write wins
        let lastWrite = conflicts
            .max(by: { $0.value.createdDate! > $1.value.createdDate! })!

        completion(.success(lastWrite))
    }

    // MARK: Internal

    fileprivate let session = WCSession.default

    // MARK: Test Seams

    func validateSession() throws {
        if session.activationState != .activated {
            throw OCKStoreError.remoteSynchronizationFailed(reason:
            """
            WatchConnectivity session has not been activated yet. \
            Make sure you have set the delegate for and activated \
            `WCSession.default` before attempting to synchronize \
            `OCKWatchConnectivityPeer`.
            """)
        }

        if !session.isReachable {
            throw OCKStoreError.remoteSynchronizationFailed(
                reason: "Companion app is not reachable")
        }

        #if os(iOS)
        if !session.isPaired {
            throw OCKStoreError.remoteSynchronizationFailed(
                reason: "No Apple Watch is paired")
        }

        if !session.isWatchAppInstalled {
            throw OCKStoreError.remoteSynchronizationFailed(
                reason: "Companion app not installed on Apple Watch")
        }
        #endif

        #if os(watchOS)
        if !session.isCompanionAppInstalled {
            throw OCKStoreError.remoteSynchronizationFailed(reason:
            """
            Could not complete synchronization because the companion \
            app is not installed on the peer iOS device.
            """)
        }

        if session.iOSDeviceNeedsUnlockAfterRebootForReachability {
            throw OCKStoreError.remoteSynchronizationFailed(reason:
            """
            iOS peer has recently been rebooted and needs to be unlocked \
            at least once before the companion app can be woken up.
            """
            )
        }
        #endif
    }
}

#endif

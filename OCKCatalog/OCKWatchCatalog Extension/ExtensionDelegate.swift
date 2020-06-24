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

import CareKit
import CareKitStore
import WatchConnectivity
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    private lazy var peer = OCKWatchConnectivityPeer()
    private lazy var store = OCKStore(name: "catalog-store", type: .inMemory, remote: peer)
    private(set) lazy var storeManager = OCKSynchronizedStoreManager(wrapping: store)

    private lazy var sessionManager: SessionManager = {
        let delegate = SessionManager()
        delegate.peer = peer
        delegate.store = store
        return delegate
    }()

    func applicationDidFinishLaunching() {
        peer.automaticallySynchronizes = true

        WCSession.default.delegate = sessionManager
        WCSession.default.activate()
    }

    func applicationDidBecomeActive() {
        store.synchronize { error in
            print(error?.localizedDescription ?? "Successful sync!")
        }
    }
}

class SessionManager: NSObject, WCSessionDelegate {

    fileprivate(set) var peer: OCKWatchConnectivityPeer!
    fileprivate(set) var store: OCKStore!

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?) {

        print("New session state: \(activationState)")
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void) {

        print("Received message from peer!")

        peer.reply(to: message, store: store) { reply in
            replyHandler(reply)
        }
    }
}

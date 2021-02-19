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

import AuthenticationServices
import CareKit
import CareKitStore
import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private(set) lazy var peer = OCKWatchConnectivityPeer()
    private(set) lazy var cdStore = OCKStore(name: "carekit-catalog-cd", type: .inMemory, remote: peer)
    private(set) lazy var hkStore = OCKHealthKitPassthroughStore(store: cdStore)

    private lazy var sessionManager: SessionManager = {
        let sessionManager = SessionManager()
        sessionManager.peer = self.peer
        sessionManager.store = self.cdStore
        return sessionManager
    }()

    private(set) lazy var storeManager: OCKSynchronizedStoreManager = {

        cdStore.fillWithDummyData()
        hkStore.fillWithDummyData()

        let coordinator = OCKStoreCoordinator()
        coordinator.attach(store: cdStore)
        coordinator.attach(eventStore: hkStore)

        return OCKSynchronizedStoreManager(wrapping: coordinator)
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        WCSession.default.delegate = sessionManager
        WCSession.default.activate()

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

private class SessionManager: NSObject, WCSessionDelegate {

    fileprivate var peer: OCKWatchConnectivityPeer!
    fileprivate var store: OCKStore!

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?) {

        print("WCSession activation did complete: \(activationState)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void) {

        print("Did receive message!")

        peer.reply(to: message, store: store) { reply in
            replyHandler(reply)
        }
    }
}

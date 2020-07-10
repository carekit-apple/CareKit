//
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
import CareKitUI
import Foundation
import SwiftUI
import XCTest

@available(iOS 14.0, watchOS 7.0, *)
class TestDetailedContactView: XCTestCase {

    let controller: OCKDetailedContactController = {
        let store = OCKStore(name: "carekit-store", type: .onDisk)
        return .init(storeManager: .init(wrapping: store))
    }()

    let query = OCKContactQuery(id: "lexi-torres")
    let data = OCKContact(id: "lexi-torres", givenName: "Lexi", familyName: "Torres", carePlanUUID: nil)
    // CODE REVIEW: Let's break this long line down into multiple lines
    let staticView = CareKitUI.DetailedContactView(title: Text(""), detail: Text(""), instructions: Text(""), image: Image(systemName: "person.crop.circle"), disclosureImage: nil, callButton: ContactButton(title: Text("Call"), image: Image(systemName: "phone"), action: nil), messageButton: ContactButton(title: Text("Message"), image: Image(systemName: "text.bubble"), action: nil), emailButton:  ContactButton(title: Text("E-mail"), image: Image(systemName: "envelope"), action: nil), addressButton: AddressButton(title: Text("Address"), detail: Text(""), image: Image(systemName: "location"), action: nil))

    func testDefaultContentInitializers() {
        _ = CareKit.DetailedContactView(contact: data, contactQuery: query, storeManager: controller.storeManager)
        _ = CareKit.DetailedContactView(contactID: "lexi-torres", storeManager:  controller.storeManager)
        _ = CareKit.DetailedContactView(controller: controller)
    }

    func testCustomContentInitializers() {
        _ = CareKit.DetailedContactView(contact: data, contactQuery: query, storeManager: controller.storeManager) { _ in self.staticView }
        _ = CareKit.DetailedContactView(contactID: "lexi-torres", storeManager: controller.storeManager) { _ in self.staticView }
        _ = CareKit.DetailedContactView(controller: controller) { _ in self.staticView }
    }
}

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

@testable import CareKit
import CareKitStore
import CareKitUI
import Combine
import Foundation
import SwiftUI
import XCTest
import Contacts

class TestDetailedContactViewModel: XCTestCase {

    var controller: OCKDetailedContactController!
    var cancellable: AnyCancellable?
    var model: ContactViewModel!

    override func setUp() {
        super.setUp()
        let data = OCKContact.mock()
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        controller = .init(storeManager: .init(wrapping: store))
        controller.contact = data
        model = controller.viewModel
    }

    func testViewModelCreation() {
        XCTAssertEqual(formatName(controller.contact?.name), model.title)
        XCTAssertEqual(formatAddress(controller.contact?.address), model.address)
    }
    
    private func formatName(_ name: PersonNameComponents?) -> String {
        guard let name = name else {
            return ""
        }
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .medium
        
        return formatter.string(from: name)
    }
    
    
    private func formatAddress(_ address: OCKPostalAddress?) -> String {
        guard let address = address else {
            return ""
        }
        let formatter = CNPostalAddressFormatter()
        formatter.style = .mailingAddress
        
        return formatter.string(from: address)
    }
}

private extension OCKContact {
    static func mock() -> OCKContact {
        var contact = OCKContact(id: "lexi-torres", givenName: "Lexi", familyName: "Torres", carePlanUUID: nil)
        contact.title = "Family Practice"
        return contact
    }
}

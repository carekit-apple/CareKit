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

import CareKitStore
import Combine
import Contacts

extension OCKContactController {

    var viewModel: ContactViewModel? { makeViewModel(from: contact) }
    
    private func makeViewModel(from contact: OCKAnyContact?) -> ContactViewModel? {
        guard let contact = contact else { return  nil }

        return .init(title: formatName(contact.name), detail: contact.title, instructions: contact.role, address: formatAddress(contact.address))
    }

    // CODE REVIEW: Why is the formatName parameter optinal?
    private func formatName(_ name: PersonNameComponents?) -> String {
        guard let name = name else {
            return ""
        }
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .medium
        
        return formatter.string(from: name)
    }
    
    // CODE REVIEW: Why is the address parameter optinal?
    // CODE REVIEW: Why is the return type non-optional?
    private func formatAddress(_ address: OCKPostalAddress?) -> String {
        guard let address = address else {
            return ""
        }
        let formatter = CNPostalAddressFormatter()
        formatter.style = .mailingAddress
        
        return formatter.string(from: address)
    }
}


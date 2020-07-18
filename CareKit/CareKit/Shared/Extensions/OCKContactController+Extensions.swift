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
import SwiftUI
import MessageUI

extension OCKContactController {

    var viewModel: ContactViewModel? { makeViewModel(from: contact) }
    private var messageDelegate: MessageComposerDelegate { MessageComposerDelegate() }
    private var mailDelegate: MailComposerDelegate { MailComposerDelegate() }
    
    private func makeViewModel(from contact: OCKAnyContact?) -> ContactViewModel? {
        guard let contact = contact else { return  nil }

        let errorHandler: (Error) -> Void = { [weak self] error in
            self?.error = error
        }
        
        return .init(title: formatName(contact.name), detail: contact.title, instructions: contact.role, address: formatAddress(contact.address),
                     callAction: didInitiateCall(errorHandler: errorHandler), messageAction: didInitiateMessage(errorHandler: errorHandler), emailAction: didInitiateEmail(errorHandler: errorHandler), addressAction: didInitiateAddress(errorHandler: errorHandler))
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
    
    private func didInitiateCall(errorHandler: ((Error) -> Void)?) -> () -> Void  {
        {
            self.handleThrowable(method: self.initiateCall) { url in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        }
    }
    
    private func didInitiateMessage(errorHandler: ((Error) -> Void)?) -> () -> Void  {
        {
            self.handleThrowable(method: self.initiateMessage) { [weak self] viewController in
                guard let self = self else { return }
                guard let rootViewController = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController else {
                    return
                }
                guard let mailComposeViewController = (rootViewController as? MFMessageComposeViewController) else {
                    return
                }
                mailComposeViewController.messageComposeDelegate = self.messageDelegate
                mailComposeViewController.present(viewController, animated: true, completion: nil)
            }
            
        }
    }
    
    private func didInitiateEmail(errorHandler: ((Error) -> Void)?) -> () -> Void  {
        {
            self.handleThrowable(method: self.initiateEmail) { [weak self] viewController in
                guard let self = self else { return }
                guard let rootViewController = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController else {
                    return
                }
                guard let mailComposeViewController = (rootViewController as? MFMailComposeViewController) else {
                    return
                }
                mailComposeViewController.mailComposeDelegate = self.mailDelegate
                mailComposeViewController.present(viewController, animated: true, completion: nil)
            }
            
        }
    }
    
    private func didInitiateAddress(errorHandler: ((Error) -> Void)?) -> () -> Void  {
        {
            self.initiateAddressLookup { (result) in
                switch result {
                case .success(let mapItem):
                    mapItem.openInMaps(launchOptions: nil)
                case .failure(let error):
                    self.error = error
                }
            }
            
        }
    }
    
    func handleThrowable<T>(method: () throws -> T, success: (T) -> Void) {
        do {
            let result = try method()
            success(result)
        } catch {
            self.error = error
        }
    }
}

extension OCKContactController {
    private class MailComposerDelegate: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
        }
    }
    
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}

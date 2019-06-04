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

import UIKit
import CareKitUI
import CareKitStore
import Contacts

internal class OCKBindableSimpleContactView<Contact: Equatable & OCKContactConvertible>: OCKSimpleContactView, OCKBindable {
    
    private let nameFormatter: PersonNameComponentsFormatter = {
        let nameFormatter = PersonNameComponentsFormatter()
        nameFormatter.style = .medium
        return nameFormatter
    }()
    
    private let addressFormatter: CNPostalAddressFormatter = {
        let formatter = CNPostalAddressFormatter()
        formatter.style = .mailingAddress
        return formatter
    }()
    
    public func updateView(with model: Contact?, animated: Bool) {
        let contact = model?.convert()
        headerView.titleLabel.text = contact?.name != nil ? nameFormatter.string(from: contact!.name) : nil
        
        if let asset = contact?.asset {
            // We can't be sure if the image they provide is in the assets folder, in the bundle, or in a directory.
            // We can check all 3 possibilities and then choose whichever is non-nil.
            let bundle = Bundle(for: OCKSimpleContactView.self)
            let careKitAssetsImage = UIImage(named: asset, in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            let appAssetsImage = UIImage(named: asset)
            let otherUrlImage = UIImage(contentsOfFile: asset)
            let image = otherUrlImage ?? appAssetsImage ?? careKitAssetsImage ?? OCKSimpleContactView.defaultImage
            headerView.iconImageView?.image = image
        } else {
            headerView.iconImageView?.image = OCKSimpleContactView.defaultImage
        }
        
        // set the role label
        instructionsLabel.text = contact?.role
        headerView.detailLabel.text = contact?.title
        
        // check we have have contact info needed for phone,
        // message, and email buttons to unhide them
        addressButton.isHidden = contact?.address == nil
        callButton.isHidden = contact?.phoneNumbers?.isEmpty ?? true
        emailButton.isHidden = contact?.emailAddresses?.isEmpty ?? true
        messageButton.isHidden = contact?.messagingNumbers?.isEmpty ?? true
        
        // Format the address with current locale in mind and set button text.
        if let contactAddress = contact?.address {
            addressButton.setDetail(addressFormatter.string(from: contactAddress), for: .normal)
        }
    }
}

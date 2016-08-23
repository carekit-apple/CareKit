/*
 Copyright (c) 2016, Troy Tsubota. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
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

class StoryboardConnectViewController: OCKConnectViewController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let contact1 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Anne Johnson", relation: "Primary Physician @ Nearby Hospital in my State", tintColor: UIColor.purpleColor(), phoneNumber: nil, messageNumber: nil, emailAddress: "annejohnson1@mac.com", monogram: "AJ", image: nil)
        let contact2 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Bill James, Lorem Ipsum dolor", relation: "Doctor", tintColor: nil, phoneNumber: CNPhoneNumber.init(stringValue: "1-888-555-5512"), messageNumber: nil, emailAddress: "this_is_a_very_long_username@example.com", monogram: "Bill James, Lorem Ipsum dolor", image: nil)
        let contact3 = OCKContact.init(contactType: OCKContactType.Personal, name: "Maria Ruiz", relation: "Friend", tintColor: UIColor.greenColor(), phoneNumber: nil, messageNumber: nil, emailAddress: nil, monogram: "MR", image: nil)
        let contact4 = OCKContact.init(contactType: OCKContactType.Personal, name: "Ravi Patel", relation: "Emergency Contact", tintColor: UIColor.orangeColor(), phoneNumber: CNPhoneNumber.init(stringValue: "8885555512"), messageNumber: CNPhoneNumber.init(stringValue: "888-555-5512"), emailAddress: "", monogram: "RP",image: UIImage.init(named: "Stars"))
        let contact5 = OCKContact.init(contactType: OCKContactType.Personal, name: "Edge Indicators", relation: "are set in the storyboard.", tintColor: nil, phoneNumber: nil, messageNumber: nil, emailAddress: nil, monogram: "", image: nil)
        contacts = [contact1, contact2, contact3, contact4, contact5]
    }
    
}

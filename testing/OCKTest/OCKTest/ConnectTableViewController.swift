/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 Copyright (c) 2016, WWT Asynchrony Labs. All rights reserved.

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


class ConnectTableViewController: UITableViewController, OCKConnectViewControllerDelegate {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "No Delegate"
            case 1:
                cell.textLabel?.text = "With Delegate & Edge Indicators"
            case 2:
                cell.textLabel?.text = "No Care Team"
            case 3:
                cell.textLabel?.text = "No Personal Contacts"
            case 4:
                cell.textLabel?.text = "No Contacts"
            default:
                cell.textLabel?.text = nil
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            
            // No Delegate
            
			let contact1 = OCKContact(contactType: .CareTeam, name: "Anne Johnson", relation: "Primary Physician @ Nearby Hospital in my State", contactInfoItems: [.email("annejohnson1@mac.com")], tintColor: .purpleColor(), monogram: "AJ", image: nil)
            let contact2 = OCKContact(contactType: .CareTeam, name: "Bill James, Lorem Ipsum dolor", relation: "Doctor", contactInfoItems: [.phone("1-888-555-5512"), .email("this_is_a_very_long_username@example.com")], tintColor: nil, monogram: "Bill James, Lorem Ipsum dolor", image: nil)
			let contact3 = OCKContact(contactType: .Personal, name: "Maria Ruiz", relation: "Friend", contactInfoItems: [], tintColor: .greenColor(), monogram: "MR", image: nil)
			let contact4 = OCKContact(contactType: .Personal, name: "Ravi Patel", relation: "Emergency Contact", contactInfoItems: [.phone("8885555512"), .email("888-555-5512")], tintColor: .orangeColor(), monogram: "RP",image: UIImage(named: "Stars"))
            let contact5 = OCKContact(contactType: .Personal, name: "", relation: "", contactInfoItems: [], tintColor: nil, monogram: "", image: nil)
            
			let connectViewController = OCKConnectViewController(contacts: [contact1, contact2, contact3, contact4, contact5])
            self.navigationController?.pushViewController(connectViewController, animated: true)
            
        } else if indexPath.row == 1 {
            
            // With Delegate & Edge Indicators
            
            let contact1 = OCKContact(contactType: .CareTeam, name: "Dr Kumar, Gita", relation: "Nutritionist", contactInfoItems: [.email("gkumar@mac.com")], tintColor: .blueColor(), monogram: "GK", image: nil)
            contact1.image = UIImage(named: "SquareCircle")
			let contact2Info: [OCKContactInfo] = [OCKContactInfo(type: .Phone, displayString: "888-555-5512", actionURL: nil),
			                                      OCKContactInfo(type: .Message, displayString: "888-555-5512", actionURL: nil),
			                                      OCKContactInfo(type: .Email, displayString: "drTomClark@example.com", actionURL: nil)]
			let contact2 = OCKContact(contactType: .CareTeam, name: "Dr Tom Clark", relation: "Physician", contactInfoItems: contact2Info, tintColor: nil, monogram: "TC", image: nil)
            let contact3 = OCKContact(contactType: .CareTeam, name: "Dr Juan Chavez", relation: "Dentist", contactInfoItems: [.sms("888-555-5512")], tintColor: .greenColor(), monogram: "JC", image: nil)
            let contact4 = OCKContact(contactType: .Personal, name: "Jason", relation: "Dad", contactInfoItems: [.phone("888-555-5512"), .sms("888-555-5512"), .email("dad@example.com")], tintColor: .orangeColor(), monogram: "Dad" , image: UIImage(named: "SquareCircle"))
            let contact5 = OCKContact(contactType: .Personal, name: "Mei Chen", relation: "Sis", contactInfoItems: [], tintColor: nil, monogram: "MC", image: UIImage(named: "Triangles.jpg"))
            let contact6 = OCKContact(contactType: .Personal, name: "Avram", relation: "Bro", contactInfoItems: [.email("avram@example.com")], tintColor: nil, monogram: "Avram", image: nil)
            let contact7 = OCKContact(contactType: .Personal, name: "Jim", relation: "Best Friend", contactInfoItems: [.email("jim12@example.com")], tintColor: nil, monogram: "😊" , image: nil)
            let contact8 = OCKContact(contactType: .CareTeam, name: "Dr Yoshiko Wong", relation: "Doctor", contactInfoItems: [.sms("888-555-5512"), .email("drYoshiko@example.com")], tintColor: .cyanColor(), monogram: "YW", image: nil)
			let contact9Info: [OCKContactInfo] = [.phone("314-555-1234"),
			                                      .phone("314-555-4321"),
			                                      .email("ewodehouse@example.com"),
			                                      .sms("314-555-4321"),
			                                      .facetimeVideo("user@example.com", displayString: nil),
			                                      .facetimeVideo("3145554321", displayString: "314-555-4321"),
			                                      .facetimeAudio("3145554321", displayString: "314-555-4321"),
			                                      OCKContactInfo(type: .Message, displayString: "ezra.wodehouse", actionURL: NSURL(string: "starstuffchat://ezra.wodehouse")!, label: "starstuff chat", icon: UIImage(named: "starstuff"))]
			let contact9 = OCKContact(contactType: .CareTeam, name: "Dr Ezra Wodehouse", relation: "Doctor", contactInfoItems: contact9Info, tintColor: .brownColor(), monogram: "EW", image: nil)
            
            let connectViewController = OCKConnectViewController(contacts: [contact1, contact2, contact3, contact4, contact5, contact6, contact7, contact8, contact9])
            connectViewController.delegate = self
            connectViewController.showEdgeIndicators = true
            self.navigationController?.pushViewController(connectViewController, animated: true)
            
        } else if indexPath.row == 2 {
            
            // No Care Team
            
			let contact1 = OCKContact(contactType: .Personal, name: "Luisa", relation: "Friend", contactInfoItems: [.email("Luisa@example.com")], tintColor: nil, monogram: "Luisa", image: UIImage(named: "Triangles.jpg"))
            let connectViewController = OCKConnectViewController(contacts: [contact1])
            connectViewController.delegate = self
            self.navigationController?.pushViewController(connectViewController, animated: true)
            
        } else if indexPath.row == 3 {
            
            // No Personal Contacts
            
            let contact1 = OCKContact(contactType: .CareTeam, name: "Dr Gabrielle Contreras", relation: "Nutritionist", contactInfoItems: [.email("contreras@example.com")], tintColor: .blueColor(), monogram: "Not Visible", image: UIImage())
            let contact2 = OCKContact(contactType: .CareTeam, name: "Dr Scharanski", relation: "Dental Surgeon", contactInfoItems: [.sms("888-555-5512")], tintColor: .greenColor(), monogram: "Hello\nWorld", image: nil)
            let connectViewController = OCKConnectViewController(contacts: [contact1, contact2])
            connectViewController.delegate = self;
            self.navigationController?.pushViewController(connectViewController, animated: true)
            
        } else if indexPath.row == 4 {
            
            // No Contacts
            
            let connectViewController = OCKConnectViewController(contacts: nil)
            connectViewController.delegate = self;
            self.navigationController?.pushViewController(connectViewController, animated: true)
        }
    }
    
    func connectViewController(connectViewController: OCKConnectViewController, titleForSharingCellForContact contact: OCKContact) -> String? {
        if contact.type == .CareTeam {
            return "Share Reports with a Doctor"
        }
        return nil
    }
    
    func connectViewController(connectViewController: OCKConnectViewController, didSelectShareButtonForContact contact: OCKContact, presentationSourceView sourceView: UIView?) {
        
        let bar1 = OCKBarSeries(title: "Title 1", values: [6, 5], valueLabels: ["6", "5"], tintColor: .brownColor())
        let bar2 = OCKBarSeries(title: "Title 2", values: [5, 10], valueLabels: ["5", "10"], tintColor: .blackColor())
        let bar3 = OCKBarSeries(title: "Title 3", values: [4, 10], valueLabels: ["4", "10"], tintColor: .blueColor())
        
        let chart = OCKBarChart(title: "Chart Title", text: "Chart Description", tintColor: .grayColor(), axisTitles: ["Axis #1", "Axis #2"], axisSubtitles: ["Subtitle #1", "Subtitle #2"], dataSeries: [bar1, bar2, bar3])
        
        let doc = OCKDocument(title: nil, elements:[OCKDocumentElementChart(chart: chart)])
        
        doc.createPDFDataWithCompletion { (data, error) in
                        let activityController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
                        activityController.excludedActivityTypes = [UIActivityTypePostToVimeo, UIActivityTypeOpenInIBooks, UIActivityTypePostToFlickr]
                         activityController.popoverPresentationController?.sourceView = sourceView
                        self.presentViewController(activityController, animated: true) {}
            
        }
   
    }
	
	func connectViewController(connectViewController: OCKConnectViewController, handleContactInfoSelected contactInfo: OCKContactInfo) -> Bool {
		if contactInfo.actionURL?.scheme == "starstuffchat" {
			print("starstuff chat pressed")
			return true
		}
		return false
	}
}


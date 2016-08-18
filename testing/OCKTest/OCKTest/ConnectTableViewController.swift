/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
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
            return UITableViewCell.init()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            
            // No Delegate
            
            let contact1 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Anne Johnson", relation: "Primary Physician @ Nearby Hospital in my State", tintColor: UIColor.purpleColor(), phoneNumber: nil, messageNumber: nil, emailAddress: "annejohnson1@mac.com", monogram: "AJ", image: nil)
            let contact2 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Bill James, Lorem Ipsum dolor", relation: "Doctor", tintColor: nil, phoneNumber: CNPhoneNumber.init(stringValue: "1-888-555-5512"), messageNumber: nil, emailAddress: "this_is_a_very_long_username@example.com", monogram: "Bill James, Lorem Ipsum dolor", image: nil)
            let contact3 = OCKContact.init(contactType: OCKContactType.Personal, name: "Maria Ruiz", relation: "Friend", tintColor: UIColor.greenColor(), phoneNumber: nil, messageNumber: nil, emailAddress: nil, monogram: "MR", image: nil)
            let contact4 = OCKContact.init(contactType: OCKContactType.Personal, name: "Ravi Patel", relation: "Emergency Contact", tintColor: UIColor.orangeColor(), phoneNumber: CNPhoneNumber.init(stringValue: "8885555512"), messageNumber: CNPhoneNumber.init(stringValue: "888-555-5512"), emailAddress: "", monogram: "RP",image: UIImage.init(named: "Stars"))
            let contact5 = OCKContact.init(contactType: OCKContactType.Personal, name: "", relation: "", tintColor: nil, phoneNumber: nil, messageNumber: nil, emailAddress: nil, monogram: "", image: nil)
            let connectViewController = OCKConnectViewController.init(contacts: [contact1, contact2, contact3, contact4, contact5])
            self.navigationController?.pushViewController(connectViewController, animated: true)
            
        } else if indexPath.row == 1 {
            
            // With Delegate & Edge Indicators
            
            let contact1 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Dr Kumar, Gita", relation: "Nutritionist", tintColor: UIColor.blueColor(), phoneNumber: nil, messageNumber: nil, emailAddress: "gkumar@mac.com", monogram: "GK", image: nil)
            contact1.image = UIImage.init(named: "SquareCircle")
            let contact2 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Dr Tom Clark", relation: "Physician", tintColor: nil, phoneNumber: CNPhoneNumber.init(stringValue: "888"), messageNumber: CNPhoneNumber.init(stringValue: "888-555-5512"), emailAddress: "drTomClark@example.com", monogram: "TC", image: nil)
            let contact3 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Dr Juan Chavez", relation: "Dentist", tintColor: UIColor.greenColor(), phoneNumber: nil, messageNumber: CNPhoneNumber.init(stringValue: "888-555-5512"), emailAddress: nil, monogram: "JC", image: nil)
            let contact4 = OCKContact.init(contactType: OCKContactType.Personal, name: "Jason", relation: "Dad", tintColor: UIColor.orangeColor(), phoneNumber: CNPhoneNumber.init(stringValue: "888-555-5512"), messageNumber: CNPhoneNumber.init(stringValue: "888-555-5512"), emailAddress: "dad@example.com", monogram: "Dad" , image: UIImage.init(named: "SquareCircle"))
            let contact5 = OCKContact.init(contactType: OCKContactType.Personal, name: "Mei Chen", relation: "Sis", tintColor: nil, phoneNumber: nil, messageNumber: nil, emailAddress: nil, monogram: "MC", image: UIImage.init(named: "Triangles.jpg"))
            let contact6 = OCKContact.init(contactType: OCKContactType.Personal, name: "Avram", relation: "Bro", tintColor: nil, phoneNumber: nil, messageNumber: nil, emailAddress: "avram@example.com", monogram: "Avram", image: nil)
            let contact7 = OCKContact.init(contactType: OCKContactType.Personal, name: "Jim", relation: "Best Friend", tintColor: nil, phoneNumber: nil, messageNumber: nil, emailAddress: "jim12@example.com", monogram: "😊" , image: nil)
            let contact8 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Dr Yoshiko Wong", relation: "Doctor", tintColor: UIColor.cyanColor(), phoneNumber: nil, messageNumber: CNPhoneNumber.init(stringValue: "888-555-5512"), emailAddress: "drYoshiko@example.com", monogram: "YW", image: nil)
            let connectViewController = OCKConnectViewController.init(contacts: [contact1, contact2, contact3, contact4, contact5, contact6, contact7, contact8])
            connectViewController.delegate = self
            connectViewController.showEdgeIndicators = true
            self.navigationController?.pushViewController(connectViewController, animated: true)
            
        } else if indexPath.row == 2 {
            
            // No Care Team

            let contact1 = OCKContact.init(contactType: OCKContactType.Personal, name: "Luisa", relation: "Friend", tintColor: nil, phoneNumber: nil, messageNumber: nil, emailAddress: "Luisa@example.com", monogram: "Luisa", image: UIImage.init(named: "Triangles.jpg"))
            let connectViewController = OCKConnectViewController.init(contacts: [contact1])
            connectViewController.delegate = self;
            self.navigationController?.pushViewController(connectViewController, animated: true)
            
        } else if indexPath.row == 3 {
            
            // No Personal Contacts
            
            let contact1 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Dr Gabrielle Contreras", relation: "Nutritionist", tintColor: UIColor.blueColor(), phoneNumber: nil, messageNumber: nil, emailAddress: "contreras@example.com", monogram: "Not Visible", image: UIImage.init())
            let contact2 = OCKContact.init(contactType: OCKContactType.CareTeam, name: "Dr Scharanski", relation: "Dental Surgeon", tintColor: UIColor.greenColor(), phoneNumber: nil, messageNumber: CNPhoneNumber.init(stringValue: "888-555-5512"), emailAddress: nil, monogram: "Hello\nWorld", image: nil)
            let connectViewController = OCKConnectViewController.init(contacts: [contact1, contact2])
            connectViewController.delegate = self;
            self.navigationController?.pushViewController(connectViewController, animated: true)
            
        } else if indexPath.row == 4 {
            
            // No Contacts
            
            let connectViewController = OCKConnectViewController.init(contacts: nil)
            connectViewController.delegate = self;
            self.navigationController?.pushViewController(connectViewController, animated: true)
        }
    }
    
    func connectViewController(connectViewController: OCKConnectViewController, titleForSharingCellForContact contact: OCKContact) -> String? {
        if contact.type == OCKContactType.CareTeam {
            return "Share Reports with a Doctor"
        }
        return nil
    }
    
    func connectViewController(connectViewController: OCKConnectViewController, didSelectShareButtonForContact contact: OCKContact, presentationSourceView sourceView: UIView) {
        
        let bar1 = OCKBarSeries.init(title: "Title 1", values: [6, 5], valueLabels: ["6", "5"], tintColor: UIColor.brownColor())
        let bar2 = OCKBarSeries.init(title: "Title 2", values: [5, 10], valueLabels: ["5", "10"], tintColor: UIColor.blackColor())
        let bar3 = OCKBarSeries.init(title: "Title 3", values: [4, 10], valueLabels: ["4", "10"], tintColor: UIColor.blueColor())
        
        let chart = OCKBarChart.init(title: "Chart Title", text: "Chart Description", tintColor: UIColor.grayColor(), axisTitles: ["Axis #1", "Axis #2"], axisSubtitles: ["Subtitle #1", "Subtitle #2"], dataSeries: [bar1, bar2, bar3])
        
        let doc = OCKDocument.init(title: nil, elements:[OCKDocumentElementChart.init(chart: chart)])
        
        doc.createPDFDataWithCompletion { (data, error) in
                        let activityController = UIActivityViewController.init(activityItems: [data], applicationActivities: nil)
                        activityController.excludedActivityTypes = [UIActivityTypePostToVimeo, UIActivityTypeOpenInIBooks, UIActivityTypePostToFlickr]
                         activityController.popoverPresentationController?.sourceView = sourceView
                        self.presentViewController(activityController, animated: true) {}
            
        }
   
    }

}


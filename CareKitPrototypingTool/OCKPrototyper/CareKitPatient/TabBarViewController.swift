/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


import UIKit
import CareKit


class TabBarViewController: UITabBarController {
    
    fileprivate var storeReference: OCKCarePlanStore?
    fileprivate var plistObjectReference: PlistParser?
    
    /**
     Dictionary which maps a OCKContact to the messages exchanged between the contact and the user.
     */
    fileprivate var messages: [String: [OCKConnectMessageItem]] = [:]
    fileprivate let dateFormatter = DateFormatter()
    fileprivate var initialTimeStamp: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Extracting the name of the Plist file which needs to be parsed from Info.plist
        guard let plistName = Bundle.main.infoDictionary?["CareKit Prototyper Plist Name"] as? String, plistName != "" else {
            fatalError("Could not get the name of the Plist file, please verify the value of `CareKit Prototyper Plist Name` in the Info.plist file.")
        }
        
        guard let store = CarePlanStoreManager.shared.createAndSetupStore(forPlist: plistName) else {
            fatalError("failed to create a Care Plan Store!")
        }
        storeReference = store
        storeReference?.delegate = self
        let plistObject = PlistParser(withPlist: plistName)
        plistObjectReference = plistObject
        
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        initialTimeStamp = dateFormatter.string(from: Date())
        
        // Initialize CareContents View Controller with the corresponding careContentUI block from plistObject
        let careContentsVC = OCKCareContentsViewController(withCarePlanStore: store,
                                                           andCustomizationObject: plistObject.careContentUI)
        careContentsVC.delegate = self
        self.viewControllers = [(UINavigationController(rootViewController: careContentsVC))]
        
        // Initialize Insights View Controller only if the corresponding insights object was retrieved from the plist
        if plistObject.insights != nil {
            let insightsVC = OCKInsightsViewController(withCarePlanStore: store,
                                                       insightObject: plistObject.insights,
                                                       andCustomizationObject: plistObject.insightsUI)
            self.viewControllers?.append(UINavigationController(rootViewController: insightsVC))
        }
        
        // Initialize Contacts View Controller only if the corresponding contacts object was retrieved from the plist
        if let contactsObject = plistObject.contacts {
            var contacts = [OCKContact]()
            for object in contactsObject {
                contacts.append(OCKContact(withObject: object as? [String : Any]))
            }
            let patient = plistObject.patient == nil ? nil : OCKPatient(withObject: plistObject.patient,
                                                                        andStore: store)
            let contactsVC = OCKConnectViewController(contacts: contacts.count == 0 ? nil : contacts,
                                                      patient: patient,
                                                      andCustomizationObject: plistObject.connectUI)
            contactsVC.dataSource = self
            contactsVC.delegate = self
            self.viewControllers?.append(UINavigationController(rootViewController: contactsVC))
        }
    }
}

//MARK: OCKCareContentsViewControllerDelegate
extension TabBarViewController: OCKCareContentsViewControllerDelegate {
    func careContentsViewController(_ viewController: OCKCareContentsViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
        let alert = UIAlertController(title: "Enter a value", message: assessmentEvent.activity.text, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.keyboardType = .decimalPad
        }
        let doneAction = UIAlertAction(title: "Done", style: .default) { [unowned self] _ in
            let valueOfTextField = alert.textFields![0]
            if let enteredValue = valueOfTextField.text, enteredValue != "" {
                let result = OCKCarePlanEventResult(valueString: enteredValue, unitString: "", userInfo: nil, values: [NSNumber(value: Double(enteredValue)!)])
                self.storeReference?.update(assessmentEvent, with: result, state: .completed) { (_, _, error) in
                    if let error = error {
                        NSLog(error.localizedDescription)
                    }
                }
            }
        }
        alert.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

//MARK: OCKConnectViewControllerDataSource
extension TabBarViewController: OCKConnectViewControllerDataSource {
    func connectViewControllerCareTeamConnections(_ viewController: OCKConnectViewController) -> [OCKContact] {
        guard let plistObject = plistObjectReference, let contactsObject = plistObject.contacts else {
            fatalError("could not access the contacts object, maybe no Contacts information was provided in the plist?")
        }
        var contacts = [OCKContact]()
        for object in contactsObject {
            contacts.append(OCKContact(withObject: object as? [String : Any]))
        }
        return contacts
    }
    
    func connectViewController(_ viewController: OCKConnectViewController, connectMessageItemAt index: Int, careTeamContact contact: OCKContact) -> OCKConnectMessageItem {
        if index == 0 {
            return OCKConnectMessageItem(messageType: .received, name: contact.name, message: "Hello", dateString: initialTimeStamp!)
        } else {
            guard let arrayOfMessages = messages[contact.name] else {
                fatalError("could not extract message conversation for the contact - \(contact.name)")
            }
            return arrayOfMessages[index-1]
        }
    }
    
    func connectViewControllerNumber(ofConnectMessageItems viewController: OCKConnectViewController, careTeamContact contact: OCKContact) -> Int {
        return ((((messages[contact.name])?.count) ?? 0) + 1)
    }
}


//MARK: OCKConnectViewControllerDelegate
extension TabBarViewController: OCKConnectViewControllerDelegate {
    
    func connectViewController(_ connectViewController: OCKConnectViewController, didSelectShareButtonFor contact: OCKContact, presentationSourceView sourceView: UIView?) {
        let document = OCKDocument(withObject: plistObjectReference?.insights)
        document.pageHeader = "Intended recepient of this report - \(contact.name)"
        let documentDisplayVC = self.storyboard?.instantiateViewController(withIdentifier: "documentsDisplay") as? DocumentsDisplayViewController
        documentDisplayVC?.documentObject = document
        self.present(documentDisplayVC!, animated: true, completion: nil)
    }
    
    func connectViewController(_ connectViewController: OCKConnectViewController, titleForSharingCellFor contact: OCKContact) -> String? {
        return "Display Generated Insights Report"
    }
    
    func connectViewController(_ viewController: OCKConnectViewController, didSendConnectMessage message: String, careTeamContact contact: OCKContact) {
        let dateTimeString = dateFormatter.string(from: Date())
        if messages[contact.name] == nil {
            messages[contact.name] = [OCKConnectMessageItem(messageType: .sent, name: "Me", message: message, dateString: dateTimeString)]
        } else {
            var allMessages = messages[contact.name] ?? []
            allMessages.append(OCKConnectMessageItem(messageType: .sent, name: "Me", message: message, dateString: dateTimeString))
            messages[contact.name] = allMessages
        }
    }
}

//MARK: OCKCarePlanStoreDelegate
extension TabBarViewController: OCKCarePlanStoreDelegate {
    func carePlanStore(_ store: OCKCarePlanStore, didReceiveUpdateOf event: OCKCarePlanEvent) {
        if event.activity.type == .assessment {
            let triggeredThresholds = event.evaluateNumericThresholds()
            for thresholdArray in triggeredThresholds {
                for threshold in thresholdArray {
                    NSLog("Threshold triggered on event \(event.occurrenceIndexOfDay) of \(event.date) for activity \(event.activity.identifier) with title:\n\(threshold.title!)")
                }
            }
        }
    }
}

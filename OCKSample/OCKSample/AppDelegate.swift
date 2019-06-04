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
import CareKit
import Contacts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // Manages synchronization of a CoreData store
    lazy var manager: OCKSynchronizedStoreManager<OCKStore> = {
        let store = OCKStore(name: "SampleAppStore")
        let manager = OCKSynchronizedStoreManager(wrapping: store)
        manager.populateSampleData()
        return manager
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let careViewController = CareViewController(storeManager: manager)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: careViewController)
        window?.tintColor = #colorLiteral(red: 0.9960784314, green: 0.3725490196, blue: 0.368627451, alpha: 1)
        window?.makeKeyAndVisible()
        
        return true
    }
}

private extension OCKSynchronizedStoreManager where Store == OCKStore {
    
    // Adds tasks and contacts into the store
    func populateSampleData() {
    
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value:  -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: aFewDaysAgo)!
        
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil,
                               interval: DateComponents(day: 1)),
            
            OCKScheduleElement(start: afterLunch, end: nil,
                               interval: DateComponents(day: 2))
        ])
        
        var doxylamine = OCKTask(identifier: "doxylamine", title: "Take Doxylamine",
                             carePlanID: nil, schedule: schedule)
        doxylamine.instructions = "Take 25mg of doxylamine when you experience nausea."
        
        let nauseaSchedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil,
                               interval: DateComponents(day: 1),
                               text: "Anytime throughout the day", targetValues: [], isAllDay: true)
            ])
        
        var nausea = OCKTask(identifier: "nausea", title: "Track your nausea",
                             carePlanID: nil, schedule: nauseaSchedule)
        nausea.impactsAdherence = false
        nausea.instructions = "Tap the button below anytime you experience nausea."
        
        store.addTasks([nausea, doxylamine])
        
        var contact1 = OCKContact(identifier: "jane", givenName: "Jane",
                                  familyName: "Daniels", carePlanID: nil)
        contact1.asset = "JaneDaniels"
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@icloud.com")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        
        contact1.address = {
            let address = OCKPostalAddress()
            address.street = "2598 Reposa Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()
        
        var contact2 = OCKContact(identifier: "matthew", givenName: "Matthew",
                                  familyName: "Reiff", carePlanID: nil)
        contact2.asset = "MatthewReiff"
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(324) 555-7415")]
        contact2.address = {
            let address = OCKPostalAddress()
            address.street = "396 El Verano Way"
            address.city = "San Francisco"
            address.state = "CA"
            address.postalCode = "94127"
            return address
        }()
        
        store.addContacts([contact1, contact2])
    }
}



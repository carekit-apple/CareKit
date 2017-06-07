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


import CareKit


/**
 @brief Singleton class which handles creation and initialization of CarePlanStore with activities parsed from the provided Plist file.
 */
class CarePlanStoreManager {
    // shared instance of the singleton class
    static let shared = CarePlanStoreManager()
    
    private var plistObject: PlistParser?
    private var store: OCKCarePlanStore?
    
    /**
     This function accepts the name of the Plist file, creates a CarePlanStore associated with the plist name, adds all the
     activity objects parsed from the plist file into the CarePlanStore and returns a reference to the CarePlanStore.
     - Parameter forPlist: Name of the plist file which needs to be parsed.
     - returns: A reference to the CarePlanStore which was created for the corresponding plist name.
     */
    func createAndSetupStore(forPlist plistName: String) -> OCKCarePlanStore? {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("We were unable to get a URL from document directory!")
        }
        let storeURL = documentDirectory.appendingPathComponent(plistName)
        var willAddActivites = true
        guard let bundleVersionFromPlist = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String, bundleVersionFromPlist != "" else {
            fatalError("Unable to access the contents of Info.plist file.")
        }
        if let bundleVersionFromContainer = UserDefaults.standard.value(forKey: "bundleVersionInContainer") as? String {
            if bundleVersionFromContainer != bundleVersionFromPlist {
                // Remove the CarePlanStore during every build and run, this avoids displaying any stale data.
                try? fileManager.removeItem(at: storeURL)
            } else {
                // Do not re-add activities while re-launching the app after force-kill.
                willAddActivites = false
            }
        }
        do {
            try fileManager.createDirectory(at: storeURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            fatalError("Failed to create a directory at the specified URL due to - \(error.localizedDescription)")
        }
        UserDefaults.standard.set(bundleVersionFromPlist, forKey: "bundleVersionInContainer")
        RandomNumberGeneratorHelper.shared.generateRandomDistribution()
        store = OCKCarePlanStore(persistenceDirectoryURL: storeURL)
        if willAddActivites {
            plistObject = PlistParser(withPlist: plistName)
            addActivitiesToStore()
        }
        return store
    }
    
    /**
     A private helper functions which add all the activities parsed from the plist file to the CarePlanStore.
     */
    private func addActivitiesToStore() {
        guard let activities = plistObject?.activities else {
            fatalError("Failed to extract the `Care Contents` object from the plist file, please verify if the `Care Contents` field in populated correctly.")
        }
        var listOfUniqueIdentifiers = [String]()
        var positionOfActivity = 0
        for case var object as [String : Any] in activities {
            positionOfActivity += 1
            // This is to allow copy pasting of activities in the plist, each object needs a UUID.
            guard let objectID = object[PlistConstants.Activity.Keys.identifier] as? String, objectID != "" else {
                fatalError("Failed to extract the `indentifier` field in the plist file for the activity element in position - \(positionOfActivity), please verify that a valid value was entered.")
            }
            guard let objectTitle = object[PlistConstants.Activity.Keys.title] as? String, objectTitle != "" else {
                fatalError("Failed to extract the `title` field in the plist file for the activity element in position - \(positionOfActivity), please verify that a valid value was entered.")
            }
            if listOfUniqueIdentifiers.contains(objectID) {
                let randomID = String.generateTitle()
                object[PlistConstants.Activity.Keys.identifier] = randomID
                object[PlistConstants.Activity.Keys.title] = (objectTitle + "- \(RandomNumberGeneratorHelper.shared.getSequenceCount())")
            } else {
                listOfUniqueIdentifiers.append(objectID)
            }
            let activity = OCKCarePlanActivity(withObject: object)
            store?.activity(forIdentifier: activity.identifier, completion: { [unowned self] (_, foundActivity, error) in
                if let err = error {
                    NSLog(err.localizedDescription)
                } else {
                    // Only add an activity if it doesn't already exist in the CarePlanStore.
                    if foundActivity == nil {
                        self.store?.add(activity, completion: { (_, error) in
                            if let err = error {
                                NSLog(err.localizedDescription)
                            }
                        })
                    }
                }
            })
        }
    }
}

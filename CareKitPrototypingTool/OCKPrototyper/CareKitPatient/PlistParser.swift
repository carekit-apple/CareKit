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


import Foundation


/**
 Create an object of this class by passing in the name of the plist file which needs to be parsed to the initializer. The public properties of this class
 represent different sections of the Plist file which correspond to the key View Controllers provided by CareKit.
 */
class PlistParser {
    
    var activities: [Any]?
    var contacts: [Any]?
    var insights: [String : Any]?
    var patient: [String : Any]?
    
    // these objects define UI properties like title, image, etc for the View Controllers.
    var careContentUI: [String : Any]?
    var insightsUI: [String : String]?
    var connectUI: [String : String]?
    
    init(withPlist plist: String) {
        if let path = Bundle.main.path(forResource: plist, ofType: "plist"), let plistObject = NSDictionary(contentsOfFile: path) as? [String : Any] {
            
            patient = plistObject[PlistConstants.Root.patient] as? [String : Any]
            activities = plistObject[PlistConstants.Root.activities] as? [Any]
            insights = plistObject[PlistConstants.Root.insight] as? [String : Any]
            contacts = plistObject[PlistConstants.Root.connect] as? [Any]
            
            guard let tabBarItemInfo = plistObject[PlistConstants.Root.viewControllerCustomization] as? [String : Any] else {
                NSLog("UI Customization field in the Plist file was not found.")
                return
            }
            careContentUI = tabBarItemInfo[PlistConstants.Customization.careContent] as? [String : Any]
            insightsUI = tabBarItemInfo[PlistConstants.Customization.insights] as? [String : String]
            connectUI = tabBarItemInfo[PlistConstants.Customization.connect] as? [String : String]
        } else {
            fatalError("Failed to locate the Plist file, please verify the name of plist file in Info.plist.")
        }
    }
}

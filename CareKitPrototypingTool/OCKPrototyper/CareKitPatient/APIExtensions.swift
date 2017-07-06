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
import CareKit


//MARK: OCKCareContentsViewController
extension OCKCareContentsViewController {
    /**
     A convenience initializer for creating an instance of OCKCareContentsViewController.
     - Parameter store: Reference to the CarePlanStore accessible using CarePlanStoreHelper singleton.
     - Parameter object: Represents the `careContentUI` section of the Plist file.
     */
    convenience init(withCarePlanStore store: OCKCarePlanStore, andCustomizationObject object: [String : Any]?) {
        self.init(carePlanStore: store)
        self.title = object?[PlistConstants.Customization.Keys.title] as? String ?? String.generateTitle()
        self.tabBarItem = UITabBarItem(title: self.title,
                                       image: UIImage(named: object?[PlistConstants.Customization.Keys.image] as? String ?? ""),
                                       selectedImage: UIImage(named: object?[PlistConstants.Customization.Keys.selectedImage] as? String ?? ""))
        let glyphTypeString = (object?[PlistConstants.Customization.CareContentUI.glyphType] as? String ?? "").lowercased()
        self.glyphType = OCKGlyphType.glyphType(forString: glyphTypeString)
        self.glyphTintColor = UIColor(netHex: object?[PlistConstants.Customization.CareContentUI.glyphTintColor] as? Int ?? 0)
        self.readOnlySectionHeader = object?[PlistConstants.Customization.CareContentUI.readOnlyHeader] as? String
        self.optionalSectionHeader = object?[PlistConstants.Customization.CareContentUI.optionalHeader] as? String
    }
}

//MARK: OCKGlyphType
extension OCKGlyphType {
    static let all = [ "heart",
                       "accessibility",
                       "activelife",
                       "adultlearning",
                       "awareness",
                       "blood",
                       "bloodpressure",
                       "cardio",
                       "childlearning",
                       "dentalhealth",
                       "femalehealth",
                       "hearing",
                       "homecare",
                       "infantcare",
                       "laboratory",
                       "malehealth",
                       "maternalhealth",
                       "medication",
                       "mentalhealth",
                       "neuro",
                       "nutrition",
                       "optometry",
                       "pediatrics",
                       "physicaltherapy",
                       "podiatry",
                       "respiratoryhealth",
                       "scale",
                       "stethoscope",
                       "syringe"
    ]
    
    /**
     A helper function to map a string to a OCKGlyphType
     - Parameter forString: Represents the string value entered in the `glyphType` section of the CareContentsUI.
     */
    static func glyphType(forString enteredString: String) -> OCKGlyphType {
        return OCKGlyphType(rawValue: OCKGlyphType.all.index(of: enteredString) ?? 0)!
    }
}

//MARK: OCKCarePlanThresholdType
extension OCKCarePlanThresholdType {
    static let all = [ "adherence",
                       "greaterthan",
                       "greaterthanorequal",
                       "lessthan",
                       "lessthanorequal",
                       "equal",
                       "rangeinclusive",
                       "rangeexclusive"
    ]
    
    /**
     A helper function to map a string to a OCKCarePlanThresholdType
     - Parameter forString: Represents the string value entered in the `type` field of the `thresholds` section in CareContents.
     */
    static func thresholdType(forString enteredString: String) -> OCKCarePlanThresholdType {
        return OCKCarePlanThresholdType(rawValue: OCKCarePlanThresholdType.all.index(of: enteredString) ?? 0)!
    }
}

//MARK: OCKInsightsViewController
extension OCKInsightsViewController {
    /**
     A convenience initializer for creating an instance of OCKCareContentsViewController.
     - Parameter store: Reference to the CarePlanStore accessible using CarePlanStoreHelper singleton.
     - Parameter insightObject: Represents the `Insights` section of the Plist file.
     - Parameter object: Represents the `insightsUI` section of the Plist file.
     */
    convenience init(withCarePlanStore store: OCKCarePlanStore, insightObject: [String : Any]?,  andCustomizationObject object: [String : String]?) {
        var insightItemArray = [OCKInsightItem]()
        var patientWidgetArray = [OCKPatientWidget]()
        
        if insightObject != nil {
            // Parse the insightObject for `rings` section and then use it to create OCKRingItem
            let ringItem = insightObject?[PlistConstants.Insights.rings] as? [Any]
            for case let ring as [String : Any] in ringItem ?? [] {
                insightItemArray.append(OCKRingItem(title: ring[PlistConstants.Insights.Rings.title] as? String,
                                                    text: ring[PlistConstants.Insights.Rings.text] as? String,
                                                    tintColor: UIColor(netHex: ring[PlistConstants.Insights.Rings.tintColor] as? Int ?? 0),
                                                    value: ring[PlistConstants.Insights.Rings.value] as! Double,
                                                    glyphType: OCKGlyphType.glyphType(forString: (ring[PlistConstants.Insights.Rings.glyphType] as? String ?? "").lowercased()),
                                                    glyphFilename: nil))
            }
            // Parse the insightObject for `message` section and then use it to create OCKMessageItem
            let messageItem = insightObject?[PlistConstants.Insights.message] as? [Any]
            for case let objectMessage as [String : Any] in messageItem ?? [] {
                insightItemArray.append(OCKMessageItem(withObject: objectMessage))
            }
            // Parse the insightObject for `charts` section and then use it to create OCKBarChart
            let chartItem = insightObject?[PlistConstants.Insights.charts] as? [String : Int]
            for _ in 0..<Int(chartItem?[PlistConstants.Insights.Charts.numberOfCharts] ?? 0) {
                insightItemArray.append(OCKBarChart(withObject: chartItem))
            }
            // Parse the insightObject for `widgets` section and then use it to create OCKPatientWidget
            let widgetItem = insightObject?[PlistConstants.Insights.widgets] as? [Any]
            if widgetItem?.count ?? 0 > 3 {
                fatalError("We do not support more than 3 widgets, please remove extra widget elements from the `widgets` sections under `Insights` from the Plist file.")
            }
            var widgetCount = 0
            for case let widgets as [String : Any] in widgetItem ?? [] {
                guard let widgetTitle = widgets[PlistConstants.Insights.Widgets.title] as? String, widgetTitle != "" else {
                    fatalError("No title was provided for the widget element in position - \(widgetCount) under the `patientWidgets` -> `Insights` section of the Plist file.")
                }
                guard let widgetText = widgets[PlistConstants.Insights.Widgets.text] as? String, widgetText != "" else {
                    fatalError("No text was provided for the widget element in position - \(widgetCount) under the `patientWidgets` -> `Insights` section of the Plist file.")
                }
                widgetCount += 1
                patientWidgetArray.append(OCKPatientWidget.defaultWidget(withTitle: widgetTitle,
                                                                         text: widgetText,
                                                                         tintColor: UIColor(netHex: widgets[PlistConstants.Insights.Widgets.tintColor] as? Int ?? 0)))
            }
        }
        
        var thresholdActivityIdentifiers = [String]()
        // block till you get the necessary activity identifiers
        let semaphore = DispatchSemaphore(value: 0)
        store.activities { (_, activities, error) in
            if let err = error {
                NSLog(err.localizedDescription)
            }
            for activity in activities {
                if activity.thresholds != nil {
                    thresholdActivityIdentifiers.append(activity.identifier)
                }
            }
            semaphore.signal()
        }
        let _ = semaphore.wait(timeout: .distantFuture)
        
        self.init(insightItems: insightItemArray,
                  patientWidgets: patientWidgetArray,
                  thresholds: thresholdActivityIdentifiers,
                  store: store)
        self.title = object?[PlistConstants.Customization.Keys.title] ?? String.generateTitle()
        self.tabBarItem = UITabBarItem(title: self.title,
                                       image: UIImage(named: object?[PlistConstants.Customization.Keys.image] ?? ""),
                                       selectedImage: UIImage(named: object?[PlistConstants.Customization.Keys.selectedImage] ?? ""))
    }
}

//MARK: OCKConnectViewController
extension OCKConnectViewController {
    /**
     A convenience initializer for creating an instance of OCKConnectViewController.
     - Parameter contacts: An array of OCKContact objects which will be displayed in the OCKConnectViewController.
     - Parameter patient: OCKPatient object constructed using the `Patient Info` section of the Plist file.
     - Parameter object: Represents the `connectUI` section of the Plist file.
     */
    convenience init(contacts: [OCKContact]?, patient: OCKPatient?, andCustomizationObject object: [String : String]?) {
        self.init(contacts: contacts,
                  patient: patient)
        self.title = object?[PlistConstants.Customization.Keys.title] ?? String.generateTitle()
        self.tabBarItem = UITabBarItem(title: self.title,
                                       image: UIImage(named: object?[PlistConstants.Customization.Keys.image] ?? ""),
                                       selectedImage: UIImage(named: object?[PlistConstants.Customization.Keys.selectedImage] ?? ""))
    }
}

//MARK: OCKBarChart
extension OCKBarChart {
    /**
     A convenience initializer for creating an instance of OCKBarChart.
     - Parameter object: Represents the `charts` section under `Insights` section of the Plist file.
     */
    convenience init(withObject object: [String : Int]?) {
        var chartSeries = [OCKBarSeries]()
        var axisTitles = [String]()
        var axisSubtitles = [String]()
        let numberOfDataPoints = Int(object?[PlistConstants.Insights.Charts.numberOfSets] ?? 0)
        for _ in 0..<Int(object?[PlistConstants.Insights.Charts.numberOfSeries] ?? 0) {
            var values = [Int]()
            var valueLabels = [String]()
            for _ in 0..<numberOfDataPoints {
                let val = RandomNumberGeneratorHelper.shared.getRandomValue()
                values.append(val)
                valueLabels.append("\(val)")
            }
            let chart = OCKBarSeries(title: String.generateTitle(),
                                     values: values as [NSNumber],
                                     valueLabels: valueLabels,
                                     tintColor: UIColor.generateRandom())
            chartSeries.append(chart)
        }
        for _ in 0..<numberOfDataPoints {
            axisTitles.append("Day")
            axisSubtitles.append("Date")
        }
        self.init(title: String.generateTitle(),
                  text: String.generateTitle(),
                  tintColor: UIColor.generateRandom(),
                  axisTitles: axisTitles,
                  axisSubtitles: axisSubtitles,
                  dataSeries: chartSeries,
                  minimumScaleRangeValue: NSNumber(integerLiteral: object?[PlistConstants.Insights.Charts.minimumScaleRange] ?? 0),
                  maximumScaleRangeValue: NSNumber(integerLiteral: object?[PlistConstants.Insights.Charts.maximumScaleRange] ?? 100))
    }
}

//MARK: OCKMessageItem
extension OCKMessageItem {
    /**
     A convenience initializer for creating an instance of OCKMessageItem.
     - Parameter object: Represents the `message` section under `Insights` section of the Plist file.
     */
    convenience init(withObject object: [String : Any]?) {
        self.init(title: object?[PlistConstants.Insights.Message.title] as? String,
                  text: object?[PlistConstants.Insights.Message.text] as? String,
                  tintColor: UIColor(netHex: object?[PlistConstants.Insights.Message.tintColor] as? Int ?? 0),
                  messageType: OCKMessageItemType.messageType(forString: (object?[PlistConstants.Insights.Message.type] as? String ?? "").lowercased()))
    }
}

//MARK: OCKMessageItemType
extension OCKMessageItemType {
    static let all = [ "tip",
                       "alert",
                       "plain"
    ]
    
    /**
     A helper function to map a string to a OCKMessageItemType
     - Parameter forString: Represents the string value entered in the `type` field of the `message` section in Insights.
     */
    static func messageType(forString enteredString: String) -> OCKMessageItemType {
        return OCKMessageItemType(rawValue: OCKMessageItemType.all.index(of: enteredString) ?? 0)!
    }
}

//MARK: OCKPatient
extension OCKPatient {
    /**
     A convenience initializer for creating an instance of OCKPatient.
     - Parameter patientInfo: Represents the `Patient Info` section of the Plist file.
     - Parameter store: Reference to the CarePlanStore accessible using CarePlanStoreHelper singleton.
     */
    convenience init(withObject patientInfo: [String : Any]?, andStore store: OCKCarePlanStore) {
        guard let patientIdentifier = patientInfo?[PlistConstants.PatientInfo.Keys.identifier] as? String, patientIdentifier != "" else {
            fatalError("No value for `identifier` was provided under the `Patient Info` section of the Plist file.")
        }
        guard let patientName = patientInfo?[PlistConstants.PatientInfo.Keys.name] as? String, patientName != "" else {
            fatalError("No value for `name` was provided under the `Patient Info` section of the Plist file.")
        }
        guard let patientMonogram = patientInfo?[PlistConstants.PatientInfo.Keys.monogram] as? String, patientMonogram != "" else {
            fatalError("No value for `monogram` was provided under the `Patient Info` section of the Plist file.")
        }
        self.init(identifier: patientIdentifier,
                  carePlanStore: store,
                  name: patientName,
                  detailInfo: patientInfo?[PlistConstants.PatientInfo.Keys.detailInfo] as? String,
                  careTeamContacts: nil,
                  tintColor: UIColor(netHex: patientInfo?[PlistConstants.PatientInfo.Keys.tintColor] as? Int ?? 0),
                  monogram: patientMonogram,
                  image: UIImage(named: patientInfo?[PlistConstants.PatientInfo.Keys.image] as? String ?? ""),
                  categories: nil,
                  userInfo: [String.generateTitle(): String.generateTitle()])
    }
}

//MARK: OCKContact
extension OCKContact {
    /**
     A convenience initializer for creating an instance of OCKContact.
     - Parameter object: Represents the `Contacts` section of the Plist file.
     */
    convenience init(withObject object: [String : Any]?) {
        var contactInfoItems = [OCKContactInfo]()
        if let contactInfoObject = object?[PlistConstants.Contacts.contactInfoItems] as?  [String : String]
        {
            if let email = contactInfoObject[PlistConstants.Contacts.ContactInfoItems.email], email != "" {
                contactInfoItems.append(OCKContactInfo.email(email))
            }
            if let phone = contactInfoObject[PlistConstants.Contacts.ContactInfoItems.phone], phone != "" {
                contactInfoItems.append(OCKContactInfo.phone(phone))
            }
            if let sms = contactInfoObject[PlistConstants.Contacts.ContactInfoItems.sms], sms != "" {
                contactInfoItems.append(OCKContactInfo.sms(sms))
            }
            if let facetimeAudio = contactInfoObject[PlistConstants.Contacts.ContactInfoItems.facetimeAudio], facetimeAudio != "" {
                contactInfoItems.append(OCKContactInfo.facetimeAudio(facetimeAudio, display: facetimeAudio))
            }
            if let facetimeVideo = contactInfoObject[PlistConstants.Contacts.ContactInfoItems.facetimeVideo], facetimeVideo != "" {
                contactInfoItems.append(OCKContactInfo.facetimeVideo(facetimeVideo, display: facetimeVideo))
            }
        }
        guard let contactTypeString = object?[PlistConstants.Contacts.type] as? String, contactTypeString != "" else {
            fatalError("No value for `type` was provided under the `Contacts` section of the Plist file.")
        }
        guard let contactName = object?[PlistConstants.Contacts.name] as? String, contactName != "" else {
            fatalError("No value for `name` was provided under the `Contacts` section of the Plist file.")
        }
        guard let contactRelation = object?[PlistConstants.Contacts.relation] as? String, contactRelation != "" else {
            fatalError("No value for `relation` was provided under the `Contacts` section of the Plist file.")
        }
        guard let contactMonogram = object?[PlistConstants.Contacts.monogram] as? String, contactMonogram != "" else {
            fatalError("No value for `monogram` was provided under the `Contacts` section of the Plist file.")
        }
        self.init(contactType: OCKContactType(rawValue: contactTypeString == "personal" ? 1 : 0)!,
                  name: contactName,
                  relation: contactRelation,
                  contactInfoItems: contactInfoItems,
                  tintColor: UIColor(netHex: object?[PlistConstants.Contacts.tintColor] as? Int ?? 0),
                  monogram: contactMonogram,
                  image: UIImage(named: object?[PlistConstants.Contacts.image] as? String ?? ""))
    }
}

// MARK:- OCKCarePlanActivity
extension OCKCarePlanActivity {
    /**
     A convenience initializer for creating an instance of OCKCarePlanActivity.
     - Parameter object: Represents the `Care Contents` section of the Plist file.
     */
    convenience init(withObject object: [String : Any]?) {
        var type = OCKCarePlanActivityType.intervention
        guard let typeString = object?[PlistConstants.Activity.Keys.type] as? String, typeString != "" else {
            fatalError("No value for `type` was provided under the `Care Contents` section of the Plist file.")
        }
        switch typeString.lowercased() {
        case "assessment":
            type = .assessment
        case "intervention":
            type = .intervention
        case "readonly":
            type = .readOnly
        default:
            fatalError("The entered value for `type` is \(typeString), this does NOT comform to the following allowed types - assessment, intervention, assessmentReadOnly and interventionReadOnly")
        }
        let imageString = object?[PlistConstants.Activity.Keys.imageURL] as? String
        var url: URL?
        if let image = imageString, image != "" {
            let split = image.components(separatedBy: ".")
            if split.count != 2 {
                fatalError("Please provide the file type for the image mentioned in imageURL as well, ex- `HeartIcon.png`")
            }
            let imageName = split[0]
            let imageExtn = split[1]
            if let path = Bundle.main.path(forResource: imageName, ofType: imageExtn) {
                url = URL(fileURLWithPath: path)
            } else {
                fatalError("The `imageURL` entered was - \(image), this file was not found. Please verify that the file exists under the 'fileForImageURL' folder.")
            }
        }
        var thresholds = [OCKCarePlanThreshold]()
        let tempThreshold = object?[PlistConstants.Activity.Keys.thresholds] as? [Any]
        for case let object as [String : Any] in tempThreshold ?? [] {
            let thresholdTypeString = object[PlistConstants.Activity.Thresholds.type] as? String ?? ""
            thresholds.append(OCKCarePlanThreshold.numericThreshold(withValue: object[PlistConstants.Activity.Thresholds.value] as! NSNumber,
                                                                    type: OCKCarePlanThresholdType.thresholdType(forString: thresholdTypeString.lowercased()),
                                                                    upperValue: object[PlistConstants.Activity.Thresholds.upperValue] as? NSNumber,
                                                                    title: object[PlistConstants.Activity.Thresholds.title] as? String))
        }
        
        let scheduleObject = object?[PlistConstants.Activity.Keys.schedule] as? [String : Any]
        guard let objectStartDate = (scheduleObject?[PlistConstants.Activity.Schedule.startDate] as? [String: Int]) else {
            fatalError("No value for `activityStartDate` in `schedule` was provided under the `Care Contents` section of the Plist file.")
        }
        let startDate = DateComponents(year: objectStartDate[PlistConstants.Activity.Schedule.StartDate.year]!,
                                       month: objectStartDate[PlistConstants.Activity.Schedule.StartDate.month]!,
                                       day: objectStartDate[PlistConstants.Activity.Schedule.StartDate.day]!)
        if startDate.month! == 0 || startDate.day! == 0 || startDate.year! == 0 {
            fatalError("No valid value for `activityStartDate` in `schedule` was provided under the `Care Contents` section of the Plist file.")
        }
        var endDate: DateComponents?
        if let objectEndDate = (scheduleObject?[PlistConstants.Activity.Schedule.endDate] as? [String: Int]) {
            endDate =  DateComponents(year: objectEndDate[PlistConstants.Activity.Schedule.StartDate.year]!,
                                      month: objectEndDate[PlistConstants.Activity.Schedule.StartDate.month]!,
                                      day: objectEndDate[PlistConstants.Activity.Schedule.StartDate.day]!)
            if endDate?.month! == 0 || endDate?.day! == 0 || endDate?.year! == 0 {
                endDate = nil
            }
        }
        let occurences = scheduleObject?[PlistConstants.Activity.Schedule.occurences] as! [NSNumber]
        let weeksToSkip = scheduleObject?[PlistConstants.Activity.Schedule.weeksToSkip] as? UInt ?? 0
        
        guard let activityIdentifier = object?[PlistConstants.Activity.Keys.identifier] as? String, activityIdentifier != "" else {
            fatalError("No valid value for `identifier` was provided under the `Care Contents` section of the Plist file.")
        }
        guard let activityTitle = object?[PlistConstants.Activity.Keys.title] as? String, activityTitle != "" else {
            fatalError("No valid value for `title` was provided under the `Care Contents` section of the Plist file.")
        }
        self.init(identifier: activityIdentifier,
                  groupIdentifier: object?[PlistConstants.Activity.Keys.groupIdentifier] as? String,
                  type: type,
                  title: activityTitle,
                  text: object?[PlistConstants.Activity.Keys.text] as? String,
                  tintColor: UIColor(netHex: object?[PlistConstants.Activity.Keys.tintColor] as? Int ?? 0),
                  instructions: object?[PlistConstants.Activity.Keys.instructions] as? String,
                  imageURL: url,
                  schedule: OCKCareSchedule.weeklySchedule(withStartDate: startDate,
                                                           occurrencesOnEachDay: occurences,
                                                           weeksToSkip: weeksToSkip,
                                                           endDate: endDate),
                  resultResettable: object?[PlistConstants.Activity.Keys.resettable] as? Bool ?? false,
                  userInfo: nil,
                  thresholds: [thresholds],
                  optional: type == .readOnly ? true : object?[PlistConstants.Activity.Keys.optional] as! Bool)
    }
}

//MARK: OCKDocument
extension OCKDocument {
    /**
     A convenience initializer for creating an instance of OCKDocument.
     - Parameter object: Represents the `charts` section under `Insights` section of the Plist file.
     */
    convenience init(withObject object: [String : Any]?) {
        let subtitle = OCKDocumentElementSubtitle(subtitle: "First subtitle")
        let paragraph = OCKDocumentElementParagraph(content: "Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque.")
        let image = OCKDocumentElementImage(image: UIImage(named: "HeartIcon.png")!)
        let table = OCKDocumentElementTable(headers: [String.generateTitle(), String.generateTitle()], rows: [[String.generateTitle(), String.generateTitle()], [String.generateTitle(), String.generateTitle()]])
        let chartItem = object?[PlistConstants.Insights.charts] as? [String : Int]
        if chartItem != nil {
            let chart = OCKDocumentElementChart(chart: OCKBarChart(withObject: chartItem))
            self.init(title: "Sample Document Title", elements: [subtitle, paragraph, chart, table, image])
        } else {
            self.init(title: "Sample Document Title", elements: [subtitle, paragraph, table, image])
        }
    }
}


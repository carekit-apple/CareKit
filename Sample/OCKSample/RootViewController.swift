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
import ResearchKit
import WatchConnectivity

class RootViewController: UITabBarController {
    // MARK: Properties
    
    fileprivate let sampleData: SampleData
    
    fileprivate let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    
    fileprivate var careContentsViewController: OCKCareContentsViewController!
    
    fileprivate var insightsViewController: OCKInsightsViewController!
    
    fileprivate var connectViewController: OCKConnectViewController!
    
    fileprivate var watchManager: WatchConnectivityManager?

    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        sampleData = SampleData(carePlanStore: storeManager.store)
        
        super.init(coder: aDecoder)
        careContentsViewController = createCareContentsViewController()
        insightsViewController = createInsightsViewController()
        connectViewController = createConnectViewController()
        
        self.viewControllers = [
            UINavigationController(rootViewController: careContentsViewController),
            UINavigationController(rootViewController: insightsViewController),
            UINavigationController(rootViewController: connectViewController)
        ]
        
        storeManager.delegate = self
        watchManager = WatchConnectivityManager(withStore: storeManager.store)
        let glyphType = Glyph.glyphType(rawValue: careContentsViewController.glyphType.rawValue)
        
        // Default the default glyph tint color
        
        var glyphTintColor = OCKGlyph.defaultColor(for: careContentsViewController.glyphType)
        if (careContentsViewController.glyphTintColor != nil) {
            glyphTintColor = careContentsViewController.glyphTintColor
        }
        
        // Create color component array
        let glyphTintColorComponents = glyphTintColor.cgColor.components
        let glyphTintColorArray = [glyphTintColorComponents![0], glyphTintColorComponents![1], glyphTintColorComponents![2], glyphTintColorComponents![3]]
        watchManager?.glyphType = Glyph.imageNameForGlyphType(glyphType: glyphType!)
        watchManager?.glyphTintColor = glyphTintColorArray
        
        // Set the custom image name if the glyphType is custom
        if (careContentsViewController.glyphType == .custom) {
            let glyphImageName = careContentsViewController.customGlyphImageName
            if (glyphImageName != "") {
                watchManager?.glyphImageName = glyphImageName
            }
            
            watchManager?.sendGlyphType(glyphType: Glyph.imageNameForGlyphType(glyphType: glyphType!),
                                        glyphTintColor: glyphTintColorArray,
                                        glyphImageName: glyphImageName)
        } else {
            watchManager?.sendGlyphType(glyphType: Glyph.imageNameForGlyphType(glyphType: glyphType!), glyphTintColor: glyphTintColorArray)
        }
    }
    
    // MARK: Convenience
    
    fileprivate func createInsightsViewController() -> OCKInsightsViewController {
        // Create an `OCKInsightsViewController` with sample data.
        let activityType1: ActivityType = .backPain
        let activityType2: ActivityType = .bloodGlucose
        let activityType3: ActivityType = .weight
        let widget1 = OCKPatientWidget.defaultWidget(withActivityIdentifier: activityType1.rawValue, tintColor: OCKColor.red)
        let widget2 = OCKPatientWidget.defaultWidget(withActivityIdentifier: activityType2.rawValue, tintColor: OCKColor.red)
        let widget3 = OCKPatientWidget.defaultWidget(withActivityIdentifier: activityType3.rawValue, tintColor: OCKColor.red)
        
        let viewController = OCKInsightsViewController(insightItems: storeManager.insights, patientWidgets: [widget1, widget2, widget3], thresholds: [activityType1.rawValue], store:storeManager.store)
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Insights", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"insights"), selectedImage: UIImage(named: "insights-filled"))
        
        return viewController    }
    
    fileprivate func createCareContentsViewController() -> OCKCareContentsViewController {
        let viewController = OCKCareContentsViewController(carePlanStore: storeManager.store)
        viewController.title = NSLocalizedString("Care Contents", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"carecard"), selectedImage: UIImage(named: "carecard-filled"))
        viewController.noActivitiesText = NSLocalizedString("There are no activities to show!", comment: "")
        viewController.delegate = self;
        return viewController

    }

    fileprivate func createConnectViewController() -> OCKConnectViewController {
        let viewController = OCKConnectViewController.init(contacts: sampleData.contacts, patient: sampleData.patient)
        viewController.delegate = self
        viewController.dataSource = self
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Connect", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"connect"), selectedImage: UIImage(named: "connect-filled"))
        
        return viewController
    }
}


extension RootViewController: OCKCareContentsViewControllerDelegate {
    
    func careContentsViewController(_ viewController: OCKCareContentsViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
            // Lookup the assessment the row represents.
            guard let activityType = ActivityType(rawValue: assessmentEvent.activity.identifier) else { return }
            guard let sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else { return }
            
            /*
             Check if we should show a task for the selected assessment event
             based on its state.
             */
            guard assessmentEvent.state == .initial ||
                assessmentEvent.state == .notCompleted ||
                (assessmentEvent.state == .completed && assessmentEvent.activity.resultResettable) else { return }
            
            // Show an `ORKTaskViewController` for the assessment's task.
            let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRun: nil)
            taskViewController.delegate = self
            
            present(taskViewController, animated: true, completion: nil)
    }
    
    func careContentsViewController(_ viewController: OCKCareContentsViewController, selectedStateTextFor carePlanEvent: OCKCarePlanEvent, atButtonIndex index: Int) -> String? {
        return "OK!"
    }
    
    func careContentsViewController(_ viewController: OCKCareContentsViewController, deselectedStateTextFor carePlanEvent: OCKCarePlanEvent, atButtonIndex index: Int) -> String? {
        return ["AM", "PM"][index % 2]
    }
}

extension RootViewController: ORKTaskViewControllerDelegate {
    
    /// Called with then user completes a presented `ORKTaskViewController`.
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        defer {
            dismiss(animated: true, completion: nil)
        }
        
        // Make sure the reason the task controller finished is that it was completed.
        guard reason == .completed else { return }
        
        // Determine the event that was completed and the `SampleAssessment` it represents.
        guard let event = careContentsViewController.lastSelectedEvent,
            let activityType = ActivityType(rawValue: event.activity.identifier),
            let sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else { return }
        
        // Build an `OCKCarePlanEventResult` that can be saved into the `OCKCarePlanStore`.
        let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskViewController.result)
        
        // Check assessment can be associated with a HealthKit sample.
        if let healthSampleBuilder = sampleAssessment as? HealthSampleBuilder {
            // Build the sample to save in the HealthKit store.
            let sample = healthSampleBuilder.buildSampleWithTaskResult(taskViewController.result)
            let sampleTypes: Set<HKSampleType> = [sample.sampleType]
            
            // Requst authorization to store the HealthKit sample.
            let healthStore = HKHealthStore()
            healthStore.requestAuthorization(toShare: sampleTypes, read: sampleTypes, completion: { success, _ in
                // Check if authorization was granted.
                if !success {
                    /*
                        Fall back to saving the simple `OCKCarePlanEventResult`
                        in the `OCKCarePlanStore`.
                    */
                    self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
                    return
                }
                
                // Save the HealthKit sample in the HealthKit store.
                healthStore.save(sample, withCompletion: { success, _ in
                    if success {
                        /*
                            The sample was saved to the HealthKit store. Use it
                            to create an `OCKCarePlanEventResult` and save that
                            to the `OCKCarePlanStore`.
                         */
                        let healthKitAssociatedResult = OCKCarePlanEventResult(
                                quantitySample: sample,
                                quantityStringFormatter: nil,
                                display: healthSampleBuilder.unit,
                                displayUnitStringKey: healthSampleBuilder.localizedUnitForSample(sample),
                                userInfo: nil
                        )
                        
                        self.completeEvent(event, inStore: self.storeManager.store, withResult: healthKitAssociatedResult)
                    }
                    else {
                        /*
                            Fall back to saving the simple `OCKCarePlanEventResult`
                            in the `OCKCarePlanStore`.
                        */
                        self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
                    }
                    
                })
            })
        }
        else {
            // Update the event with the result.
            completeEvent(event, inStore: storeManager.store, withResult: carePlanResult)
        }
    }
    
    // MARK: Convenience
    
    fileprivate func completeEvent(_ event: OCKCarePlanEvent, inStore store: OCKCarePlanStore, withResult result: OCKCarePlanEventResult) {
        store.update(event, with: result, state: .completed) { success, _, error in
            if !success {
                print(error!.localizedDescription)
            }
        }
    }
}

// MARK: OCKConnectViewControllerDataSource

extension RootViewController: OCKConnectViewControllerDataSource {
    
    func connectViewControllerNumber(ofConnectMessageItems viewController: OCKConnectViewController, careTeamContact contact: OCKContact) -> Int {
        return sampleData.connectMessageItems.count
    }
    
    func connectViewControllerCareTeamConnections(_ viewController: OCKConnectViewController) -> [OCKContact] {
        return sampleData.contactsWithMessageItems
    }
    
    func connectViewController(_ viewController: OCKConnectViewController, connectMessageItemAt index: Int, careTeamContact contact: OCKContact) -> OCKConnectMessageItem {
        return sampleData.connectMessageItems[index]
    }
}

// MARK: OCKConnectViewControllerDelegate

extension RootViewController: OCKConnectViewControllerDelegate {
    
    /// Called when the user taps a contact in the `OCKConnectViewController`.
    func connectViewController(_ connectViewController: OCKConnectViewController, didSelectShareButtonFor contact: OCKContact, presentationSourceView sourceView: UIView?) {
        let document = sampleData.generateSampleDocument()
        document.createPDFData {(data, error) in
            let activityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
        
        func connectViewController(_ viewController: OCKConnectViewController, didSendConnectMessage message: String, careTeamContact contact: OCKContact) {
            let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            let connectMessage = OCKConnectMessageItem(messageType: .sent, name: sampleData.patient.name, message: message, dateString: dateString)
            sampleData.connectMessageItems.append(connectMessage)
        }
    }
    
    func connectViewController(_ viewController: OCKConnectViewController, didSendConnectMessage message: String, careTeamContact contact: OCKContact) {
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let connectMessage = OCKConnectMessageItem(messageType: .sent, name: sampleData.patient.name, message: message, dateString: dateString)
        sampleData.connectMessageItems.append(connectMessage)
    }
}


// MARK: CarePlanStoreManagerDelegate

extension RootViewController: CarePlanStoreManagerDelegate {
    
    /// Called when the `CarePlanStoreManager`'s insights are updated.
    func carePlanStoreManager(_ manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem]) {
        // Update the insights view controller with the new insights.
        insightsViewController.items = insights
    }
}

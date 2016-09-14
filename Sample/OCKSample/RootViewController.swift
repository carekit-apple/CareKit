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

import UIKit
import CareKit
import ResearchKit

class RootViewController: UITabBarController {
    // MARK: Properties
    
    private let sampleData: SampleData
    
    private let storeManager = CarePlanStoreManager.sharedCarePlanStoreManager
    
    private var careCardViewController: OCKCareCardViewController!
    
    private var symptomTrackerViewController: OCKSymptomTrackerViewController!
    
    private var insightsViewController: OCKInsightsViewController!
    
    private var connectViewController: OCKConnectViewController!
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        sampleData = SampleData(carePlanStore: storeManager.store)
        
        super.init(coder: aDecoder)
        
        careCardViewController = createCareCardViewController()
        symptomTrackerViewController = createSymptomTrackerViewController()
        insightsViewController = createInsightsViewController()
        connectViewController = createConnectViewController()
        
        self.viewControllers = [
            UINavigationController(rootViewController: careCardViewController),
            UINavigationController(rootViewController: symptomTrackerViewController),
            UINavigationController(rootViewController: insightsViewController),
            UINavigationController(rootViewController: connectViewController)
        ]
        
        storeManager.delegate = self
    }

    // MARK: Convenience
    
    private func createInsightsViewController() -> OCKInsightsViewController {
        // Create an `OCKInsightsViewController` with sample data.
        let headerTitle = NSLocalizedString("Weekly Charts", comment: "")
        let viewController = OCKInsightsViewController(insightItems: storeManager.insights, headerTitle: headerTitle, headerSubtitle: "")
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Insights", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"insights"), selectedImage: UIImage(named: "insights-filled"))
        
        return viewController
    }
    
    private func createCareCardViewController() -> OCKCareCardViewController {
        let viewController = OCKCareCardViewController(carePlanStore: storeManager.store)
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Care Card", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"carecard"), selectedImage: UIImage(named: "carecard-filled"))
        
        return viewController
    }
    
    private func createSymptomTrackerViewController() -> OCKSymptomTrackerViewController {
        let viewController = OCKSymptomTrackerViewController(carePlanStore: storeManager.store)
        viewController.delegate = self
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Symptom Tracker", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"symptoms"), selectedImage: UIImage(named: "symptoms-filled"))
        
        return viewController
    }
    
    private func createConnectViewController() -> OCKConnectViewController {
        let viewController = OCKConnectViewController(contacts: sampleData.contacts)
        viewController.delegate = self
        
        // Setup the controller's title and tab bar item
        viewController.title = NSLocalizedString("Connect", comment: "")
        viewController.tabBarItem = UITabBarItem(title: viewController.title, image: UIImage(named:"connect"), selectedImage: UIImage(named: "connect-filled"))
        
        return viewController
    }
}



extension RootViewController: OCKSymptomTrackerViewControllerDelegate {
    
    /// Called when the user taps an assessment on the `OCKSymptomTrackerViewController`.
    func symptomTrackerViewController(viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
        // Lookup the assessment the row represents.
        guard let activityType = ActivityType(rawValue: assessmentEvent.activity.identifier) else { return }
        guard let sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else { return }
        
        /*
            Check if we should show a task for the selected assessment event
            based on its state.
        */
        guard assessmentEvent.state == .Initial ||
            assessmentEvent.state == .NotCompleted ||
            (assessmentEvent.state == .Completed && assessmentEvent.activity.resultResettable) else { return }
        
        // Show an `ORKTaskViewController` for the assessment's task.
        let taskViewController = ORKTaskViewController(task: sampleAssessment.task(), taskRunUUID: nil)
        taskViewController.delegate = self
        
        presentViewController(taskViewController, animated: true, completion: nil)
    }
}



extension RootViewController: ORKTaskViewControllerDelegate {
    
    /// Called when the user completes a presented `ORKTaskViewController`.
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        defer {
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Make sure the reason the task controller finished is that it was completed.
        guard reason == .Completed else { return }
        
        // Determine the event that was completed
        guard let event = symptomTrackerViewController.lastSelectedAssessmentEvent else { return }

        carePlanResultWith(event: event, taskResult: taskViewController.result) { carePlanResult, _ in
            self.completeEvent(event, inStore: self.storeManager.store, withResult: carePlanResult)
        }
    }
    
    // MARK: Convenience

    // Generate an `OCKCarePlanEventResult` with given event and task result, saving it to HealthKit if appropriate
    private func carePlanResultWith(event event: OCKCarePlanEvent, taskResult:ORKTaskResult, completion: (carePlanResult: OCKCarePlanEventResult, savedToHealthKit: Bool) -> ()) {
        // The `SampleAssessment` this event represents.
        guard let activityType = ActivityType(rawValue: event.activity.identifier),
            sampleAssessment = sampleData.activityWithType(activityType) as? Assessment else { return }

        // Build an `OCKCarePlanEventResult` that can be saved into the `OCKCarePlanStore`.
        let carePlanResult = sampleAssessment.buildResultForCarePlanEvent(event, taskResult: taskResult)

        // Check assessment can be associated with a HealthKit sample.
        guard let healthSampleBuilder = sampleAssessment as? HealthSampleBuilder else {
            completion(carePlanResult: carePlanResult, savedToHealthKit: false)
            return
        }

        // Build the sample to save in the HealthKit store.
        let sample = healthSampleBuilder.buildSampleWithTaskResult(taskResult)
        let sampleTypes: Set<HKSampleType> = [sample.sampleType]

        // Requst authorization to store the HealthKit sample.
        let healthStore = HKHealthStore()
        healthStore.requestAuthorizationToShareTypes(sampleTypes, readTypes: sampleTypes) { success, _ in
            guard success else {
                 // Check if authorization was grante and fall back to the simple `OCKCarePlanEventResult`
                completion(carePlanResult: carePlanResult, savedToHealthKit: false)
                return
            }

            // Save the HealthKit sample in the HealthKit store.
            healthStore.saveObject(sample) { success, _ in
                guard success else {
                    // Fall back to the simple `OCKCarePlanEventResult`
                    completion(carePlanResult: carePlanResult, savedToHealthKit: false)
                    return
                }

                /*
                 The sample was saved to the HealthKit store. Use it
                 to create an `OCKCarePlanEventResult`
                 */
                let healthKitAssociatedResult = OCKCarePlanEventResult(
                    quantitySample: sample,
                    quantityStringFormatter: nil,
                    displayUnit: healthSampleBuilder.unit,
                    displayUnitStringKey: healthSampleBuilder.localizedUnitForSample(sample),
                    userInfo: nil
                )

                completion(carePlanResult: healthKitAssociatedResult, savedToHealthKit: true)
            }
        }
    }

    private func completeEvent(event: OCKCarePlanEvent, inStore store: OCKCarePlanStore, withResult result: OCKCarePlanEventResult) {
        store.updateEvent(event, withResult: result, state: .Completed) { success, _, error in
            if !success {
                print(error?.localizedDescription)
            }
        }
    }
}



extension RootViewController: OCKConnectViewControllerDelegate {
    
    /// Called when the user taps a contact in the `OCKConnectViewController`.
    func connectViewController(connectViewController: OCKConnectViewController, didSelectShareButtonForContact contact: OCKContact, presentationSourceView sourceView: UIView?) {
        let document = sampleData.generateSampleDocument()
        let activityViewController = UIActivityViewController(activityItems: [document], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView
        
        presentViewController(activityViewController, animated: true, completion: nil)
    }
}


extension RootViewController: CarePlanStoreManagerDelegate {
    
    /// Called when the `CarePlanStoreManager`'s insights are updated.
    func carePlanStoreManager(manager: CarePlanStoreManager, didUpdateInsights insights: [OCKInsightItem]) {
        // Update the insights view controller with the new insights.
        insightsViewController.items = insights
    }
}

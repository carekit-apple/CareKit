/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
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
#if !os(watchOS) && canImport(ResearchKit) && canImport(ResearchKitUI)

import CareKitStore
import CareKitUI
import ResearchKit
import ResearchKitUI
import UIKit

// MARK: OCKSurveyTaskViewControllerDelegate

public protocol OCKSurveyTaskViewControllerDelegate: AnyObject {

    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        for task: OCKAnyTask,
        didFinish result: Result<ORKTaskFinishReason, Error>)

    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        shouldAllowDeletingOutcomeForEvent event: OCKAnyEvent) -> Bool
}

public extension OCKSurveyTaskViewControllerDelegate {

    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        for task: OCKAnyTask,
        didFinish result: Result<ORKTaskFinishReason, Error>) {
        // No-op
    }

    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        shouldAllowDeletingOutcomeForEvent event: OCKAnyEvent) -> Bool {
        return true
    }
}

open class OCKSurveyTaskViewController: OCKTaskViewController<OCKSurveyTaskViewSynchronizer>, ORKTaskViewControllerDelegate {

    private let extractOutcome: (ORKTaskResult) -> [OCKOutcomeValue]?

    public let survey: ORKTask

    public weak var surveyDelegate: OCKSurveyTaskViewControllerDelegate?

    @available(*, unavailable, renamed: "init(query:store:survey:viewSynchronizer:extractOutcome:)")
    public convenience init(
        task: OCKAnyTask,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager,
        survey: ORKTask,
        viewSynchronizer: OCKSurveyTaskViewSynchronizer = OCKSurveyTaskViewSynchronizer(),
        extractOutcome: @escaping (ORKTaskResult) -> [OCKOutcomeValue]?
    ) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, renamed: "init(query:store:survey:viewSynchronizer:extractOutcome:)")
    public init(
        taskID: String,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager,
        survey: ORKTask,
        viewSynchronizer: OCKSurveyTaskViewSynchronizer = OCKSurveyTaskViewSynchronizer(),
        extractOutcome: @escaping (ORKTaskResult) -> [OCKOutcomeValue]?
    ) {
        fatalError("Unavailable")
    }

    public init(
        eventQuery: OCKEventQuery,
        store: OCKAnyStoreProtocol,
        survey: ORKTask,
        viewSynchronizer: OCKSurveyTaskViewSynchronizer = OCKSurveyTaskViewSynchronizer(),
        extractOutcome: @escaping (ORKTaskResult) -> [OCKOutcomeValue]?
    ) {
        self.survey = survey
        self.extractOutcome = extractOutcome
        super.init(query: eventQuery, store: store, viewSynchronizer: viewSynchronizer)
    }

    override open func taskView(
        _ taskView: UIView & OCKTaskDisplayable,
        didCompleteEvent isComplete: Bool,
        at indexPath: IndexPath,
        sender: Any?) {
    
            guard isComplete else {

                let event = viewModel[indexPath.section][indexPath.row]

                let shouldDeleteOutcome = surveyDelegate?.surveyTask(
                    viewController: self,
                    shouldAllowDeletingOutcomeForEvent: event
                )

                guard shouldDeleteOutcome == true else { return }
                
                let cancelAction = UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: nil
                )
                
                let confirmAction = UIAlertAction(
                    title: "Delete",
                    style: .destructive
                ) { _ in

                    super.taskView(
                        taskView,
                        didCompleteEvent: isComplete,
                        at: indexPath,
                        sender: sender
                    )
                }
                
                let warningAlert = UIAlertController(
                    title: "Delete",
                    message: "Are you sure you want to delete your response?",
                    preferredStyle: .actionSheet
                )
                
                warningAlert.addAction(cancelAction)
                warningAlert.addAction(confirmAction)
                
                /*
                 TODO: Remove in the future. Explicitly setting the tint color here to support
                 current developers that have a SwiftUI lifecycle app and wrap this view
                 controller in a `UIViewControllerRepresentable` implementation...Tint color
                 is not propagated...etc.
                 */
                warningAlert.view.tintColor = determineTintColor(from: view)
                present(warningAlert, animated: true, completion: nil)
                
                return
                
            }

            let surveyViewController = ORKTaskViewController(
                task: survey,
                taskRun: nil
            )

            let directory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).last!.appendingPathComponent("ResearchKit", isDirectory: true)

                surveyViewController.outputDirectory = directory
                /*
                 TODO: Remove in the future. Explicitly setting the tint color here to support
                 current developers that have a SwiftUI lifecycle app and wrap this view
                 controller in a `UIViewControllerRepresentable` implementation...Tint color
                 is not propagated...etc.
                 */
                surveyViewController.view.tintColor = determineTintColor(from: view)
        
            surveyViewController.delegate = self

            present(surveyViewController, animated: true, completion: nil)
    }

    // MARK: ORKTaskViewControllerDelegate

    open func taskViewController(
        _ taskViewController: ORKTaskViewController,
        didFinishWith reason: ORKTaskFinishReason,
        error: Error?) {

        taskViewController.dismiss(animated: true, completion: nil)

        guard let task = viewModel.first?.first?.task else {
            assertionFailure("Task controller is missing its task")
            return
        }

        if let error = error {
            surveyDelegate?.surveyTask(
                viewController: self,
                for: task,
                didFinish: .failure(error)
            )
            return
        }

        guard reason == .completed else {
            return
        }

        let indexPath = IndexPath(item: 0, section: 0)
        let event = viewModel[indexPath.section][indexPath.row]

        guard let values = extractOutcome(taskViewController.result) else {
            return
        }

        let outcome = OCKOutcome(
            taskUUID: event.task.uuid,
            taskOccurrenceIndex: event.scheduleEvent.occurrence,
            values: values
        )

        store.addAnyOutcome(
            outcome,
            callbackQueue: .main) { result in

            if case let .failure(error) = result {

                self.surveyDelegate?.surveyTask(
                    viewController: self,
                    for: task,
                    didFinish: .failure(error)
                )
            }

            self.surveyDelegate?.surveyTask(
                viewController: self,
                for: task,
                didFinish: .success(reason)
            )
        }
    }
}

#endif


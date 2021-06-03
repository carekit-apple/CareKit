/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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
#if !os(watchOS) && canImport(ResearchKit)

import CareKitStore
import CareKitUI
import ResearchKit
import UIKit

// MARK: OCKSurveyTaskViewControllerDelegate

public protocol OCKSurveyTaskViewControllerDelegate: AnyObject {

    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        for task: OCKAnyTask,
        didFinish result: Result<ORKTaskViewControllerFinishReason, Error>)

    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        shouldAllowDeletingOutcomeForEvent event: OCKAnyEvent) -> Bool
}

public extension OCKSurveyTaskViewControllerDelegate {

    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        for task: OCKAnyTask,
        didFinish result: Result<ORKTaskViewControllerFinishReason, Error>) {
        // No-op
    }

    func surveyTask(
        viewController: OCKSurveyTaskViewController,
        shouldAllowDeletingOutcomeForEvent event: OCKAnyEvent) -> Bool {
        return true
    }
}

open class OCKSurveyTaskViewController: OCKTaskViewController<OCKTaskController, OCKSurveyTaskViewSynchronizer>, ORKTaskViewControllerDelegate {

    private let extractOutcome: (ORKTaskResult) -> [OCKOutcomeValue]?

    public let survey: ORKTask

    public weak var surveyDelegate: OCKSurveyTaskViewControllerDelegate?

    public convenience init(
        task: OCKAnyTask,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager,
        survey: ORKTask,
        viewSynchronizer: OCKSurveyTaskViewSynchronizer = OCKSurveyTaskViewSynchronizer(),
        extractOutcome: @escaping (ORKTaskResult) -> [OCKOutcomeValue]?) {

        self.init(
            taskID: task.id,
            eventQuery: eventQuery,
            storeManager: storeManager,
            survey: survey,
            viewSynchronizer: viewSynchronizer,
            extractOutcome: extractOutcome
        )
    }

    public init(
        taskID: String,
        eventQuery: OCKEventQuery,
        storeManager: OCKSynchronizedStoreManager,
        survey: ORKTask,
        viewSynchronizer: OCKSurveyTaskViewSynchronizer = OCKSurveyTaskViewSynchronizer(),
        extractOutcome: @escaping (ORKTaskResult) -> [OCKOutcomeValue]?) {

        self.survey = survey
        self.extractOutcome = extractOutcome

        super.init(
            viewSynchronizer: viewSynchronizer,
            taskID: taskID,
            eventQuery: eventQuery,
            storeManager: storeManager
        )
    }

    override open func taskView(
        _ taskView: UIView & OCKTaskDisplayable,
        didCompleteEvent isComplete: Bool,
        at indexPath: IndexPath,
        sender: Any?) {

        guard isComplete else {

            if let event = controller.eventFor(indexPath: indexPath),

               let delegate = surveyDelegate,

               delegate.surveyTask(
                    viewController: self,
                    shouldAllowDeletingOutcomeForEvent: event) == false {

                return
            }

            let cancelAction = UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            )

            let confirmAction = UIAlertAction(
                title: "Delete", style: .destructive) { _ in
                
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
        surveyViewController.delegate = self

        present(surveyViewController, animated: true, completion: nil)
    }

    // MARK: ORKTaskViewControllerDelegate
    
    open func taskViewController(
        _ taskViewController: ORKTaskViewController,
        didFinishWith reason: ORKTaskViewControllerFinishReason,
        error: Error?) {

        taskViewController.dismiss(animated: true, completion: nil)

        guard let task = controller.taskEvents.first?.first?.task else {
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

        guard let event = controller.eventFor(indexPath: indexPath) else {
            return
        }

        guard let values = extractOutcome(taskViewController.result) else {
            return
        }

        let outcome = OCKOutcome(
            taskUUID: event.task.uuid,
            taskOccurrenceIndex: event.scheduleEvent.occurrence,
            values: values
        )

        controller.storeManager.store.addAnyOutcome(
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

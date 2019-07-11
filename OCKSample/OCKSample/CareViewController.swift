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

import Foundation
import UIKit
import CareKit

class CareViewController: OCKDailyPageViewController<OCKStore> {

        override func viewDidLoad() {
            super.viewDidLoad()
            navigationItem.rightBarButtonItem =
                UIBarButtonItem(title: "Care Team", style: .plain, target: self,
                                action: #selector(presentContactsListViewController))
        }

        @objc private func presentContactsListViewController() {
            let viewController = OCKContactsListViewController(storeManager: storeManager)
            viewController.title = "Care Team"
            viewController.navigationItem.rightBarButtonItem =
                UIBarButtonItem(title: "Done", style: .plain, target: self,
                                action: #selector(dismissContactsListViewController))

            let navigationController = UINavigationController(rootViewController: viewController)
            present(navigationController, animated: true, completion: nil)
        }

        @objc private func dismissContactsListViewController() {
            dismiss(animated: true, completion: nil)
        }

    // This will be called each time the selected date changes.
    // Use this as an opportunity to rebuild the content shown to the user.
    override func dailyPageViewController<S>(
        _ dailyPageViewController: OCKDailyPageViewController<S>,
        prepare listViewController: OCKListViewController,
        for date: Date) where S: OCKStoreProtocol {

        let identifiers = ["doxylamine", "nausea", "kegels"]
        let anchor = OCKTaskAnchor.taskIdentifiers(identifiers)
        var query = OCKTaskQuery(for: date)
        query.excludesTasksWithNoEvents = true

        storeManager.store.fetchTasks(anchor, query: query) { result in
            switch result {
            case .failure(let error): print("Error: \(error)")
            case .success(let tasks):

                // Add a non-CareKit view into the list
                let tipTitle = "Benefits of exercising"
                let tipText = "Learn how activity can promote a healthy pregnancy."

                // Only show the tip view on the current date
                if Calendar.current.isDate(date, inSameDayAs: Date()) {
                    let tipView = TipView()
                    tipView.headerView.titleLabel.text = tipTitle
                    tipView.headerView.detailLabel.text = tipText
                    tipView.imageView.image = UIImage(named: "exercise.jpg")
                    listViewController.appendView(tipView, animated: false)
                }

                // Since the kegel task is only sheduled every other day, there will be cases
                // where it is not contained in the tasks array returned from the query.
                if let kegelsTask = tasks.first(where: { $0.identifier == "kegels" }) {
                    let kegelsCard = OCKSimpleTaskViewController(storeManager: self.storeManager,
                                                                 task: kegelsTask,
                                                                 eventQuery: OCKEventQuery(for: date))
                    listViewController.appendViewController(kegelsCard, animated: false)
                }

                // Create a card for the doxylamine task if there are events for it on this day.
                if let doxylamineTask = tasks.first(where: { $0.identifier == "doxylamine" }) {
                    let doxylamineCard = OCKChecklistTaskViewController(
                        storeManager: self.storeManager,
                        task: doxylamineTask,
                        eventQuery: OCKEventQuery(for: date))

                    listViewController.appendViewController(doxylamineCard, animated: false)
                }

                // Create a card for the nausea task if there are events for it on this day.
                // Its OCKSchedule was defined to have daily events, so this task should be
                // found in `tasks` every day after the task start date.
                if let nauseaTask = tasks.first(where: { $0.identifier == "nausea" }) {
                    // Create a plot comparing nausea to medication adherence.
                    let nauseaDataSeries = OCKCartesianChartViewController<OCKStore>.DataSeriesConfiguration(
                        taskIdentifier: "nausea",
                        legendTitle: "Nausea",
                        gradientStartColor: #colorLiteral(red: 0.9176470588, green: 0.3529411765, blue: 0.4588235294, alpha: 1),
                        gradientEndColor: #colorLiteral(red: 0.9020889401, green: 0.5339772701, blue: 0.4407126009, alpha: 1),
                        markerSize: 10,
                        eventAggregator: OCKEventAggregator.countOutcomeValues)

                    let doxylamineDataSeries = OCKCartesianChartViewController<OCKStore>.DataSeriesConfiguration(
                        taskIdentifier: "doxylamine",
                        legendTitle: "Doxylamine",
                        gradientStartColor: #colorLiteral(red: 0.7372466922, green: 0.7372466922, blue: 0.7372466922, alpha: 1),
                        gradientEndColor: #colorLiteral(red: 0.7372466922, green: 0.7372466922, blue: 0.7372466922, alpha: 1),
                        markerSize: 10,
                        eventAggregator: OCKEventAggregator.countOutcomeValues)

                    let insightsCard = OCKCartesianChartViewController(
                        storeManager: self.storeManager,
                        dataSeriesConfigurations: [nauseaDataSeries, doxylamineDataSeries],
                        date: date,
                        plotType: .bar)

                    let titleText = "Nausea & Doxylamine Intake"
                    let detailText = "This Week"

                    insightsCard.chartView.headerView.titleLabel.text = titleText
                    insightsCard.chartView.headerView.detailLabel.text = detailText

                    listViewController.appendViewController(insightsCard, animated: false)

                    // Also create a card that displays a single event.
                    // The event query passed into the initializer specifies that only
                    // today's log entries should be displayed by this log task view controller.
                    let nauseaCard = OCKSimpleLogTaskViewController(
                        storeManager: self.storeManager,
                        task: nauseaTask,
                        eventQuery: OCKEventQuery(for: date))

                    listViewController.appendViewController(nauseaCard, animated: true)
                }
            }
        }
    }
}

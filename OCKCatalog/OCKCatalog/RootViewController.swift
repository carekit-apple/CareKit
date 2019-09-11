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

import AuthenticationServices
import CareKit

class RootViewController: UITableViewController {
    private enum Constants {
        static let cellID = "cell"
        static let untrackedTaskID = "nausea"
        static let trackedTaskID = "doxylamine"
        static let contactID = "lexi-torres"
    }

    private enum Section: String, CaseIterable {
        case task, contact, chart, lists
    }

    private enum TaskStyle: String, CaseIterable {
        case grid, checklist
        case simple, instructions, buttonLog = "button log"
    }

    private enum ContactStyle: String, CaseIterable {
        case simple, detailed
    }

    private enum List: String, CaseIterable {
        case tasks, contacts
    }

    var storeManager: OCKSynchronizedStoreManager<OCKStore>? {
        didSet {
            dataIsReady = false
            storeManager?.store.fillWithDummyData { [weak self] in
                guard let self = self else { return }
                self.dataIsReady = true
                self.tableView.reloadData()
            }
        }
    }

    private var dataIsReady = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellID)
        tableView.tableFooterView = UIView()
        clearsSelectionOnViewWillAppear = true

        navigationController?.navigationBar.prefersLargeTitles = true
        title = "CareKit Catalog"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataIsReady ? Section.allCases.count : 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.allCases[section].rawValue
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .task: return TaskStyle.allCases.count
        case .contact: return ContactStyle.allCases.count
        case .chart: return OCKCartesianGraphView.PlotType.allCases.count
        case .lists: return List.allCases.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellID, for: indexPath)
        let title: String
        switch Section.allCases[indexPath.section] {
        case .task: title = TaskStyle.allCases[indexPath.row].rawValue
        case .contact: title = ContactStyle.allCases[indexPath.row].rawValue
        case .chart: title = OCKCartesianGraphView.PlotType.allCases[indexPath.row].rawValue
        case .lists: title = List.allCases[indexPath.row].rawValue
        }
        cell.textLabel?.text = title.capitalized
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let storeManager = storeManager else { return }
        var viewController: UIViewController

        let section = Section.allCases[indexPath.section]
        switch section {
        case .task:
            let taskViewController = makeTaskViewController(withStyle: TaskStyle.allCases[indexPath.row], storeManager: storeManager)
            viewController = ContainerViewController(childViewController: taskViewController)

        case .contact:
            let contactViewController = makeContactViewController(withStyle: ContactStyle.allCases[indexPath.row], storeManager: storeManager)
            viewController = ContainerViewController(childViewController: contactViewController)

        case .chart:
            let chartViewController = makeChartViewController(withStyle: OCKCartesianGraphView.PlotType.allCases[indexPath.row],
                                                              storeManager: storeManager)
            viewController = ContainerViewController(childViewController: chartViewController)

        case .lists:
            switch List.allCases[indexPath.row] {
            case .tasks: viewController = UINavigationController(rootViewController: OCKDailyTasksPageViewController(storeManager: storeManager))
            case .contacts: viewController = UINavigationController(rootViewController: OCKContactsListViewController(storeManager: storeManager))
            }
        }

        if section == .lists {
            present(viewController, animated: true, completion: nil)
        } else {
            navigationController?.pushViewController(viewController, animated: true)
        }
        clearSelection()
    }

    private func makeTaskViewController(withStyle style: TaskStyle, storeManager: OCKSynchronizedStoreManager<OCKStore>) -> UIViewController {
        switch style {
        case .checklist:
            return OCKChecklistTaskViewController(storeManager: storeManager, taskIdentifier: Constants.trackedTaskID, eventQuery: .today)
        case .grid:
            return OCKGridTaskViewController(storeManager: storeManager, taskIdentifier: Constants.trackedTaskID, eventQuery: .today)
        case .simple:
            return OCKSimpleTaskViewController(storeManager: storeManager, taskIdentifier: Constants.trackedTaskID, eventQuery: .today)
        case .instructions:
            return OCKInstructionsTaskViewController(storeManager: storeManager, taskIdentifier: Constants.trackedTaskID, eventQuery: .today)
        case .buttonLog:
            return OCKButtonLogTaskViewController(storeManager: storeManager, taskIdentifier: Constants.untrackedTaskID, eventQuery: .today)
        }
    }

    private func makeContactViewController(withStyle style: ContactStyle, storeManager: OCKSynchronizedStoreManager<OCKStore>) -> UIViewController {
        switch style {
        case .simple:
            return OCKSimpleContactViewController(storeManager: storeManager, contactIdentifier: Constants.contactID, query: nil)
        case .detailed:
            return OCKDetailedContactViewController(storeManager: storeManager, contactIdentifier: Constants.contactID, query: nil)
        }
    }

    private func makeChartViewController(withStyle style: OCKCartesianGraphView.PlotType,
                                         storeManager: OCKSynchronizedStoreManager<OCKStore>) -> UIViewController {
        let gradientStart = UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9960784314, green: 0.3725490196, blue: 0.368627451, alpha: 1) : #colorLiteral(red: 0.8627432641, green: 0.2630574384, blue: 0.2592858295, alpha: 1)
        }
        let gradientEnd = UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9960784314, green: 0.4732026144, blue: 0.368627451, alpha: 1) : #colorLiteral(red: 0.8627432641, green: 0.3598620686, blue: 0.2592858295, alpha: 1)
        }

        let markerSize: CGFloat = style == .bar ? 10 : 2
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let configurations = [
            OCKDataSeriesConfiguration<OCKStore>(
                taskIdentifier: Constants.trackedTaskID,
                legendTitle: Constants.trackedTaskID.capitalized,
                gradientStartColor: gradientStart,
                gradientEndColor: gradientEnd,
                markerSize: markerSize,
                eventAggregator: .countOutcomeValues)
        ]

        let chartViewController = OCKCartesianChartViewController(storeManager: storeManager, type: style,
                                                                  dataSeriesConfigurations: configurations, date: startOfDay)
        chartViewController.synchronizedView.headerView.titleLabel.text = Constants.trackedTaskID.capitalized

        return chartViewController
    }

    private func clearSelection() {
        if let selectionPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectionPath, animated: true)
        }
    }
}

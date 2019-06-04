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

class RootViewController: UITableViewController {
    
    private enum Constants {
        static let cellID = "cell"
        static let untrackedTaskID = "nausea"
        static let trackedTaskID = "doxylamine"
        static let contactID = "lexi-torres"
    }
    
    private let storeManager: OCKSynchronizedStoreManager<OCKStore> = {
        let store = OCKStore(name: "carekit-catalog", type: .inMemory)
        return OCKSynchronizedStoreManager(wrapping: store)
    }()
    
    private enum Sections: String, CaseIterable {
        case task, event, contact, chart, lists
    }
    
    private enum Lists: String, CaseIterable {
        case tasks, contacts
    }
    
    private var isFillingDummyData = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        storeManager.store.fillWithDummyData { [weak self] in
            self?.isFillingDummyData = false
            self?.tableView.reloadData()
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellID)
        tableView.tableFooterView = UIView()
        clearsSelectionOnViewWillAppear = true
        
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "CareKit Catalog"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return isFillingDummyData ? 0 : Sections.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Sections.allCases[section].rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections.allCases[section] {
        case .task: return OCKTaskViewController<OCKStore>.Style.allCases.count
        case .event: return OCKEventViewController<OCKStore>.Style.allCases.count
        case .contact: return OCKContactViewController<OCKStore>.Style.allCases.count
        case .chart: return OCKCartesianGraphView.PlotType.allCases.count
        case .lists: return Lists.allCases.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellID, for: indexPath)
        switch Sections.allCases[indexPath.section] {
        case .task: cell.textLabel?.text = OCKTaskViewController<OCKStore>.Style.allCases[indexPath.row].rawValue
        case .event: cell.textLabel?.text = OCKEventViewController<OCKStore>.Style.allCases[indexPath.row].rawValue
        case .contact: cell.textLabel?.text = OCKContactViewController<OCKStore>.Style.allCases[indexPath.row].rawValue
        case .chart: cell.textLabel?.text = OCKCartesianGraphView.PlotType.allCases[indexPath.row].rawValue
        case .lists: cell.textLabel?.text = Lists.allCases[indexPath.row].rawValue
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var viewController: UIViewController
        
        let section = Sections.allCases[indexPath.section]
        switch section {
        case .task:
            let style = OCKTaskViewController<OCKStore>.Style.allCases[indexPath.row]
            let taskCard = OCKTaskViewController.makeViewController(style: style, storeManager: storeManager,
                                                             taskIdentifier: Constants.trackedTaskID, eventQuery: .today)
            viewController = ContainerViewController(childViewController: taskCard)
            
        case .event:
            let style = OCKEventViewController<OCKStore>.Style.allCases[indexPath.row]
            let taskIdentifier = style == .simpleLog ? Constants.untrackedTaskID : Constants.trackedTaskID
            let eventCard = OCKEventViewController.makeViewController(style: style, storeManager: storeManager,
                                                              taskIdentifier: taskIdentifier, eventQuery: .today)
            viewController = ContainerViewController(childViewController: eventCard)
            
        case .contact:
            let style = OCKContactViewController<OCKStore>.Style.allCases[indexPath.row]
            let contactCard = OCKContactViewController.makeViewController(style: style, storeManager: storeManager,
                                                                      contactIdentifier: Constants.contactID)
            viewController = ContainerViewController(childViewController: contactCard)
            
        case .chart:
            let style = OCKCartesianGraphView.PlotType.allCases[indexPath.row]
            let graphCard = makeGraphViewController(withStyle: style)
            viewController = ContainerViewController(childViewController: graphCard)
        
        case .lists:
            switch Lists.allCases[indexPath.row] {
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
        
    private func makeGraphViewController(withStyle style: OCKCartesianGraphView.PlotType) -> OCKCartesianChartViewController<OCKStore> {
        let markerSize: CGFloat = style == .bar ? 10 : 2
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let configurations = [
            OCKCartesianChartViewController<OCKStore>.DataSeriesConfiguration(
                taskIdentifier: Constants.trackedTaskID,
                legendTitle: Constants.trackedTaskID.capitalized,
                gradientStartColor: #colorLiteral(red: 0.3058823529, green: 0.3294117647, blue: 0.7843137255, alpha: 1),
                gradientEndColor: #colorLiteral(red: 0.5607843137, green: 0.5803921569, blue: 0.9843137255, alpha: 1),
                markerSize: markerSize,
                eventAggregator: .countOutcomeValues)
        ]
        let graphCard = OCKCartesianChartViewController(storeManager: storeManager, dataSeriesConfigurations: configurations,
                                                        date: startOfDay, plotType: style)
        graphCard.chartView.headerView.titleLabel.text = Constants.trackedTaskID.capitalized
        return graphCard
    }
    
    private func clearSelection() {
        if let selectionPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectionPath, animated: true)
        }
    }
}

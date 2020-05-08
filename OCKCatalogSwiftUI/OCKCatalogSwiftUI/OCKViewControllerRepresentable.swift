//
/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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

import SwiftUI
import CareKit

struct OCKListView: View, UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    func makeUIViewController(context: Context) -> OCKListViewController {
        let listController = OCKListViewController()
        return listController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKChecklistTaskView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    func makeUIViewController(context: Context) -> OCKListViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let trackedTaskID = "doxylamine"
        let viewController = OCKChecklistTaskViewController(taskID: trackedTaskID, eventQuery: .init(for: Date()), storeManager: appDelegate.storeManager)

        let listController = OCKListViewController()
        listController.appendViewController(viewController, animated: false)
        return listController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKGridTaskView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    func makeUIViewController(context: Context) -> OCKListViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let trackedTaskID = "doxylamine"
        let viewController = OCKGridTaskViewController(taskID: trackedTaskID, eventQuery: .init(for: Date()), storeManager: appDelegate.storeManager)

        let listController = OCKListViewController()
        listController.appendViewController(viewController, animated: false)
        return listController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKSimpleTaskView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    func makeUIViewController(context: Context) -> OCKListViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let trackedTaskID = "doxylamine"
        let viewController = OCKSimpleTaskViewController(taskID: trackedTaskID, eventQuery: .init(for: Date()), storeManager: appDelegate.storeManager)

        let listController = OCKListViewController()
        listController.appendViewController(viewController, animated: false)
        return listController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKInstructionsTaskView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    func makeUIViewController(context: Context) -> OCKListViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let trackedTaskID = "doxylamine"
        let viewController = OCKInstructionsTaskViewController(taskID: trackedTaskID, eventQuery: .init(for: Date()), storeManager: appDelegate.storeManager)


        let listController = OCKListViewController()
        listController.appendViewController(viewController, animated: false)
        return listController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKButtonLogTaskView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    func makeUIViewController(context: Context) -> OCKListViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let trackedTaskID = "doxylamine"
        let viewController = OCKButtonLogTaskViewController(taskID: trackedTaskID, eventQuery: .init(for: Date()), storeManager: appDelegate.storeManager)

        let listController = OCKListViewController()
        listController.appendViewController(viewController, animated: false)
        return listController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKSimpleContactView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    func makeUIViewController(context: Context) -> OCKListViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let contactID = "lexi-torres"
        let viewController = OCKSimpleContactViewController(contactID: contactID, storeManager: appDelegate.storeManager)

        let listController = OCKListViewController()
        listController.appendViewController(viewController, animated: false)
        return listController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKDetailedContactView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    func makeUIViewController(context: Context) -> OCKListViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let contactID = "lexi-torres"
        let viewController = OCKDetailedContactViewController(contactID: contactID, storeManager: appDelegate.storeManager)

        let listController = OCKListViewController()
        listController.appendViewController(viewController, animated: false)
        return listController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKCartesianChartView: UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKListViewController

    let type: OCKCartesianGraphView.PlotType

    func makeUIViewController(context: Context) -> OCKListViewController {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let viewController = makeChartViewController(withStyle: type, storeManager: appDelegate.storeManager)

        let listController = OCKListViewController()
        listController.appendViewController(viewController, animated: false)
        return listController
    }

    private func makeChartViewController(withStyle style: OCKCartesianGraphView.PlotType,
                                         storeManager: OCKSynchronizedStoreManager) -> UIViewController {
        // 8 and 9
        let gradientStart = UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9960784314, green: 0.3725490196, blue: 0.368627451, alpha: 1) : #colorLiteral(red: 0.8627432641, green: 0.2630574384, blue: 0.2592858295, alpha: 1)
        }
        let gradientEnd = UIColor { traitCollection -> UIColor in
            return traitCollection.userInterfaceStyle == .light ? #colorLiteral(red: 0.9960784314, green: 0.4732026144, blue: 0.368627451, alpha: 1) : #colorLiteral(red: 0.8627432641, green: 0.3598620686, blue: 0.2592858295, alpha: 1)
        }

        let markerSize: CGFloat = style == .bar ? 10 : 2
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let trackedTaskID = "doxylamine"

        let configurations = [
            OCKDataSeriesConfiguration(
                taskID: trackedTaskID,
                legendTitle: trackedTaskID.capitalized,
                gradientStartColor: gradientStart,
                gradientEndColor: gradientEnd,
                markerSize: markerSize,
                eventAggregator: .countOutcomeValues)
        ]

        let chartViewController = OCKCartesianChartViewController(plotType: style, selectedDate: startOfDay,
                                                                  configurations: configurations, storeManager: storeManager)
        chartViewController.controller.fetchAndObserveInsights(forConfigurations: configurations)
        chartViewController.chartView.headerView.titleLabel.text = trackedTaskID.capitalized
        return chartViewController
    }

    func updateUIViewController(_ uiViewController: OCKListViewController, context: Context) {

    }
}

struct OCKDailyTasksPageView: View, UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKDailyTasksPageViewController

    func makeUIViewController(context: Context) -> OCKDailyTasksPageViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let rootViewController = OCKDailyTasksPageViewController(storeManager: appDelegate.storeManager)
        rootViewController.isModalInPresentation = true
        return rootViewController
    }

    func updateUIViewController(_ uiViewController: OCKDailyTasksPageViewController, context: Context) {

    }
}

struct OCKContactsListView: View, UIViewControllerRepresentable {
    typealias UIViewControllerType = OCKContactsListViewController

    func makeUIViewController(context: Context) -> OCKContactsListViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        let rootViewController = OCKContactsListViewController(storeManager: appDelegate.storeManager)
        return rootViewController
    }

    func updateUIViewController(_ uiViewController: OCKContactsListViewController, context: Context) {

    }
}

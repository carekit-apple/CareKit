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

import CareKitStore
import CareKitUI
import Combine
import MessageUI
import UIKit

/// Types wishing to receive updates from chart view controllers can conform to this protocol.
public protocol OCKChartViewControllerDelegate: AnyObject {

    /// Called when an unhandled error is encountered in a calendar view controller.
    /// - Parameters:
    ///   - viewController: The view controller in which the error was encountered.
    ///   - didEncounterError: The error that was unhandled.
    func chartViewController<C: OCKChartControllerProtocol, VS: OCKChartViewSynchronizerProtocol>(
        _ viewController: OCKChartViewController<C, VS>, didEncounterError: Error)
}

/// A view controller that displays a chart view and keep it synchronized with a store.
open class OCKChartViewController<Controller: OCKChartControllerProtocol, ViewSynchronizer: OCKChartViewSynchronizerProtocol>:
UIViewController, OCKChartViewDelegate {

    // MARK: Properties

    /// If set, the delegate will receive updates when import events happen
    public weak var delegate: OCKChartViewControllerDelegate?

    /// Handles the responsibility of updating the view when data in the store changes.
    public let viewSynchronizer: ViewSynchronizer

    /// Handles the responsibility of interacting with data from the store.
    public let controller: Controller

    /// The view that is being synchronized against the store.
    public var chartView: ViewSynchronizer.View {
        guard let view = self.view as? ViewSynchronizer.View else { fatalError("View should be of type \(ViewSynchronizer.View.self)") }
        return view
    }

    private var viewDidLoadCompletion: (() -> Void)?
    private var viewModelSubscription: AnyCancellable?

    // MARK: - Life Cycle

    public init(controller: Controller, viewSynchronizer: ViewSynchronizer) {
        self.controller = controller
        self.viewSynchronizer = viewSynchronizer
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    override open func loadView() {
        view = viewSynchronizer.makeView()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        chartView.delegate = self

        // Begin listening for changes in the view model. Note, when we subscribe to the view model, it sends its current value through the stream
        startObservingViewModel()

        viewDidLoadCompletion?()
    }

    // MARK: - Methods

    // Create a subscription that updates the view when the view model is updated.
    private func startObservingViewModel() {
        viewModelSubscription?.cancel()
        viewModelSubscription = controller.objectWillChange
            .context()
            .sink { [weak self] context in
                guard let typedView = self?.view as? ViewSynchronizer.View else { fatalError("View should be of type \(ViewSynchronizer.View.self)") }
                self?.viewSynchronizer.updateView(typedView, context: context)
            }
    }

    // MARK: - OCKChartViewDelegate

    open func didSelectChartView(_ chartView: UIView & OCKChartDisplayable) {}
}

public extension OCKChartViewController where Controller: OCKChartController {

    /// Initialize a view controller that displays a chart. Fetches and stays synchronized with insights.
    /// - Parameter viewSynchronizer: Manages the chart view.
    /// - Parameter weekOfDate: A date in the week of the insights range to fetch.
    /// - Parameter configurations: Configurations used to fetch the insights ad display the data.
    /// - Parameter storeManager: Wraps the store that contains the insight data to fetch.
    convenience init(viewSynchronizer: ViewSynchronizer, weekOfDate: Date,
                     configurations: [OCKDataSeriesConfiguration], storeManager: OCKSynchronizedStoreManager) {
        let controller = Controller(weekOfDate: weekOfDate, storeManager: storeManager)
        self.init(controller: controller, viewSynchronizer: viewSynchronizer)
        viewDidLoadCompletion = { [weak self] in
            self?.controller.fetchAndObserveInsights(forConfigurations: configurations, errorHandler: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.chartViewController(self, didEncounterError: error)
            })
        }
    }
}

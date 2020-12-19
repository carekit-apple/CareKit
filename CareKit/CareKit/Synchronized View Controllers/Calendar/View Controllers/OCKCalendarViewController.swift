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

/// Types wishing to receive updates from calendar view controllers can conform to this protocol.
public protocol OCKCalendarViewControllerDelegate: AnyObject {

    /// Called when an unhandled error is encountered in a calendar view controller.
    /// - Parameters:
    ///   - viewController: The view controller in which the error was encountered.
    ///   - didEncounterError: The error that was unhandled.
    func calendarViewController<C: OCKCalendarControllerProtocol, VS: OCKCalendarViewSynchronizerProtocol>(
        _ viewController: OCKCalendarViewController<C, VS>, didEncounterError: Error)
}

/// A view controller that displays a calendar view and keep it synchronized with a store.
open class OCKCalendarViewController<Controller: OCKCalendarControllerProtocol, ViewSynchronizer: OCKCalendarViewSynchronizerProtocol>:
UIViewController, OCKCalendarViewDelegate {

    // MARK: Properties

    /// If set, the delegate will receive updates when import events happen
    public weak var delegate: OCKCalendarViewControllerDelegate?

    /// Handles the responsibility of updating the view when data in the store changes.
    public let viewSynchronizer: ViewSynchronizer

    /// Handles the responsibility of interacting with data from the store.
    public let controller: Controller

    /// The view that is being synchronized against the store.
    public var calendarView: ViewSynchronizer.View {
        guard let view = self.view as? ViewSynchronizer.View else { fatalError("View should be of type \(ViewSynchronizer.View.self)") }
        return view
    }

    private var viewDidLoadCompletion: (() -> Void)?
    private var viewModelSubscription: AnyCancellable?

    // MARK: - Life Cycle

    /// Initialize with a controller and a synchronizer
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
        calendarView.delegate = self

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

    // MARK: - OCKCalendarViewDelegate

    open func calendarView(_ calendarView: UIView & OCKCalendarDisplayable, didSelectDate date: Date, at index: Int, sender: Any?) {}
}

public extension OCKCalendarViewController where Controller: OCKCalendarController {

    /// Initialize a view controller that displays adherence. Fetches and stays synchronized with the adherence data.
    /// - Parameter viewSynchronizer: Manages the calendar view.
    /// - Parameter dateInterval: The date interval for the adherence range.
    /// - Parameter aggregator: Used to aggregate adherence over the date interval.
    /// - Parameter storeManager: Wraps the store that contains the adherence data.
    convenience init(viewSynchronizer: ViewSynchronizer, dateInterval: DateInterval,
                     aggregator: OCKAdherenceAggregator, storeManager: OCKSynchronizedStoreManager) {
        let controller = Controller(dateInterval: dateInterval, storeManager: storeManager)
        self.init(controller: controller, viewSynchronizer: viewSynchronizer)
        viewDidLoadCompletion = { [weak self] in
            self?.controller.fetchAndObserveAdherence(usingAggregator: aggregator, errorHandler: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.calendarViewController(self, didEncounterError: error)
            })
        }
    }
}

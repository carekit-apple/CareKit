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
import UIKit

/// View controller that is synchronized with a list of completion states. Shows an `OCKCalendarWeekView` and handles user interactions
/// automatically.
open class OCKWeekCalendarViewController<Store: OCKStoreProtocol>: OCKCalendarViewController<OCKCalendarWeekView, Store> {
    // MARK: Properties

    /// The type of the view displayed by the view controller.
    public typealias View = OCKCalendarWeekView

    // MARK: Life Cycle

    /// Create a view controller that queries for and displays completion states.
    /// - Parameter storeManager: A store manager that will be used to provide synchronization.
    /// - Parameter date: Any date in the date interval to display.
    /// - Parameter aggregator: Used to aggregate events to compute completion.
    override public init(storeManager: OCKSynchronizedStoreManager<Store>, date: Date, aggregator: OCKAdherenceAggregator<Store.Event>) {
        super.init(storeManager: storeManager, date: date, aggregator: aggregator)
    }

    // MARK: Methods

    /// Update the view whenever the view model changes.
    /// - Parameter view: The view to update.
    /// - Parameter context: The data associated with the updated state.
    override open func updateView(_ view: OCKCalendarWeekView, context: OCKSynchronizationContext<[OCKCompletionRingButton.CompletionState]>) {
        // clear the view
        guard let states = context.viewModel else {
            view.completionRingButtons.forEach { $0.setState(.empty, animated: true) }
            return
        }

        // Else update the ring states
        guard states.count == view.completionRingButtons.count else {
            fatalError("Number of states and completions rings do not match")
        }
        view.completionRingButtons.enumerated().forEach { $1.setState(states[$0], animated: true) }
    }

    /// Create an instance of the view to be displayed.
    override open func makeView() -> OCKCalendarWeekView {
        return .init(weekOf: date)
    }
}

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
import CareKitStore
import CareKitUI

internal protocol OCKCalendarViewControllerDelegate: class {
    func calendarViewController<S: OCKStoreProtocol>(
        _ calendarViewController: OCKCalendarViewController<S>,
        didFailWithError error: Error)
}

internal class OCKCalendarViewController<Store: OCKStoreProtocol>: OCKSynchronizedViewController<[OCKCompletionRingButton.CompletionState]> {
    
    // MARK: Properties
    
    public enum Style: String, CaseIterable {
        case week
    }
    
    public weak var delegate: OCKCalendarViewControllerDelegate?
    public let adherenceQuery: OCKAdherenceQuery
    public let storeManager: OCKSynchronizedStoreManager<Store>?
    
    // Styled initializers
    
    public static func makeCalendar(style: Style, storeManager: OCKSynchronizedStoreManager<Store>?,
                                    adherenceQuery: OCKAdherenceQuery) -> OCKCalendarViewController<Store> {
        switch style {
        case .week: return OCKWeekCalendarViewController<Store>(storeManager: storeManager, adherenceQuery: adherenceQuery)
        }
    }
    
    // Custom view initializer
    
    internal init(
        storeManager: OCKSynchronizedStoreManager<Store>?,
        adherenceQuery: OCKAdherenceQuery,
        loadCustomView: @escaping () -> UIView,
        modelDidChange: @escaping CustomModelDidChange) {
        
        self.storeManager = storeManager
        self.adherenceQuery = adherenceQuery
        super.init(loadCustomView: loadCustomView, modelDidChange: modelDidChange)
    }
    
    // Bindable view initializers
    
    internal init<View: UIView & OCKBindable>(
        storeManager: OCKSynchronizedStoreManager<Store>?,
        adherenceQuery: OCKAdherenceQuery,
        loadDefaultView: @escaping () -> View,
        modelDidChange: ModelDidChange? = nil)
    where View.Model == [OCKCompletionRingButton.CompletionState] {
            
        self.storeManager = storeManager
        self.adherenceQuery = adherenceQuery
        super.init(loadDefaultView: loadDefaultView, modelDidChange: modelDidChange)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        fetchAdherence()
    }
    
    // MARK: Methods
    
    override internal func subscribe() {
        super.subscribe()
        
        subscription = storeManager?.notificationPublisher
            .compactMap { $0 as? OCKOutcomeNotification<Store> }
            .sink(receiveValue: { [weak self] (task) in
                self?.fetchAdherence()
            }
        )
    }
    
    private func fetchAdherence() {
        storeManager?.store.fetchAdherence(query: adherenceQuery) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.delegate?.calendarViewController(self, didFailWithError: error)
            case .success(let adherence):
                let states = self.convertAdherenceToCompletionRingState(adherence: adherence)
                self.modelUpdated(viewModel: states, animated: true)
            }
        }
    }
    
    private func convertAdherenceToCompletionRingState(adherence: [OCKAdherence]) -> [OCKCompletionRingButton.CompletionState] {
        return zip(adherenceQuery.dates(), adherence).map { (date, adherence) in
            let isInFuture = date > Date() && !Calendar.current.isDateInToday(date)
            switch adherence {
            case .noTasks: return .dimmed
            case .noEvents: return .empty
            case .progress(let value):
                if value > 0 { return .progress(CGFloat(value)) }
                return isInFuture ? .empty : .zero
            }
        }
    }
}

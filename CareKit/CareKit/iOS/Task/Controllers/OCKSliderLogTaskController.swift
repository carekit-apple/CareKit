//
//  OCKSliderLogTaskController.swift
//  
//
//  Created by Dylan Li on 5/26/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import CareKitStore
import Combine
import Foundation
import SwiftUI

open class OCKSliderLogTaskController: OCKTaskController {
    
    /// Data used to create a `CareKitUI.SliderTaskTaskView`.
    @Published public private(set) var viewModel: SliderLogTaskViewModel? {
        willSet { objectWillChange.send() }
    }
    
    /// Data used to create a `CareKitUI.SliderTaskTaskView`.
    @Published public private(set) var value: Double = 0
    
    private var cancellable: AnyCancellable?
    
    public required init(storeManager: OCKSynchronizedStoreManager) {
        super.init(storeManager: storeManager)
        cancellable = $taskEvents.sink { [unowned self] taskEvents in
            self.viewModel = self.makeViewModel(from: taskEvents)
        }
    }
    
    private func makeViewModel(from taskEvents: OCKTaskEvents) -> SliderLogTaskViewModel? {
        guard !taskEvents.isEmpty else { return nil }

        if let foundValue = taskEvents.first?.first?.sortedOutcomeValuesByRecency().outcome?.values.first?.numberValue?.doubleValue {
            value = foundValue
        }
    
        let errorHandler: (Error) -> Void = { [weak self] error in
            self?.error = error
        }
        
        return .init(title: taskEvents.firstEventTitle,
                     detail: taskEvents.firstEventDetail,
                     instructions: taskEvents.firstTaskInstructions) { sliderValue in
                        if self.taskEvents.first?.first?.outcome?.values != nil {
                            self.appendOutcomeValue(value: sliderValue, at: .init(row: 0, section: 0)) { result in
                                if case let .failure(error) = result {
                                    errorHandler(error)
                                }
                            }
                        } else {
                            self.saveOutcomesForEvent(atIndexPath: .init(row: 0, section: 0), values: [.init(sliderValue)], errorHandler: errorHandler)
                        }
                     }
    }
}

#endif

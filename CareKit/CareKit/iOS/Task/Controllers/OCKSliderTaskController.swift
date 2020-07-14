//
//  OCKSliderTaskController.swift
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

open class OCKSliderTaskController: OCKTaskController {
    
    /// Data used to create a `CareKitUI.NumericProgressTaskTaskView`.
    @Published public private(set) var viewModel: SliderTaskViewModel? {
        willSet { objectWillChange.send() }
    }
    
    private var cancellable: AnyCancellable?
    
    public required init(storeManager: OCKSynchronizedStoreManager) {
        super.init(storeManager: storeManager)
        cancellable = $taskEvents.sink { [unowned self] taskEvents in
            self.viewModel = self.makeViewModel(from: taskEvents)
        }
    }
    
    private func makeViewModel(from taskEvents: OCKTaskEvents) -> SliderTaskViewModel? {
        guard !taskEvents.isEmpty else { return nil }
        
        let errorHandler: (Error) -> Void = { [weak self] error in
            self?.error = error
        }

        return .init(title: taskEvents.firstEventTitle,
                     detail: taskEvents.firstEventDetail,
                     instructions: taskEvents.firstTaskInstructions,
                     isComplete: taskEvents.isFirstEventComplete,
                     action: toggleActionForFirstEvent(errorHandler: errorHandler),
                     maximumImage: nil,
                     minimumImage: nil,
                     initialValue: 5,
                     range: 0...10,
                     step: 1,
                     sliderHeight: 40,
                     frameHeightMultiplier: 1.7,
                     useDefaultSlider: false)
    }
        
}

#endif

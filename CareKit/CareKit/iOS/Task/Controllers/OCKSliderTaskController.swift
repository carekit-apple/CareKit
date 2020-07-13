//
//  OCKSliderTaskController.swift
//  
//
//  Created by Dylan Li on 5/26/20.
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
        
        let event = taskEvents.first?.first
        var value: CGFloat = 0
        var isComplete = false
        
        if let foundValue = event?.scheduleEvent.element.targetValues.first?.numberValue?.doubleValue {
            value = CGFloat(foundValue)
            isComplete = true
        }

        return .init(title: taskEvents.firstEventTitle, detail: taskEvents.firstEventDetail, instructions: taskEvents.firstTaskInstructions, isComplete: isComplete, action: {}, maximumImage: nil, minimumImage: nil, initialValue: value, range: (value - 5)...(value + 5), step: 1, sliderHeight: 40, frameHeightMultiplier: 1.7, useDefaultSlider: false)
    }
        
}

#endif

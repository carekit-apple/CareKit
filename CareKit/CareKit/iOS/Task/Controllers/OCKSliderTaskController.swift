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
    
    /// Data used to create a `CareKitUI.SliderTaskTaskView`.
    @Published public private(set) var viewModel: SliderTaskViewModel? {
        willSet { objectWillChange.send() }
    }
    
    /// Data used to create a `CareKitUI.SliderTaskTaskView`.
    @Published public private(set) var value: CGFloat = 0 {
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
        
        if let foundValue = event?.scheduleEvent.element.targetValues.first?.numberValue?.doubleValue {
            value = CGFloat(foundValue)
        }
    
        let errorHandler: (Error) -> Void = { [weak self] error in
            self?.error = error
        }
        
        return .init(title: taskEvents.firstEventTitle,
                     detail: taskEvents.firstEventDetail,
                     instructions: taskEvents.firstTaskInstructions,
                     isComplete: taskEvents.isFirstEventComplete,
                     value: value,
                     action: saveSliderValueActionForFirstEvent(errorHandler: errorHandler))
    }
    
    func saveSliderValueActionForFirstEvent(errorHandler: ((Error) -> Void)?) -> (Double) -> Void {
        { sliderValue in
            return self.saveOutcomesEvent(atIndexPath: .init(row: 0, section: 0), values: [.init(sliderValue)], errorHandler: errorHandler) }
    }
        
}

#endif

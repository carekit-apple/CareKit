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
    }
        
}

#endif

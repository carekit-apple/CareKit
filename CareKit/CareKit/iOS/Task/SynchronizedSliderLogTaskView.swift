//
//  OCKSliderButton.swift
//
//
//  Created by Dylan Li on 7/21/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import CareKitStore
import CareKitUI
import Foundation
import SwiftUI

@available(iOS 14.0, *)
public struct SynchronizedSliderLogTaskView<Controller: OCKSliderLogTaskController, SliderLogTaskView: View>: View {

    @StateObject private var controller: OCKSliderLogTaskController
    @State private var value: Double = 0

    private let errorHandler: ((Error) -> Void)?
    private let content: (_ controller: OCKSliderLogTaskController, _ value: Binding<Double>) -> SliderLogTaskView
    private let query: OCKSynchronizedTaskQuery?
    
    public var body: some View {
        content(controller, $value)
            .onAppear {
                query?.perform(using: controller)
                value = controller.value
            }
            .onReceive(controller.$value) { updatedValue in
                value = updatedValue
            }
            .onReceive(controller.$error.compactMap { $0 }) { error in
                self.errorHandler?(error)
            }
    }

    init(controller: Controller, query: OCKSynchronizedTaskQuery? = nil, errorHandler: ((Error) -> Void)? = nil,
         content: @escaping (_ viewModel: OCKSliderLogTaskController, _ value: Binding<Double>) -> SliderLogTaskView) {
        self.query = query
        self._controller = .init(wrappedValue: controller)
        self.errorHandler = errorHandler
        self.content = content
    }

    init(copying copy: Self, settingErrorHandler errorHandler: @escaping (Error) -> Void) {
        self.query = copy.query
        self._controller = .init(wrappedValue: copy.controller)
        self.content = copy.content
        self.errorHandler = errorHandler
    }
}

#endif

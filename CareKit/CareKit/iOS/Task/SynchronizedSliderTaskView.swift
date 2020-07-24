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
public struct SynchronizedSliderTaskView<Controller: OCKSliderTaskController, SliderTaskView: View>: View {

    @StateObject private var controller: OCKSliderTaskController
    
    @State private var value: CGFloat = 5
//    public let minimumImage: Image?
//    public let maximumImage: Image?
//    public let range: ClosedRange<CGFloat>?
//    public let step: CGFloat?
//    public let sliderStyle: SliderStyle?

    private let errorHandler: ((Error) -> Void)?
    private let content: (_ controller: OCKSliderTaskController, _ value: Binding<CGFloat>) -> SliderTaskView
    private let query: OCKSynchronizedTaskQuery?
    
    public var body: some View {
        content(controller, $value)
            .onAppear {
                self.query?.perform(using: self.controller)
            }
            .onReceive(controller.$error.compactMap { $0 }) { error in
                self.errorHandler?(error)
            }
    }

    init(controller: Controller, query: OCKSynchronizedTaskQuery? = nil, errorHandler: ((Error) -> Void)? = nil, initialValue: CGFloat = 5,
         content: @escaping (_ viewModel: OCKSliderTaskController, _ value: Binding<CGFloat>) -> SliderTaskView) {
        self.query = query
        self._controller = .init(wrappedValue: controller)
        self.errorHandler = errorHandler
        self._value = State(initialValue: initialValue)
        self.content = content
        //        self.minimumImage = nil
//        self.maximumImage = nil
//        self.range = nil
//        self.step = nil
//        self.sliderStyle = nil
    }

    init(copying copy: Self, settingErrorHandler errorHandler: @escaping (Error) -> Void) {
        self.query = copy.query
        self._controller = .init(wrappedValue: copy.controller)
        self.content = copy.content
        self.errorHandler = errorHandler
    }

}

@available(iOS 14.0, *)
public extension SynchronizedSliderTaskView where SliderTaskView == CareKitUI.SliderTaskView<_SliderTaskViewHeader, _SliderTaskViewFooter> {
    
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager,
         initialValue: CGFloat, range: ClosedRange<CGFloat>, step: CGFloat, minimumImage: Image, maximumImage: Image,  sliderStyle: SliderStyle) {
        self.init(controller: .init(storeManager: storeManager),
                  query: .tasks([task], eventQuery),
                  initialValue: initialValue) { controller, value in
            CareKitUI.SliderTaskView(title: Text(controller.viewModel?.title ?? ""),
                                     detail: controller.viewModel?.detail.map { Text($0) },
                                     instructions: controller.viewModel?.instructions.map{ Text($0) },
                                     isComplete: controller.viewModel?.isComplete ?? false,
                                     value: value,
                                     range: range,
                                     step: step,
                                     minimumImage: minimumImage,
                                     maximumImage: maximumImage,
                                     sliderStyle: sliderStyle,
                                     action: controller.viewModel?.action ?? { _ in })
        }
    }
}

#endif

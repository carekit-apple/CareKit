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

    init(controller: Controller, query: OCKSynchronizedTaskQuery? = nil, errorHandler: ((Error) -> Void)? = nil, initialValue: CGFloat,
         content: @escaping (_ viewModel: OCKSliderTaskController, _ value: Binding<CGFloat>) -> SliderTaskView) {
        self.query = query
        self._controller = .init(wrappedValue: controller)
        self.errorHandler = errorHandler
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    init(copying copy: Self, settingErrorHandler errorHandler: @escaping (Error) -> Void) {
        self.query = copy.query
        self._controller = .init(wrappedValue: copy.controller)
        self.content = copy.content
        self.errorHandler = errorHandler
    }

}
/*
@available(iOS 14.0, *)
public extension SynchronizedSliderTaskView where Controller == OCKSliderTaskController, SliderTaskView == CareKitUI.SliderTaskView<_SliderTaskViewHeader, _SliderTaskViewFooter> {
    
    /// Create an instance that displays the default content.
    /// - Parameters:
    ///     - controller: Controller that holds a reference to data displayed by the view.
    init(controller: OCKSliderTaskController, initialValue: CGFloat) {
        self.init(controller: controller, initialValue: initialValue) { controller, value in
            .init(viewModel: controller.viewModel, value: value)
        }
    }
    
    /// Create an instance that displays the default content. The first event that matches the provided query will be fetched from the the store and
    /// displayed in the view. The view will update when changes occur in the store.
    /// - Parameters:
    ///     - task: The task associated with the event to fetch.
    ///     - eventQuery: A query used to fetch an event in the store.
    ///     - storeManager: Wraps the store that contains the event to fetch.
    ///     - content: Create a view to display whenever the body is computed.
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager, initialValue: CGFloat) {
        self.init(controller: .init(storeManager: storeManager),
                  query: .tasks([task], eventQuery),
                  initialValue: initialValue) { controller, value in
            .init(viewModel: controller.viewModel, value: value)
        }
    }
    
    /// Create an instance that displays the default content. The first task and event that match the provided queries will be fetched from the the
    /// store and displayed in the view. The view will update when changes occur in the store.
    /// - Parameters:
    ///     - taskID: The ID of the task to fetch.
    ///     - eventQuery: A query used to fetch an event in the store.
    ///     - storeManager: Wraps the store that contains the task and event to fetch.
    ///     - content: Create a view to display whenever the body is computed.
    init(taskID: String, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager, initialValue: CGFloat) {
        self.init(controller: .init(storeManager: storeManager),
                  query: .taskIDs([taskID], eventQuery), initialValue: initialValue) { controller, value in
            .init(viewModel: controller.viewModel, value: value)
        }
    }
}*/

private extension CareKitUI.SliderTaskView where Header == _SliderTaskViewHeader, SliderView == _SliderTaskViewFooter {
    init(viewModel: SliderTaskViewModel?, value: Binding<CGFloat>,
         minimumImage: Image? = nil, maximumImage: Image? = nil, range: ClosedRange<CGFloat> = 0...10, step: CGFloat = 1, sliderStyle: SliderStyle = .system) {
        self.init(title: Text(viewModel?.title ?? ""),
                  detail: viewModel?.detail.map { Text($0) },
                  instructions: viewModel?.instructions.map{ Text($0) },
                  isComplete: viewModel?.isComplete ?? false,
                  value: value,
                  range: range,
                  step: step,
                  minimumImage: minimumImage,
                  maximumImage: maximumImage,
                  sliderStyle: sliderStyle,
                  action: viewModel?.action ?? { _ in })
    }
}

#endif

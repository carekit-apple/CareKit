//
//  SliderTaskView.swift
//
//
//  Created by Dylan Li on 5/26/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//
#if !os(watchOS)

import CareKitUI
import Foundation
import SwiftUI

/// A card that updates when a controller changes. The view displays a header view, multi-line label, and a completion button.
///
/// In CareKit, this view is intended to display a particular event for a task. The state of the button indicates the completion state of the event.
///
/// # View Updates
/// The view updates with the observed controller. By default, data from the controller is mapped to the view. The mapping can be customized by
/// providing a closure that returns a view. The closure is called whenever the controller changes.
///
/// # Style
/// The card supports styling using `careKitStyle(_:)`.
///
/// ```
///     +-------------------------------------------------------+
///     |                                                       |
///     |  <Title>                                              |
///     |  <Detail>                                             |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     |  <Instructions>                                       |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  |               <Completion Button>               |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```

@available(iOS 14.0, *)
public struct SliderTaskView<Header: View, SliderView: View>: View {
    
    private typealias TaskView = SynchronizedTaskView<OCKSliderTaskController, CareKitUI.SliderTaskView<Header, SliderView>>

    private let taskView: TaskView

    public var body: some View {
        taskView
    }

    private init(taskView: TaskView) {
        self.taskView = taskView
    }

//    private let content: (_ configuration: SliderTaskViewConfiguration) -> CareKitUI.SliderTaskView<Header, SliderView>

    /// Owns the view model that drives the view.
    @ObservedObject public var controller: OCKSliderTaskController

//    public var body: some View {
//        content(.init(controller: controller))
//    }

    /// Create an instance that updates the content view when the observed controller changes.
    /// - Parameter controller: Owns the view model that drives the view.
    /// - Parameter content: Return a view to display whenever the controller changes.
//    public init(controller: OCKSliderTaskController,
//                content: @escaping (_ configuration: SliderTaskViewConfiguration) ->
//        CareKitUI.SliderTaskView<Header,Footer>) {
//        self.controller = controller
//        self.content = content
//    }
}

@available(iOS 14.0, *)
public extension SliderTaskView where Header == _SliderTaskViewHeader, Footer == _SliderTaskViewFooter {

    /// Create an instance that updates the content view when the observed controller changes. The default view will be displayed whenever the
    /// controller changes.
    /// - Parameter controller: Owns the view model that drives the view.
    init(controller: OCKSliderTaskController) {
        self.init(controller: controller, content: { .init(configuration: $0) })
    }
}

private extension CareKitUI.SliderTaskView where Header == _SliderTaskViewHeader, SliderView == _SliderTaskViewFooter {
    init(viewModel: SliderTaskViewModel?) {
        self.init(title: Text(" "), //Text(viewModel?.title ?? ""),
                  detail: nil, //viewModel?.detail.map { Text($0) },
                  instructions: nil, //viewModel?.instructions.map{ Text($0) },
                  isComplete: viewModel?.isComplete ?? false,
                  action: viewModel?.action ?? {},
                  maximumImage: viewModel?.maximumImage,
                  minimumImage: viewModel?.minimumImage,
                  initialValue: viewModel?.initialValue ?? 5,
                  range: viewModel?.range ?? 0...10,
                  step: viewModel?.step ?? 1,
                  useDefaultSlider: viewModel?.useDefaultSlider ?? false)
    }
}

public struct SliderTaskViewModel {
    
    /// The title text to display in the header.
    public let title: String
    
    /// The detail text to display in the header.
    public let detail: String?
    
    /// Instructions text to display under the header.
    public let instructions: String?
    
    /// True if the button under the slider is in the completed.
    public let isComplete: Bool
    
    /// Action to perform when the button is tapped.
    public let action: () -> Void
    
    /// Image to display to the right of the slider. Default value is nil.
    public let maximumImage: Image?
    
    /// Image to display to the left of the slider. Default value is nil.
    public let minimumImage: Image?
    
    /// Value that the slider begins on. Must be within the range.
    public let initialValue: CGFloat
    
    /// The range that includes all possible values.
    public let range: ClosedRange<CGFloat>.Bound
    
    /// Value of the increment that the slider takes.
    public let step: CGFloat
    
    /// Height of the bar of the slider. Default value is 40.
    public let sliderHeight: CGFloat
    
    /// Value to multiply the slider height by to attain the hieght of the frame enclosing the slider. Default value is 1.7.
    public let frameHeightMultiplier: CGFloat
    
    public let useDefaultSlider: Bool
}

#endif

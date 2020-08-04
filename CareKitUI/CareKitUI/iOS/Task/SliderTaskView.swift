//
//  SliderTaskView.swift
//  
//
//  Created by Dylan Li on 6/2/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import Foundation
import SwiftUI

/// A card that displays a header view, multi-line label, a slider, and a completion button.
///
/// In CareKit, this view is intended to display a particular event for a task. The state of the button indicates the completion state of the event.
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
///     |  <Min Image> –––––––––––––O–––––––––––– <Max Image>   |
///     |                                                       |
///     |                       +-------+                       |
///     |                      /         \                      |
///     |                     |  <Value>  |                     |
///     |                      \         /                      |
///     |                       +-------+                       |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```
public struct SliderTaskView<Header: View, SliderView: View>: View {
    
    // MARK: - Properties
    
    @Environment(\.careKitStyle) private var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    private let isHeaderPadded: Bool
    private let isSliderViewPadded: Bool
    private let header: Header
    private let sliderView: SliderView
    private let instructions: Text?
    
    public var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
                VStack { header }
                    .if(isCardEnabled && isHeaderPadded) { $0.padding([.horizontal, .top]) }
                
                instructions?
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(nil)
                    .if(isCardEnabled) { $0.padding([.horizontal]) }
                
                VStack { sliderView }
                    .if(isCardEnabled && isHeaderPadded) { $0.padding([.horizontal, .bottom]) }
            }
        }
    }
    
    // MARK: - Init
    
    private init(isHeaderPadded: Bool, isSliderViewPadded: Bool,
                 instructions: Text?, @ViewBuilder header: () -> Header, @ViewBuilder sliderView: () -> SliderView) {
        self.isHeaderPadded = isHeaderPadded
        self.isSliderViewPadded = isSliderViewPadded
        self.instructions = instructions
        self.header = header()
        self.sliderView = sliderView()
    }
    
    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    /// - Parameter sliderView: View to inject under the header. Specified content will be stacked vertically.
    public init(instructions: Text? = nil, @ViewBuilder header: () -> Header, @ViewBuilder sliderView: () -> SliderView) {
        self.init(isHeaderPadded: false, isSliderViewPadded: false, instructions: instructions, header: header, sliderView: sliderView)
    }
}

public extension SliderTaskView where Header == _SliderTaskViewHeader {
    
    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter sliderView: View to inject under the header. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, @ViewBuilder sliderView: () -> SliderView) {
        self.init(isHeaderPadded: true, isSliderViewPadded: false, instructions: instructions, header: {
            _SliderTaskViewHeader(title: title, detail: detail)
        }, sliderView: sliderView)
    }
}

public extension SliderTaskView where SliderView == _SliderTaskViewSliderView {
    
    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete; True if the button under the slider is in the completed.
    /// - Parameter initialValue: The initial value the slider begins on. Default value is the midpoint of the range.
    /// - Parameter value: The binded value that the slider will reflect
    /// - Parameter range: The range that includes all possible values.
    /// - Parameter step: Value of the increment that the slider takes. Default value is 1
    /// - Parameter minimumImage: Image to display to the left of the slider. Default value is nil.
    /// - Parameter maximumImage: Image to display to the right of the slider. Default value is nil.
    /// - Parameter sliderStyle: The style of the slider, either the SwiftUI system slider or the custom filler slider.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    init(instructions: Text? = nil, isComplete: Bool,
         initialValue: CGFloat? = nil, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat = 1,
         minimumImage: Image? = nil, maximumImage: Image? = nil, sliderStyle: OCKSliderStyle = .system,
         action: @escaping (Double) -> Void,
         @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isSliderViewPadded: true, instructions: instructions, header: header, sliderView: {
            _SliderTaskViewSliderView(initialValue: initialValue,
                                  value: value,
                                  range: range,
                                  step: step,
                                  isComplete: isComplete,
                                  minimumImage: minimumImage,
                                  maximumImage: maximumImage,
                                  sliderStyle: sliderStyle,
                                  action: action)
        })
    }
}

public extension SliderTaskView where Header == _SliderTaskViewHeader, SliderView == _SliderTaskViewSliderView {
    
    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete; True if the button under the slider is in the completed.
    /// - Parameter initialValue: The initial value the slider begins on. Default value is the midpoint of the range.
    /// - Parameter value: The binded value that the slider will reflect
    /// - Parameter range: The range that includes all possible values.
    /// - Parameter step: Value of the increment that the slider takes. Default value is 1
    /// - Parameter minimumImage: Image to display to the left of the slider. Default value is nil.
    /// - Parameter maximumImage: Image to display to the right of the slider. Default value is nil.
    /// - Parameter sliderStyle: The style of the slider, either the SwiftUI system slider or the custom filler slider.
    /// - Parameter action: Action to perform when the button is tapped.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, isComplete: Bool,
         initialValue: CGFloat? = nil, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat = 1,
         minimumImage: Image? = nil, maximumImage: Image? = nil, sliderStyle: OCKSliderStyle,
         action: @escaping (Double) -> Void) {
        self.init(isHeaderPadded: true, isSliderViewPadded: true, instructions: instructions, header: {
            _SliderTaskViewHeader(title: title, detail: detail)
        }, sliderView: {
            _SliderTaskViewSliderView(initialValue: initialValue,
                                  value: value,
                                  range: range,
                                  step: step,
                                  isComplete: isComplete,
                                  minimumImage: minimumImage,
                                  maximumImage: maximumImage,
                                  sliderStyle: sliderStyle,
                                  action: action)
        })
    }
}

/// The default header used by a `SliderTaskView`.
public struct _SliderTaskViewHeader: View {

    @Environment(\.careKitStyle) private var style

    fileprivate let title: Text
    fileprivate let detail: Text?

    public var body: some View {
        VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
            HeaderView(title: title, detail: detail)
            Divider()
        }
    }
}

/// The default slider view used by an `SliderTaskView`.
public struct _SliderTaskViewSliderView: View {
    
    @Binding var value: CGFloat
    fileprivate let initialValue: CGFloat
    fileprivate let isComplete: Bool
    fileprivate let minimumImage: Image?
    fileprivate let maximumImage: Image?
    fileprivate let range: ClosedRange<CGFloat>
    fileprivate let step: CGFloat
    fileprivate let sliderStyle: OCKSliderStyle
    fileprivate let action: (_ value: Double) -> Void
    
    
    init(initialValue: CGFloat?, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat,
         isComplete: Bool, minimumImage: Image?, maximumImage: Image?, sliderStyle: OCKSliderStyle,
         action: @escaping (_ value: Double) -> Void) {
        self.initialValue = initialValue ?? range.lowerBound + round((range.upperBound - range.lowerBound) / (step * 2)) * step
        self.isComplete = isComplete
        self.action = action
        self.minimumImage = minimumImage
        self.maximumImage = maximumImage
        self.range = range
        self.step = step
        self.sliderStyle = sliderStyle
        _value = value
        
    }
    
    public var body: some View {
        VStack {
            OCKSlider(value: $value, range: range, step: step,
                      isComplete: isComplete, minimumImage: minimumImage, maximumImage: maximumImage, sliderStyle: sliderStyle)
            OCKSliderButton(value: $value, isComplete: isComplete, action: action)
        }
        .onAppear {
            if !isComplete {
                value = initialValue
            }
        }
    }
}

#endif

//
//  SliderLogTaskView.swift
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
public struct SliderLogTaskView<Header: View, Slider: View>: View {
    
    // MARK: - Properties
    
    @Environment(\.careKitStyle) private var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    private let isHeaderPadded: Bool
    private let isSliderPadded: Bool
    private let header: Header
    private let slider: Slider
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
                
                VStack { slider }
                    .if(isCardEnabled && isHeaderPadded) { $0.padding([.horizontal, .bottom]) }
            }
        }
    }
    
    // MARK: - Init
    
    private init(isHeaderPadded: Bool, isSliderPadded: Bool,
                 instructions: Text?, @ViewBuilder header: () -> Header, @ViewBuilder slider: () -> Slider) {
        self.isHeaderPadded = isHeaderPadded
        self.isSliderPadded = isSliderPadded
        self.instructions = instructions
        self.header = header()
        self.slider = slider()
    }
    
    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    /// - Parameter sliderView: View to inject under the header. Specified content will be stacked vertically.
    public init(instructions: Text? = nil, @ViewBuilder header: () -> Header, @ViewBuilder slider: () -> Slider) {
        self.init(isHeaderPadded: false, isSliderPadded: false, instructions: instructions, header: header, slider: slider)
    }
}

public extension SliderLogTaskView where Header == _SliderLogTaskViewHeader {
    
    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter sliderView: View to inject under the header. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, @ViewBuilder slider: () -> Slider) {
        self.init(isHeaderPadded: true, isSliderPadded: false, instructions: instructions, header: {
            _SliderLogTaskViewHeader(title: title, detail: detail)
        }, slider: slider)
    }
}

public extension SliderLogTaskView where Slider == _SliderLogTaskViewSlider {
    
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
    init(instructions: Text? = nil,
         value: Binding<Double>, range: ClosedRange<Double>, step: Double = 1,
         minimumImage: Image? = nil, maximumImage: Image? = nil, sliderStyle: SliderStyle = .system,
         action: @escaping (Double) -> Void,
         @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isSliderPadded: true, instructions: instructions, header: header, slider: {
            _SliderLogTaskViewSlider(value: value,
                                  range: range,
                                  step: step,
                                  minimumImage: minimumImage,
                                  maximumImage: maximumImage,
                                  sliderStyle: sliderStyle,
                                  action: action)
        })
    }
}

public extension SliderLogTaskView where Header == _SliderLogTaskViewHeader, Slider == _SliderLogTaskViewSlider {
    
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
    init(title: Text, detail: Text? = nil, instructions: Text? = nil,
         value: Binding<Double>, range: ClosedRange<Double>, step: Double = 1,
         minimumImage: Image? = nil, maximumImage: Image? = nil, sliderStyle: SliderStyle = .system,
         action: @escaping (Double) -> Void) {
        self.init(isHeaderPadded: true, isSliderPadded: true, instructions: instructions, header: {
            _SliderLogTaskViewHeader(title: title, detail: detail)
        }, slider: {
            _SliderLogTaskViewSlider(value: value,
                                  range: range,
                                  step: step,
                                  minimumImage: minimumImage,
                                  maximumImage: maximumImage,
                                  sliderStyle: sliderStyle,
                                  action: action)
        })
    }
}

/// The default header used by a `SliderTaskView`.
public struct _SliderLogTaskViewHeader: View {

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
public struct _SliderLogTaskViewSlider: View {
    
    @Binding var value: Double
    fileprivate let initialValue: Double
    fileprivate let minimumImage: Image?
    fileprivate let maximumImage: Image?
    fileprivate let range: ClosedRange<Double>
    fileprivate let step: Double
    fileprivate let sliderStyle: SliderStyle
    fileprivate let action: (_ value: Double) -> Void
    
    
    init(value: Binding<Double>, range: ClosedRange<Double>, step: Double,
         minimumImage: Image?, maximumImage: Image?, sliderStyle: SliderStyle,
         action: @escaping (_ value: Double) -> Void) {
        self.initialValue = range.lowerBound + round((range.upperBound - range.lowerBound) / (step * 2)) * step
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
            SliderButton(value: $value, action: action)
            
            Slider(value: $value, range: range, step: step,
                   minimumImage: minimumImage, maximumImage: maximumImage, sliderStyle: sliderStyle)
        }
        .onAppear {
            value = initialValue
        }
    }
}

#endif

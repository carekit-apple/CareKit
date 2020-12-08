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
///     |             <Min Desc>        <Max Desc>              |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  |                      <Log>                      |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     |                   <Latest Value: >                    |
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
    /// - Parameter valuesArray: The binded array of all outcome values
    /// - Parameter value: The binded value that the slider will reflect
    /// - Parameter range: The range that includes all possible values.
    /// - Parameter step: Value of the increment that the slider takes. Default value is 1
    /// - Parameter minimumImage: Image to display to the left of the slider. Default value is nil.
    /// - Parameter maximumImage: Image to display to the right of the slider. Default value is nil.
    /// - Parameter minimumDescription: Description to display next to lower bound value. Default value is nil.
    /// - Parameter maximumDescription: Description to display next to upper bound value. Default value is nil.
    /// - Parameter sliderStyle: The style of the slider, either the SwiftUI system slider or the custom bar slider.
    /// - Parameter gradientColors:  The colors to use when drawing a color gradient inside the slider. Colors are drawn such that lower indexes correspond to the minimum side of the scale, while colors at higher indexes in the array correspond to the maximum side of the scale. Setting this value to nil results in no gradient being drawn. Defaults to nil. An example usage would set an array of red and green to visually indicate a scale from bad to good.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    init(instructions: Text? = nil,
         valuesArray: Binding<[Double]>, value: Binding<Double>, range: ClosedRange<Double>, step: Double = 1,
         minimumImage: Image? = nil, maximumImage: Image? = nil,
         minimumDescription: String? = nil, maximumDescription: String? = nil,
         sliderStyle: SliderStyle = .system, gradientColors: [Color]? = nil,
         action: @escaping (Double) -> Void,
         @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isSliderPadded: true, instructions: instructions, header: header, slider: {
            _SliderLogTaskViewSlider(valuesArray: valuesArray,
                                     value: value,
                                     range: range,
                                     step: step,
                                     minimumImage: minimumImage,
                                     maximumImage: maximumImage,
                                     minimumDescription: minimumDescription,
                                     maximumDescription: maximumDescription,
                                     sliderStyle: sliderStyle,
                                     gradientColors: gradientColors,
                                     action: action)
        })
    }
}

public extension SliderLogTaskView where Header == _SliderLogTaskViewHeader, Slider == _SliderLogTaskViewSlider {
    
    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter valuesArray: The binded array of all outcome values
    /// - Parameter value: The binded value that the slider will reflect
    /// - Parameter range: The range that includes all possible values.
    /// - Parameter step: Value of the increment that the slider takes. Default value is 1
    /// - Parameter minimumImage: Image to display to the left of the slider. Default value is nil.
    /// - Parameter maximumImage: Image to display to the right of the slider. Default value is nil.
    /// - Parameter minimumDescription: Description to display next to lower bound value. Default value is nil.
    /// - Parameter maximumDescription: Description to display next to upper bound value. Default value is nil.
    /// - Parameter sliderStyle: The style of the slider, either the SwiftUI system slider or the custom bar slider.
    /// - Parameter gradientColors:  The colors to use when drawing a color gradient inside the slider. Colors are drawn such that lower indexes correspond to the minimum side of the scale, while colors at higher indexes in the array correspond to the maximum side of the scale. Setting this value to nil results in no gradient being drawn. Defaults to nil. An example usage would set an array of red and green to visually indicate a scale from bad to good.
    /// - Parameter action: Action to perform when the button is tapped.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil,
         valuesArray: Binding<[Double]>, value: Binding<Double>, range: ClosedRange<Double>, step: Double = 1,
         minimumImage: Image? = nil, maximumImage: Image? = nil,
         minimumDescription: String? = nil, maximumDescription: String? = nil,
         sliderStyle: SliderStyle = .system, gradientColors: [Color]? = nil,
         action: @escaping (Double) -> Void) {
        self.init(isHeaderPadded: true, isSliderPadded: true, instructions: instructions, header: {
            _SliderLogTaskViewHeader(title: title, detail: detail)
        }, slider: {
            _SliderLogTaskViewSlider(valuesArray: valuesArray,
                                     value: value,
                                     range: range,
                                     step: step,
                                     minimumImage: minimumImage,
                                     maximumImage: maximumImage,
                                     minimumDescription: minimumDescription,
                                     maximumDescription: maximumDescription,
                                     sliderStyle: sliderStyle,
                                     gradientColors: gradientColors,
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
    
    @State var isActive: Bool = false
    @Binding var value: Double
    @Binding var valuesArray: [Double]
    fileprivate let initialValue: Double
    fileprivate let minimumImage: Image?
    fileprivate let maximumImage: Image?
    fileprivate let minimumDescription: String?
    fileprivate let maximumDescription: String?
    fileprivate let range: ClosedRange<Double>
    fileprivate let step: Double
    fileprivate let sliderStyle: SliderStyle
    fileprivate let gradientColors: [Color]?
    fileprivate let action: (_ value: Double) -> Void
    
    
    init(valuesArray: Binding<[Double]>, value: Binding<Double>, range: ClosedRange<Double>, step: Double,
         minimumImage: Image?, maximumImage: Image?,
         minimumDescription: String?, maximumDescription: String?,
         sliderStyle: SliderStyle,
         gradientColors: [Color]?,
         action: @escaping (_ value: Double) -> Void) {
        self.initialValue = range.lowerBound + round((range.upperBound - range.lowerBound) / (step * 2)) * step
        self.action = action
        self.minimumImage = minimumImage
        self.maximumImage = maximumImage
        self.minimumDescription = minimumDescription
        self.maximumDescription = maximumDescription
        self.range = range
        self.step = step
        self.sliderStyle = sliderStyle
        self.gradientColors = gradientColors
        _value = value
        _valuesArray = valuesArray
    }
    
    public var body: some View {
        VStack {
            Slider(value: $value, isActive: $isActive, range: range, step: step,
                   minimumImage: minimumImage, maximumImage: maximumImage,
                   minimumDescription: minimumDescription, maximumDescription: maximumDescription,
                   sliderStyle: sliderStyle, gradientColors: gradientColors)
            
            SliderLogButton(isActive: $isActive, valuesArray: $valuesArray, value: $value, action: action)
        }
        .onAppear {
            value = initialValue
        }
    }
}

#endif

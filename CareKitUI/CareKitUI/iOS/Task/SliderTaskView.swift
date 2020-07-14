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

/// A card that displays a header view, multi-line label, and a completion button.
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
///     |  +-------------------------------------------------+  |
///     |  |               <Completion Button>               |  |
///     |  +-------------------------------------------------+  |
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
    /// - Parameter sliderview: View to inject under the header. Specified content will be stacked vertically.
    public init(instructions: Text? = nil, @ViewBuilder header: () -> Header, @ViewBuilder sliderView: () -> SliderView) {
        self.init(isHeaderPadded: false, isSliderViewPadded: false, instructions: instructions, header: header, sliderView: sliderView)
    }
}

public extension SliderTaskView where Header == _SliderTaskViewHeader {
    
    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter sliderview: View to inject under the header. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, @ViewBuilder sliderView: () -> SliderView) {
        self.init(isHeaderPadded: true, isSliderViewPadded: false, instructions: instructions, header: {
            _SliderTaskViewHeader(title: title, detail: detail)
        }, sliderView: sliderView)
    }
}

public extension SliderTaskView where SliderView == _SliderTaskViewFooter {
    
    /// Create an instance.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete; True if the button under the slider is in the completed.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter minimumImage: Image to display to the left of the slider. Default value is nil.
    /// - Parameter maximumImage: Image to display to the right of the slider. Default value is nil.
    /// - Parameter initialValue: Value that the slider begins on. Must be within the range.
    /// - Parameter range: The range that includes all possible values.
    /// - Parameter step: Value of the increment that the slider takes.
    /// - Parameter sliderHeight: Height of the bar of the slider.  Default value is 40.
    /// - Parameter frameHeightMultiplier: Value to multiply the slider height by to attain the hieght of the frame enclosing the slider. Default value is 1.7.
    init( @ViewBuilder header: () -> Header,
                       instructions: Text? = nil,
                       isComplete: Bool,
                       action: @escaping () -> Void = {},
                       minimumImage: Image? = nil, maximumImage: Image? = nil,
                       initialValue: CGFloat, range: ClosedRange<CGFloat>, step: CGFloat,
                       sliderHeight: CGFloat = 40, frameHeightMultiplier: CGFloat = 1.7,
                       useDefaultSlider: Bool) {
        self.init(isHeaderPadded: false, isSliderViewPadded: true, instructions: instructions, header: header, sliderView: {
            _SliderTaskViewFooter(isComplete: isComplete,
                                  action: action,
                                  maximumImage: maximumImage, minimumImage: minimumImage,
                                  initialValue: initialValue, range: range, step: step,
                                  sliderHeight: sliderHeight, frameHeightMultiplier: frameHeightMultiplier,
                                  useDefaultSlider: useDefaultSlider)
        })
    }
}

public extension SliderTaskView where Header == _SliderTaskViewHeader, SliderView == _SliderTaskViewFooter {
    
    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete; True if the button under the slider is in the completed.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter minimumImage: Image to display to the left of the slider. Default value is nil.
    /// - Parameter maximumImage: Image to display to the right of the slider. Default value is nil.
    /// - Parameter initialValue: Value that the slider begins on. Must be within the range.
    /// - Parameter range: The range that includes all possible values.
    /// - Parameter step: Value of the increment that the slider takes.
    /// - Parameter sliderHeight: Height of the bar of the slider.  Default value is 40.
    /// - Parameter frameHeightMultiplier: Value to multiply the slider height by to attain the hieght of the frame enclosing the slider. Default value is 1.7.
    init(title: Text, detail: Text? = nil,
         instructions: Text? = nil,
         isComplete: Bool,
         action: @escaping () -> Void = {},
         minimumImage: Image? = nil, maximumImage: Image? = nil,
         initialValue: CGFloat, range: ClosedRange<CGFloat>, step: CGFloat,
         sliderHeight: CGFloat = 40, frameHeightMultiplier: CGFloat = 1.7,
         useDefaultSlider: Bool) {
        self.init(isHeaderPadded: true, isSliderViewPadded: true, instructions: instructions, header: {
            _SliderTaskViewHeader(title: title, detail: detail)
        }, sliderView: {
            _SliderTaskViewFooter(isComplete: isComplete,
                                  action: action,
                                  maximumImage: maximumImage, minimumImage: minimumImage,
                                  initialValue: initialValue, range: range, step: step,
                                  sliderHeight: sliderHeight, frameHeightMultiplier: frameHeightMultiplier,
                                  useDefaultSlider: useDefaultSlider)
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

/// The default footer used by an `SliderTaskView`.
public struct _SliderTaskViewFooter: View {
    
    @Environment(\.careKitStyle) private var style
    
    fileprivate let isComplete: Bool
    fileprivate let action: () -> Void
    fileprivate let maximumImage: Image?
    fileprivate let minimumImage: Image?
    fileprivate let range: ClosedRange<CGFloat>
    fileprivate let step: CGFloat
    fileprivate let sliderHeight: CGFloat
    fileprivate let frameHeightMultiplier: CGFloat
    fileprivate let useDefaultSlider: Bool
    @State var value: CGFloat = 0
    
    private func initialValueInRange(initialValue: CGFloat, range: ClosedRange<CGFloat>) -> State<CGFloat> {
        return initialValue > range.upperBound ? State(initialValue: range.upperBound) : (initialValue < range.lowerBound ? State(initialValue: range.lowerBound) : State(initialValue: initialValue))
    }
    
    init(isComplete: Bool, action: @escaping () -> Void, maximumImage: Image?, minimumImage: Image?, initialValue: CGFloat, range: ClosedRange<CGFloat>, step: CGFloat, sliderHeight: CGFloat, frameHeightMultiplier: CGFloat, useDefaultSlider: Bool){
        self.isComplete = isComplete
        self.action = action
        self.maximumImage = maximumImage
        self.minimumImage = minimumImage
        self.range = range
        self.step = step
        self.sliderHeight = sliderHeight
        self.frameHeightMultiplier = frameHeightMultiplier
        self.useDefaultSlider = useDefaultSlider
        _value = initialValueInRange(initialValue: initialValue, range: range)
    }
    
    public var body: some View {
        VStack {
            OCKSlider(value: self.$value, range: self.range, step: self.step, isComplete: self.isComplete, minimumImage: self.minimumImage, maximumImage: self.maximumImage, sliderHeight: self.sliderHeight, frameHeightMultiplier: self.frameHeightMultiplier, useDefaultSlider: self.useDefaultSlider)
            OCKSliderButton(value: self.$value, isComplete: self.isComplete, action: self.action)
        }
    }
}

#endif

//
//  OCKSlider.swift
//  
//
//  Created by Dylan Li on 6/22/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//
#if !os(watchOS)

import SwiftUI

public struct OCKSlider: View {
    
    @Environment(\.careKitStyle) private var style
    
    @Binding private var value: CGFloat
    private let isComplete: Bool
    private var range: (CGFloat, CGFloat)
    private let step: CGFloat
    private let minimumImage: Image?
    private let maximumImage: Image?
    private let leftBarColor: Color = .accentColor
    private var rightBarColor: Color = Color.white
    private var borderColor: Color = Color.gray
    private var borderWidth: CGFloat = 1
    private let sliderHeight: CGFloat?
    private let frameHeight: CGFloat?
    private let usesSystemSlider: Bool
    
    private var containsImages: Bool {
        if minimumImage == nil, maximumImage == nil {
            return false
        } else {
            return true
        }
    }
    
    init(value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat, isComplete: Bool, minimumImage: Image?, maximumImage: Image?, sliderStyle: SliderStyle) {
        _value = value
        self.range = (range.lowerBound, range.upperBound)
        self.step = step
        self.isComplete = isComplete
        self.minimumImage = minimumImage
        self.maximumImage = maximumImage
        switch sliderStyle {
        case .filler(let sliderDimensions):
            self.sliderHeight = sliderDimensions.sliderHeight
            self.frameHeight = sliderHeight! * sliderDimensions.frameHeightMultiplier
            self.usesSystemSlider = false
        case .system:
            self.sliderHeight = nil
            self.frameHeight = nil
            self.usesSystemSlider = true
        }
        self.borderWidth = style.appearance.borderWidth2
        self.rightBarColor = Color(style.color.white)
        self.borderColor = Color(style.color.customGray)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            self.view(geometry: geometry)
        }
        .frame(height: frameHeight)
        .padding(.top)
    }
    
    private func view(geometry: GeometryProxy) -> some View {
        
        let frameWidth = geometry.size.width
        let imageWidth = (frameWidth / 8).rounded()
        var sliderWidth: CGFloat { containsImages ? frameWidth - imageWidth * 2 - imageWidth / 2 : frameWidth }
        var knobWidth: CGFloat { sliderWidth * 0.1 }
        let drag = self.isComplete ? nil : DragGesture(minimumDistance: 0)
        
        return HStack(spacing: 0) {
            minimumImage?
                .sliderImageModifier(width: imageWidth, height: usesSystemSlider ? imageWidth : sliderHeight)
            
            Spacer(minLength: 0)
            
            if usesSystemSlider {
                Slider(value: $value, in: range.0...range.1)
                    .gesture(drag.onChanged({ drag in
                        onDragChange(drag, sliderWidth: sliderWidth, knobWidth: knobWidth) }))
                    .disabled(isComplete)
                    .frame(width: sliderWidth, height: sliderHeight)
            } else {
                ZStack {
                    addTicks(range: range, step: step, sliderWidth: sliderWidth, sliderHeight: sliderHeight!, knobWidth: knobWidth)
                    sliderView(width: sliderWidth, height: sliderHeight!, knobWidth: knobWidth)
                        .gesture(drag.onChanged({ drag in
                            onDragChange(drag, sliderWidth: sliderWidth, knobWidth: knobWidth) }))
                        .disabled(isComplete)
                }.frame(width: sliderWidth, height: usesSystemSlider ? imageWidth : sliderHeight)
            }
            
            Spacer(minLength: 0)
                
            maximumImage?
                .sliderImageModifier(width: imageWidth, height: usesSystemSlider ? imageWidth : sliderHeight)
        }
    }
    
    private func sliderView(width: CGFloat, height: CGFloat, knobWidth: CGFloat) -> some View {
        let offsetX = getOffsetX(sliderWidth: width, knobWidth: knobWidth)
        let barLeftSize = CGSize(width: CGFloat(offsetX + knobWidth / 2), height: height)
        let barRightSize = CGSize(width: width - barLeftSize.width, height: height)
        
        let components = DefaultSliderComponents(
            barLeft: DefaultSliderModifier(name: .barLeft, size: barLeftSize, offset: 0),
            barRight: DefaultSliderModifier(name: .barRight, size: barRightSize, offset: barLeftSize.width)
        )
        
        return
            ZStack {
                rightBarColor
                    .modifier(components.barRight)
                    .cornerRadius(style.appearance.cornerRadius1)
                leftBarColor
                    .modifier(components.barLeft)
                    .cornerRadius(style.appearance.cornerRadius1)
                RoundedRectangle(cornerRadius: style.appearance.cornerRadius1)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
    }
    
    private func addTicks(range: (CGFloat, CGFloat), step: CGFloat, sliderWidth: CGFloat, sliderHeight: CGFloat, knobWidth: CGFloat) -> some View {
        var values = [CGFloat]()
        var possibleValue = range.0
        while possibleValue <= range.1 {
            values.append(possibleValue)
            possibleValue += step
        }
        let tickLocations = values.map {
            CGFloat(values.firstIndex(of: $0)!) * (sliderWidth - knobWidth) / CGFloat(values.count - 1)
        }
        
        return ZStack {
            ForEach(tickLocations, id: \.self) { location in
                DefaultSliderTickMark(possibleLocations: tickLocations, location: location, sliderHeight: sliderHeight, values: values, color: self.borderColor)
            }
        }.offset(x: knobWidth / 2)
    }
    
    private func onDragChange(_ drag: DragGesture.Value, sliderWidth: CGFloat, knobWidth: CGFloat) {
        let width = (knob: knobWidth, view: sliderWidth)
        let xrange = (min: CGFloat(0), max: width.view - width.knob)
        var dragValue = drag.startLocation.x + drag.translation.width
        dragValue -= 0.5 * width.knob
        dragValue = dragValue > xrange.max ? xrange.max : dragValue
        dragValue = dragValue < xrange.min ? xrange.min : dragValue
        dragValue = dragValue.convert(fromRange: (xrange.min, xrange.max), toRange: (range.0, range.1))
        dragValue = round(dragValue / step) * step
        self.value = dragValue
    }
    
    private func getOffsetX(sliderWidth: CGFloat, knobWidth: CGFloat) -> CGFloat {
        let width = (knob: knobWidth, view: sliderWidth)
        let xrange = (CGFloat(0), width.view - width.knob)
        let result = self.value.convert(fromRange: (range.0, range.1), toRange: xrange)
        return result
    }
}

public enum SliderStyle {
    case filler(OCKSliderDimensions)
    case system
}

public struct OCKSliderDimensions {
    let sliderHeight: CGFloat
    let frameHeightMultiplier: CGFloat
    
    /// Create the dimensions used to determine appearance of an OCK Slider with a filler style
    /// - Parameter sliderHeight: Height of the bar of the slider.  Default value is 40.
    /// - Parameter frameHeightMultiplier: Value to multiply the slider height by to attain the hieght of the frame enclosing the slider. Default value is 1.7.
    public init(sliderHeight: CGFloat = 40, frameHeightMultiplier: CGFloat = 1.7) {
        self.sliderHeight = sliderHeight
        self.frameHeightMultiplier = frameHeightMultiplier
    }
}

private struct DefaultSliderTickMark: View {
    private let color: Color
    private let location: CGFloat
    private let value: CGFloat
    private enum PositionalHeight: CGFloat {
        case middle = 1.5
        case end = 1.7
    }
    private let position: PositionalHeight
    private let sliderHeight: CGFloat
    private let width: CGFloat = 1
    private var length: CGFloat { sliderHeight * position.rawValue }
    
    private init(sliderHeight: CGFloat, location: CGFloat, position: PositionalHeight, value: CGFloat, color: Color) {
        self.location = location
        self.value = value
        self.sliderHeight = sliderHeight
        self.position = position
        self.color = color
    }
    
    public init(possibleLocations: [CGFloat], location: CGFloat, sliderHeight: CGFloat, values: [CGFloat], color: Color) {
        let value = values[possibleLocations.firstIndex(of: location)!]
        if possibleLocations.firstIndex(of: location) != 0, possibleLocations.firstIndex(of: location) != possibleLocations.count - 1 {
            self.init(sliderHeight: sliderHeight, location: location, position: .middle, value: value, color: color)
        } else {
            self.init(sliderHeight: sliderHeight, location: location, position: .end, value: value, color: color)
        }
    }
    
    var body: some View {
        
        let tickMark = Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .position(x: location, y: sliderHeight / 2)
        let label = Text(position == .end ? String(format: "%g", value) : "")
            .font(.footnote)
            .foregroundColor(color)
            .position(x: location, y: -sliderHeight / 4 - (length - sliderHeight) / 2)
        
        return ZStack {
            label
            tickMark
        }
    }
}

private struct DefaultSliderComponents {
    let barLeft: DefaultSliderModifier
    let barRight: DefaultSliderModifier
}

private struct DefaultSliderModifier: ViewModifier {
    enum Name {
        case barLeft
        case barRight
    }
    let name: Name
    let size: CGSize
    let offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width)
            .position(x: size.width * 0.5, y: size.height * 0.5)
            .offset(x: offset)
    }
}

private extension Image {
    func sliderImageModifier(width: CGFloat, height: CGFloat? = 40) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
    }
}

private extension CGFloat {
    func convert(fromRange: (CGFloat, CGFloat), toRange: (CGFloat, CGFloat)) -> CGFloat {
        var value = self
        value -= fromRange.0
        value /= CGFloat(fromRange.1 - fromRange.0)
        value *= toRange.1 - toRange.0
        value += toRange.0
        return value
    }
}

#endif

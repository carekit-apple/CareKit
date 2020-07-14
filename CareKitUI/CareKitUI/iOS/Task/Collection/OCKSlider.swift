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
    private var range: (CGFloat, CGFloat)
    private let step: CGFloat
    private let leftBarColor: Color = .accentColor
    private var rightBarColor: Color = Color.white
    private var borderColor: Color = Color.gray
    private let isComplete: Bool
    private let minimumImage: Image?
    private let maximumImage: Image?
    private var sliderHeight: CGFloat
    private var frameHeight: CGFloat
    private var borderWidth: CGFloat = 1
    private let useDefaultSlider: Bool
    private var containsImages: Bool {
        if minimumImage == nil, maximumImage == nil {
            return false
        } else {
            return true
        }
    }
    
    init(value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat, isComplete: Bool, minimumImage: Image?, maximumImage: Image?, sliderHeight: CGFloat, frameHeightMultiplier: CGFloat, useDefaultSlider: Bool) {
        _value = value
        self.range = (range.lowerBound, range.upperBound)
        self.step = step
        self.isComplete = isComplete
        self.minimumImage = minimumImage
        self.maximumImage = maximumImage
        self.sliderHeight = sliderHeight
        self.frameHeight = sliderHeight * frameHeightMultiplier
        self.useDefaultSlider = useDefaultSlider
        self.rightBarColor = Color(style.color.white)
        self.borderColor = Color(style.color.customGray)
        self.borderWidth = style.appearance.borderWidth2
    }
    
    public var body: some View {
        GeometryReader { geometry in
            self.view(geometry: geometry)
        }
        .frame(height: frameHeight)
        .padding(.top)
    }
    
    private func view(geometry: GeometryProxy) -> some View {
        
        let frameWidth: CGFloat = geometry.size.width
        let imageWidth: CGFloat = (frameWidth / 8).rounded()
        var sliderWidth: CGFloat { containsImages ? frameWidth - imageWidth * 2 - imageWidth / 2 : frameWidth }
        var knobWidth: CGFloat { sliderWidth * 0.1 }
        let drag = self.isComplete ? nil : DragGesture(minimumDistance: 0)
        
        return HStack(spacing: 0) {
            self.minimumImage?
                .sliderImageModifier(width: imageWidth, height: sliderHeight)
            
            Spacer(minLength: 0)
            
            if self.useDefaultSlider {
                Slider(value: self.$value, in: self.range.0...self.range.1)
                    .gesture(drag.onChanged( { drag in
                        self.onDragChange(drag, sliderWidth: sliderWidth, knobWidth: knobWidth) } ))
                    .frame(width: sliderWidth, height: sliderHeight)
            } else {
                ZStack {
                    self.addTicks(range: self.range, step: self.step, sliderWidth: sliderWidth, sliderHeight: sliderHeight, knobWidth: knobWidth)
                    self.sliderView(width: sliderWidth, height: sliderHeight, knobWidth: knobWidth)
                }.frame(width: sliderWidth, height: sliderHeight)
            }
            
            Spacer(minLength: 0)
                
            self.maximumImage?
                .sliderImageModifier(width: imageWidth, height: sliderHeight)
        }
    }
    
    private func sliderView(width: CGFloat, height: CGFloat, knobWidth: CGFloat) -> some View {
        let drag = isComplete ? nil : DragGesture(minimumDistance: 0)
        
        let offsetX = self.getOffsetX(sliderWidth: width, knobWidth: knobWidth)
        let barLeftSize = CGSize(width: CGFloat(offsetX + knobWidth / 2), height: height)
        let barRightSize = CGSize(width: width - barLeftSize.width, height: height)
        
        let components = DefaultSliderComponents(
            barLeft: DefaultSliderModifier(name: .barLeft, size: barLeftSize, offset: 0),
            barRight: DefaultSliderModifier(name: .barRight, size: barRightSize, offset: barLeftSize.width)
        )
        
        return
            ZStack {
                self.rightBarColor
                    .modifier(components.barRight)
                    .cornerRadius(style.appearance.cornerRadius1)
                self.leftBarColor
                    .modifier(components.barLeft)
                    .cornerRadius(style.appearance.cornerRadius1)
                RoundedRectangle(cornerRadius: style.appearance.cornerRadius1)
                    .stroke(borderColor, lineWidth: borderWidth)
            }.gesture(drag.onChanged( { drag in
                self.onDragChange(drag, sliderWidth: width, knobWidth: knobWidth) } ))
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
        let width = (knob: CGFloat(knobWidth), view: CGFloat(sliderWidth))
        let xrange = (min: CGFloat(0), max: CGFloat(width.view - width.knob))
        var value = CGFloat(drag.startLocation.x + drag.translation.width)
        value -= 0.5 * width.knob
        value = value > xrange.max ? xrange.max : value
        value = value < xrange.min ? xrange.min : value
        value = value.convert(fromRange: (xrange.min, xrange.max), toRange: (CGFloat(range.0), CGFloat(range.1)))
        value = round(value / CGFloat(self.step)) * CGFloat(self.step)
        self.value = value
    }
    
    private func getOffsetX(sliderWidth: CGFloat, knobWidth: CGFloat) -> CGFloat {
        let width = (knob: knobWidth, view: sliderWidth)
        let xrange: (CGFloat, CGFloat) = (0, CGFloat(width.view - width.knob))
        let result = CGFloat(self.value).convert(fromRange: (CGFloat(range.0), CGFloat(range.1)), toRange: xrange)
        return result
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
    func sliderImageModifier(width: CGFloat, height: CGFloat) -> some View {
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

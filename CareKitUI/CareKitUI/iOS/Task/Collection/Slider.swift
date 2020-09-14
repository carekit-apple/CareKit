//
//  Slider.swift
//
//
//  Created by Dylan Li on 6/22/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import SwiftUI

struct Slider: View {
    
    @Environment(\.careKitStyle) private var style
    
    @Binding private var value: Double
    private let range: (Double, Double)
    private let step: Double
    private let minimumImage: Image?
    private let maximumImage: Image?
    private let sliderHeight: CGFloat?
    private let frameHeight: CGFloat
    private let cornerRadius: CGFloat?
    private let borderWidth: CGFloat = 1
    private let usesSystemSlider: Bool
    private var containsImages: Bool { (minimumImage == nil && maximumImage == nil) ? false : true }
    
    init(value: Binding<Double>, range: ClosedRange<Double>, step: Double, minimumImage: Image?, maximumImage: Image?, sliderStyle: SliderStyle) {
        _value = value
        self.range = (range.lowerBound, range.upperBound)
        self.step = step
        self.minimumImage = minimumImage
        self.maximumImage = maximumImage
        switch sliderStyle {
        case .ticked:
            self.sliderHeight = 40
            self.frameHeight = 80
            self.cornerRadius = 15
            self.usesSystemSlider = false
        case .system:
            self.sliderHeight = nil
            self.frameHeight = 40
            self.cornerRadius = nil
            self.usesSystemSlider = true
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            view(geometry: geometry)
        }
        .frame(height: frameHeight)
        .padding(.top)
    }
    
    private func view(geometry: GeometryProxy) -> some View {
        let frameWidth = geometry.size.width
        let imageWidth = (frameWidth / 8).rounded()
        return
            HStack(spacing: 0) {
                minimumImage?
                    .sliderImageModifier(width: imageWidth, height: usesSystemSlider ? imageWidth : sliderHeight!)
                
                Spacer(minLength: 0)
                
                slider(frameWidth: frameWidth, imageWidth: imageWidth)
                
                Spacer(minLength: 0)
                
                maximumImage?
                    .sliderImageModifier(width: imageWidth, height: usesSystemSlider ? imageWidth : sliderHeight!)
            }
            .padding(.top, (sliderHeight ?? 0) * 0.65)
    }
    
    private func slider(frameWidth: CGFloat, imageWidth: CGFloat) -> some View {
        let sliderWidth = containsImages ? frameWidth - imageWidth * 2 - imageWidth / 2 : frameWidth
        let knobWidth = cornerRadius == nil ? sliderWidth * 0.1 : cornerRadius! * 1.8
        let drag = DragGesture(minimumDistance: 0)
        return
            usesSystemSlider ?
            ViewBuilder.buildEither(first:
                                        SwiftUI.Slider(value: $value, in: range.0...range.1)
                                        .gesture(drag.onChanged({ drag in
                                                                    onDragChange(drag, sliderWidth: sliderWidth, knobWidth: knobWidth) }))
                                        .frame(width: sliderWidth)) :
            ViewBuilder.buildEither(second:
                                        ZStack {
                                            addTicks(sliderWidth: sliderWidth, knobWidth: knobWidth)
                                            fillerBarView(width: sliderWidth, height: sliderHeight!, knobWidth: knobWidth)
                                                .gesture(drag.onChanged({ drag in
                                                                            onDragChange(drag, sliderWidth: sliderWidth, knobWidth: knobWidth) }))
                                        }.frame(width: sliderWidth, height: sliderHeight)
            )
    }
    
    private func fillerBarView(width: CGFloat, height: CGFloat, knobWidth: CGFloat) -> some View {
        let offsetX = getOffsetX(sliderWidth: width, knobWidth: knobWidth)
        let barLeftSize = CGSize(width: CGFloat(offsetX + knobWidth / 2), height: height)
        let barRightSize = CGSize(width: width, height: height)
        let barLeftColor = Color.accentColor
        let barRightColor = Color(style.color.white)
        return
            ZStack {
                barRightColor
                    .modifier(SliderModifier(size: barRightSize, radius: cornerRadius!))
                barLeftColor
                    .modifier(SliderModifier(size: barLeftSize, radius: cornerRadius!))
                RoundedRectangle(cornerRadius: cornerRadius!)
                    .stroke(Color(style.color.customGray), lineWidth: borderWidth)
            }
    }
    
    private func addTicks(sliderWidth: CGFloat, knobWidth: CGFloat) -> some View {
        var values = [Double]()
        var possibleValue = range.0
        while possibleValue <= range.1 {
            values.append(possibleValue)
            possibleValue += step
        }
        let spacing = (sliderWidth - knobWidth) / CGFloat(values.count - 1) - borderWidth
        return
            HStack(spacing: spacing) {
                ForEach(values, id: \.self) { value in
                    SliderTickMark(value: value, values: values, sliderHeight: sliderHeight!, width: borderWidth, color: Color(style.color.customGray))
                }
            }
            .frame(height: sliderHeight!)
    }
    
    private func onDragChange(_ drag: DragGesture.Value, sliderWidth: CGFloat, knobWidth: CGFloat) {
        let width = (knob: knobWidth, view: sliderWidth)
        let xrange = (min: Double(0), max: Double(width.view - width.knob))
        var dragValue = Double(drag.startLocation.x + drag.translation.width)
        dragValue -= 0.5 * Double(width.knob)
        dragValue = dragValue > xrange.max ? xrange.max : dragValue
        dragValue = dragValue < xrange.min ? xrange.min : dragValue
        dragValue = dragValue.convert(fromRange: (xrange.min, xrange.max), toRange: (range.0, range.1))
        dragValue = round(dragValue / step) * step
        self.value = dragValue
    }
    
    private func getOffsetX(sliderWidth: CGFloat, knobWidth: CGFloat) -> CGFloat {
        let width = (knob: knobWidth, view: sliderWidth)
        let xrange = (Double(0), Double(width.view - width.knob))
        let result = self.value.convert(fromRange: (range.0, range.1), toRange: xrange)
        return CGFloat(result)
    }
}

private struct SliderModifier: ViewModifier {
    let size: CGSize
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width)
            .position(x: size.width * 0.5, y: size.height * 0.5)
            .cornerRadius(radius)
    }
}

private struct SliderTickMark: View {
    private let color: Color
    private let value: Double
    private enum PositionalHeight: CGFloat {
        case middle = 1.5
        case end = 1.7
    }
    private let position: PositionalHeight
    private let sliderHeight: CGFloat
    private let width: CGFloat
    private let fontSize: CGFloat?
    private var length: CGFloat { sliderHeight * position.rawValue }
    
    private init(sliderHeight: CGFloat, position: PositionalHeight, value: Double, color: Color, width: CGFloat) {
        self.value = value
        self.sliderHeight = sliderHeight
        self.position = position
        self.color = color
        self.width = width
        self.fontSize = position == .end ? 15 : nil
    }
    
    public init(value: Double, values: [Double], sliderHeight: CGFloat, width: CGFloat, color: Color) {
        let index = values.firstIndex(of: value)!
        if index != 0, index != values.count - 1 {
            self.init(sliderHeight: sliderHeight, position: .middle, value: value, color: color, width: width)
        } else {
            self.init(sliderHeight: sliderHeight, position: .end, value: value, color: color, width: width)
        }
    }
    
    var body: some View {
        let tickMark = Rectangle()
            .fill(color)
            .frame(width: width, height: length)
        
        return
            VStack(spacing: fontSize) {
                if position == .end {
                    Text(String(format: "%g", value))
                        .font(.system(size: fontSize!))
                        .frame(width: fontSize! * 3, height: fontSize!)
                        .foregroundColor(color)
                }
                tickMark
                    
            }
            .if(position == .end) { $0.offset(y: -fontSize!)}
            .frame(width: width)
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

private extension Double {
    func convert(fromRange: (Double, Double), toRange: (Double, Double)) -> Double {
        var value = self
        value -= fromRange.0
        value /= (fromRange.1 - fromRange.0)
        value *= toRange.1 - toRange.0
        value += toRange.0
        return value
    }
}

#endif

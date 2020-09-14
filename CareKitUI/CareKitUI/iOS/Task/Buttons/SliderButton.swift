//
//  OCKSliderButton.swift
//
//
//  Created by Dylan Li on 6/27/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import SwiftUI

struct SliderButton: View {
    
    @Environment(\.careKitStyle) private var style
    
    @Binding var value: Double
    let action: (_ value: Double) -> Void
    private let diameter: CGFloat = 60
    private let borderWidth: CGFloat = 3
    private let fontSize: CGFloat = 25
    private let foregroundColor: Color = .accentColor
    private let text = Text(loc("LOG"))
    private var backgroundColor: Color { Color(style.color.white) }
    
    public var body: some View {
        Button(action: {
            action(value)
        }) {
            ZStack {
                Circle()
                    .frame(width: diameter, height: diameter)
                    .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: borderWidth))
                    .foregroundColor(backgroundColor)
                Group {
                    Text(String(format: "%g", value))
                        .font(.system(size: fontSize))
                        .fontWeight(.semibold)
                    text
                        .font(.system(size: diameter * 0.2))
                        .fontWeight(.semibold)
                        .offset(y: diameter * 0.3)
                }.foregroundColor(foregroundColor)
            }
        }
        .buttonStyle(NoHighlightStyle())
        .padding(.top)
    }
}

#endif

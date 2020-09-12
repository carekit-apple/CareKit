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
    
    @Binding var value: CGFloat
    let isComplete: Bool
    let action: (_ value: Double) -> Void
    private let diameter: CGFloat = 60
    private let borderWidth: CGFloat = 3
    private let fontSize: CGFloat = 25
    
    private var foregroundColor: Color {
        isComplete ? Color(style.color.white) : .accentColor
    }
    
    private var backgroundColor: Color {
        isComplete ? .accentColor : Color(style.color.white)
    }
    
    private var text: Text? {
        isComplete ? Text(loc("DONE")) : nil
    }
    
    public var body: some View {
        Button(action: {
            action(Double(value))
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
                    text?
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

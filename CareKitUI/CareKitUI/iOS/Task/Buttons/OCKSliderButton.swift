//
//  DefaultSliderCompletionView.swift
//  
//
//  Created by Dylan Li on 6/27/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import SwiftUI

public struct OCKSliderButton: View {
    
    @Environment(\.careKitStyle) private var style
    
    @Binding var value: CGFloat
    let isComplete: Bool
    let action: () -> Void
    private let diameter: CGFloat = 60
    private let borderWidth: CGFloat = 2
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
        GeometryReader { geometry in
            Button(action: self.action) {
                ZStack {
                    Circle()
                        .overlay(Circle().stroke(Color.accentColor, lineWidth: self.borderWidth))
                        .foregroundColor(self.backgroundColor)
                    Group {
                        Text(String(format: "%g", self.value))
                            .font(.system(size: self.fontSize))
                            .fontWeight(.semibold)
                        self.text?
                            .font(.system(size: self.diameter * 0.2))
                            .fontWeight(.semibold)
                            .offset(y: self.diameter * 0.3)
                    }.foregroundColor(self.foregroundColor)
                }
            }
            .frame(width: geometry.size.width)
            .buttonStyle(NoHighlightStyle())
        }.frame(height: diameter).padding(.top)
    }
}
#endif

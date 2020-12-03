//
//  OCKSliderButton.swift
//
//
//  Created by Dylan Li on 6/27/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import SwiftUI

struct SliderLogButton: View {
    
    @Environment(\.careKitStyle) private var style
    
    @Binding var isActive: Bool
    @Binding var valuesArray: [Double]
    @Binding var value: Double
    let action: (_ value: Double) -> Void
    
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: style.appearance.cornerRadius2, style: .continuous)
    }
    
    var background: some View {
        shape
            .fill(Color.accentColor)
    }
    
    var valueText: String {
        valuesArray.count == 0 ? loc("NO_VALUES_LOGGED") : (loc("LATEST_VALUE") + ": " + String(format: "%g", valuesArray[0]))
    }

    public var body: some View {
        VStack {
            Button(action: {
                action(value)
                isActive = false
            }) {
                HStack {
                    Spacer()
                    
                    Text(loc("LOG"))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding([.top,.bottom])
                .clipShape(shape)
                .background(background)
                .font(Font.subheadline.weight(.medium))
                .foregroundColor(.accentColor)
            }
            .disabled(!isActive)
            .padding(.bottom)
            
            Button(action: {print(valuesArray.count)}) {
                Text(valueText)
                    .foregroundColor(.accentColor)
                    .font(Font.subheadline.weight(.medium))
            }
            .disabled(valuesArray.count == 0)
        }
        .buttonStyle(NoHighlightStyle())
    }
}

#endif

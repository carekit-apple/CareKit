//
//  TestSliderTaskView.swift
//
//
//  Created by Dylan Li on 7/27/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

import CareKitUI
import SwiftUI
import XCTest

class TestSliderTaskView: XCTestCase {
    
    @State var value: CGFloat = 0

    func testDefaultInitializers() {
        var body: some View {
            Group {
                SliderTaskView(title: Text(""), detail:  Text(""), instructions:  Text(""), isComplete: false,
                               initialValue: 5, value: $value, range: 0...10, step: 1, minimumImage: nil, maximumImage: nil, sliderStyle: .system, action: { _ in })
                SliderTaskView(title: Text(""), isComplete: false,
                               initialValue: 5, value: $value,  range: 0...10, step: 1, sliderStyle: .filler(OCKSliderDimensions()), action: { _ in })
                SliderTaskView(title: Text(""), isComplete: false,
                               initialValue: 5, value: $value,  range: 0...10, step: 1, sliderStyle: .filler(OCKSliderDimensions(height: 100, cornerRadius: 2)), action: { _ in })
            }
        }
    }

    func testCustomInitializers() {
        var body: some View {
            Group {
                SliderTaskView(header: { EmptyView() }, sliderView: { EmptyView() })
                SliderTaskView(isComplete: true, initialValue: 50, value: $value, range: 10...100, step: 2, sliderStyle: .system, action: { _ in }, header: { EmptyView() })
                SliderTaskView(title: Text(""), sliderView: { EmptyView() })
            }
        }
    }
}

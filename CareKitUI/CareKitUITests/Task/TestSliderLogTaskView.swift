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

    func testInitializers() {
        var body: some View {
            MockSliderView()
        }
    }
}

struct MockSliderView: View {
    
    let value: Double = 0
    
    var body: some View {
        // Default initializers
        SliderLogTaskView(title: Text(""), detail:  Text(""), instructions:  Text(""), value: .constant(value), range: 0...10, step: 1, sliderStyle: .ticked, action: { _ in })
        
        SliderLogTaskView(title: Text(""), value: .constant(value), range: 0...10, minimumImage: Image(systemName: "chevron.down"), maximumImage: Image(systemName: "chevron.up"), action: { _ in })
        
        // Custom initializers
        SliderLogTaskView(header: { EmptyView() }, slider: { EmptyView() })
        
        SliderLogTaskView(value: .constant(value), range: 10...100, step: 2, sliderStyle: .system, action: { _ in }, header: { EmptyView() })
        
        SliderLogTaskView(title: Text(""), slider: { EmptyView() })
    }
}

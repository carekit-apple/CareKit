

import CareKitUI
import SwiftUI
import XCTest

class TestSliderTaskView: XCTestCase {
    
    @State private var value: CGFloat = 0

    func testDefaultInitializers() {
        _ = SliderTaskView(title: Text(""), detail:  Text(""), instructions:  Text(""), isComplete: false, value: $value, range: 0...10, step: 1, minimumImage: nil, maximumImage: nil, sliderStyle: .system, action: { _ in })
        _ = SliderTaskView(title: Text(""), isComplete: false, value: $value,  range: 0...10, step: 1, sliderStyle: .filler(OCKSliderDimensions()), action: { _ in })
        _ = SliderTaskView(title: Text(""), isComplete: false, value: $value,  range: 0...10, step: 1, sliderStyle: .filler(OCKSliderDimensions(sliderHeight: 100, frameHeightMultiplier: 2)), action: { _ in })
    }

    func testCustomInitializers() {
        _ = SliderTaskView(header: { EmptyView() }, sliderView: { EmptyView() })
        _ = SliderTaskView(isComplete: true, value: $value,range: 10...100, step: 2, sliderStyle: .system, action: { _ in }, header: { EmptyView() })
        _ = SliderTaskView(title: Text(""), sliderView: { EmptyView() })
    }
}

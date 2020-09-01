//
//  TestSliderTaskView.swift
//
//
//  Created by Dylan Li on 7/27/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

import CareKit
import CareKitStore
import CareKitUI
import Foundation
import SwiftUI
import XCTest

@available(iOS 14.0, watchOS 7.0, *)
class TestSliderTaskView: XCTestCase {
    let controller: OCKSliderTaskController = {
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        return .init(storeManager: .init(wrapping: store))
    }()
    
    @State var value: CGFloat = 6

    let eventQuery = OCKEventQuery(for: Date())
    let task = OCKTask(id: "", title: "", carePlanUUID: nil, schedule: .dailyAtTime(hour: 1, minutes: 0, start: Date(), end: nil, text: nil))
    var staticView: CareKitUI.SliderTaskView<_SliderTaskViewHeader, _SliderTaskViewSliderView> {
        CareKitUI.SliderTaskView(title: Text(""),
                                 detail: Text(""),
                                 instructions: Text(""),
                                 isComplete: false,
                                 initialValue: 2, value: $value,
                                 range: 0...10, step: 2,
                                 minimumImage: nil, maximumImage: nil,
                                 sliderStyle: .UISlider,
                                 action: { _ in })
    }

    func testDefaultContentInitializers() {
        _ = CareKit.SliderTaskView(task: task, eventQuery: eventQuery, storeManager: controller.storeManager)
        _ = CareKit.SliderTaskView(taskID: "", eventQuery: eventQuery, storeManager: controller.storeManager)
        _ = CareKit.SliderTaskView(controller: controller)
    }

    func testCustomContentInitializers() {
        _ = CareKit.SliderTaskView(task: task, eventQuery: eventQuery, storeManager: controller.storeManager) { controller, value in self.staticView }
        _ = CareKit.SliderTaskView(taskID: "", eventQuery: eventQuery, storeManager: controller.storeManager) { controller, value in self.staticView }
        _ = CareKit.SliderTaskView(controller: controller) { controller, value in self.staticView }
    }
}

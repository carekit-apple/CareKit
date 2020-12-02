//
//  TestSliderLogTaskView.swift
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
class TestSliderLogTaskView: XCTestCase {
    let controller: OCKSliderLogTaskController = {
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        return .init(storeManager: .init(wrapping: store))
    }()
    
    @State var value: Double = 6
    @State var valuesArray: [Double] = []

    let eventQuery = OCKEventQuery(for: Date())
    let task = OCKTask(id: "", title: "", carePlanUUID: nil, schedule: .dailyAtTime(hour: 1, minutes: 0, start: Date(), end: nil, text: nil))
    var staticView: CareKitUI.SliderLogTaskView<_SliderLogTaskViewHeader, _SliderLogTaskViewSlider> {
        CareKitUI.SliderLogTaskView(title: Text(""),
                                 detail: Text(""),
                                 instructions: Text(""),
                                 valuesArray: $valuesArray,
                                 value: $value,
                                 range: 0...10,
                                 step: 2,
                                 minimumImage: nil,
                                 maximumImage: nil,
                                 sliderStyle: .system,
                                 action: { _ in })
    }

    func testDefaultContentInitializers() {
        _ = CareKit.SliderLogTaskView(task: task, eventQuery: eventQuery, storeManager: controller.storeManager)
        _ = CareKit.SliderLogTaskView(taskID: "", eventQuery: eventQuery, storeManager: controller.storeManager)
        _ = CareKit.SliderLogTaskView(controller: controller)
    }

    func testCustomContentInitializers() {
        _ = CareKit.SliderLogTaskView(task: task, eventQuery: eventQuery, storeManager: controller.storeManager) { controller, value, valuesArray in self.staticView }
        _ = CareKit.SliderLogTaskView(taskID: "", eventQuery: eventQuery, storeManager: controller.storeManager) { controller, value, valuesArray  in self.staticView }
        _ = CareKit.SliderLogTaskView(controller: controller) { controller, value, valuesArray  in self.staticView }
    }
}

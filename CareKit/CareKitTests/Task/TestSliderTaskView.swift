//
//  TestSliderTaskView.swift
//  
//
//  Created by Dylan Li on 7/9/20.
//

import CareKit
import CareKitStore
import CareKitUI
import Foundation
import SwiftUI
import XCTest

@available(iOS 14.0, watchOS 7.0, *)
class TestSliderTaskView: XCTestCase {

    let controller: OCKNumericProgressTaskController = {
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        return .init(storeManager: .init(wrapping: store))
    }()

    let eventQuery = OCKEventQuery(for: Date())
    let task = OCKTask(id: "", title: "", carePlanUUID: nil, schedule: .dailyAtTime(hour: 1, minutes: 0, start: Date(), end: nil, text: nil))
    let staticView = CareKitUI.NumericProgressTaskView(title: Text(""), progress: Text(""), goal: Text(""), isComplete: false)

    func testDefaultContentInitializers() {
        _ = CareKit.NumericProgressTaskView(task: task, eventQuery: eventQuery, storeManager: controller.storeManager)
        _ = CareKit.NumericProgressTaskView(taskID: "", eventQuery: eventQuery, storeManager: controller.storeManager)
        _ = CareKit.NumericProgressTaskView(controller: controller)
    }

    func testCustomContentInitializers() {
        _ = CareKit.NumericProgressTaskView(task: task, eventQuery: eventQuery, storeManager: controller.storeManager) { _ in self.staticView }
        _ = CareKit.NumericProgressTaskView(taskID: "", eventQuery: eventQuery, storeManager: controller.storeManager) { _ in self.staticView }
        _ = CareKit.NumericProgressTaskView(controller: controller) { _ in self.staticView }
    }
}

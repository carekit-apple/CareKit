/*
 Copyright (c) 2020, Apple Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CareKit
import CareKitStore
import CareKitUI
import Foundation
import SwiftUI
import XCTest

@available(iOS 14.0, watchOS 7.0, *)
class TestLabeledValueTaskView: XCTestCase {

    let controller: OCKLabeledValueTaskController = {
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        return .init(storeManager: .init(wrapping: store))
    }()

    let eventQuery = OCKEventQuery(for: Date())
    let task = OCKTask(id: "", title: "", carePlanUUID: nil, schedule: .dailyAtTime(hour: 1, minutes: 0, start: Date(), end: nil, text: nil))
    let staticView = CareKitUI.LabeledValueTaskView(title: Text(""), state: .incomplete(Text("")))

    func testDefaultContentInitializers() {
        _ = CareKit.LabeledValueTaskView(task: task, eventQuery: eventQuery, storeManager: controller.storeManager)
        _ = CareKit.LabeledValueTaskView(taskID: "", eventQuery: eventQuery, storeManager: controller.storeManager)
        _ = CareKit.LabeledValueTaskView(controller: controller)
    }

    func testCustomContentInitializers() {
        _ = CareKit.LabeledValueTaskView(task: task, eventQuery: eventQuery, storeManager: controller.storeManager) { _ in self.staticView }
        _ = CareKit.LabeledValueTaskView(taskID: "", eventQuery: eventQuery, storeManager: controller.storeManager) { _ in self.staticView }
        _ = CareKit.LabeledValueTaskView(controller: controller) { _ in self.staticView }
    }
}

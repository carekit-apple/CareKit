/*
 Copyright (c) 2019, Apple Inc. All rights reserved.

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
import Foundation

extension OCKHealthKitPassthroughStore {

    enum Tasks: String, CaseIterable {
        case steps
    }

    func fillWithDummyData() {
        // Note: If the tasks and contacts already exist in the store, these methods will fail. If you have modified the data and would like the
        // changes to be reflected in the app, delete and reinstall the catalog app.
        let aFewDaysAgo = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -10, to: Date())!)
        addAnyTasks(makeTasks(on: aFewDaysAgo), callbackQueue: .main) { result in
            switch result {
            case .failure(let error): print("[ERROR] \(error.localizedDescription)")
            case .success: break
            }
        }
    }

    private func makeTasks(on start: Date) -> [OCKAnyTask] {
        // Steps task
        let stepsScheduleElement = OCKScheduleElement(start: start, end: nil, interval: .init(day: 1),
                                                      text: nil, targetValues: [OCKOutcomeValue(500.0)], duration: .allDay)
        let hkLinkage = OCKHealthKitLinkage(quantityIdentifier: .stepCount, quantityType: .cumulative, unit: .count())
        var stepsTask = OCKHealthKitTask(id: Tasks.steps.rawValue, title: "Steps", carePlanUUID: nil,
                                         schedule: .init(composing: [stepsScheduleElement]), healthKitLinkage: hkLinkage)
        stepsTask.instructions = "A walk a day keeps the doctor away."

        return [stepsTask]
    }
}

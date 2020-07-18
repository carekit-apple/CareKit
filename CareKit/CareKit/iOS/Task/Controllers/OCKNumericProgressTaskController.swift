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
#if !os(watchOS)

import CareKitStore
import Combine
import Foundation

open class OCKNumericProgressTaskController: OCKTaskController {

    /// Data used to create a `CareKitUI.NumericProgressTaskTaskView`.
    @Published public private(set) var viewModel: NumericProgressTaskViewModel? {
        willSet { objectWillChange.send() }
    }

    private var cancellable: AnyCancellable?

    public required init(storeManager: OCKSynchronizedStoreManager) {
        super.init(storeManager: storeManager)
        cancellable = $taskEvents.sink { [unowned self] taskEvents in
            self.viewModel = self.makeViewModel(from: taskEvents)
        }
    }

    private func makeViewModel(from taskEvents: OCKTaskEvents) -> NumericProgressTaskViewModel? {
        guard !taskEvents.isEmpty else { return nil }

        let event = taskEvents.first?.first

        let goalValue = (event?.scheduleEvent.element.targetValues.first?.numberValue?.doubleValue)
            .logIfNil(message: "No target value found for the numeric progress task.")
            ?? 0

        let progressValue = (event?.outcome?.values.first?.numberValue?.doubleValue)
            .logIfNil(message: "No progress value found for the numeric progress task.")
            ?? 0

        let isComplete = progressValue >= goalValue
        let goal = goalValue.removingExtraneousDecimal() ?? "0"
        let progress = progressValue.removingExtraneousDecimal() ?? "0"

        return .init(title: taskEvents.firstEventTitle,
                     detail: taskEvents.firstEventDetail,
                     instructions: taskEvents.firstTaskInstructions,
                     progress: progress, goal: goal,
                     isComplete: isComplete)
    }
}

private extension Double {
    func test() {

    }
}

private extension Optional where Wrapped == Double {
    func logIfNil(message: String) -> Self {
        switch self {
        case .none: log(.debug, "Encountered nil value in OCKNumericProgressTaskController")
        case .some: break
        }
        return self
    }
}

#endif

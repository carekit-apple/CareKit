/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
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
import ResearchKit

/**
 Protocol that adds a method to the `Activity` protocol that returns an `ORKTask`
 to present to the user.
 */
protocol Assessment: Activity {
    func task() -> ORKTask
}


/**
 Extends instances of `Assessment` to add a method that returns a
 `OCKCarePlanEventResult` for a `OCKCarePlanEvent` and `ORKTaskResult`. The
 `OCKCarePlanEventResult` can then be written to a `OCKCarePlanStore`.
 */
extension Assessment {
    func buildResultForCarePlanEvent(event: OCKCarePlanEvent, taskResult: ORKTaskResult) -> OCKCarePlanEventResult {
        // Get the first result for the first step of the task result.
        guard let firstResult = taskResult.firstResult as? ORKStepResult, stepResult = firstResult.results?.first else { fatalError("Unexepected task results") }
        
        // Determine what type of result should be saved.
        if let scaleResult = stepResult as? ORKScaleQuestionResult, answer = scaleResult.scaleAnswer {
            return OCKCarePlanEventResult(valueString: answer.stringValue, unitString: "out of 10", userInfo: nil)
        }
        else if let numericResult = stepResult as? ORKNumericQuestionResult, answer = numericResult.numericAnswer {
            return OCKCarePlanEventResult(valueString: answer.stringValue, unitString: numericResult.unit, userInfo: nil)
        }
        
        fatalError("Unexpected task result type")
    }
}

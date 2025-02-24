/*
 Copyright (c) 2022, Apple Inc. All rights reserved.
 
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

import Foundation
import os.log

/// A protocol that describes user progress for a task.
public protocol CareTaskProgress {

    /// The fraction of the task that completed between 0 and 1 inclusive.
    ///
    /// When using CareKit, the value is clamped to ensure it's within the proper range.
    var fractionCompleted: Double { get }
}

extension CareTaskProgress {

    var clampedFractionCompleted: Double {

        let isClampingRequired = fractionCompleted < 0 || fractionCompleted > 1

        // Make sure to notify the developer if we need to clamp the value. The need to clamp
        // the value is typically an indicator that there's an issue in their implementation of
        // `fractionCompleted`.
        if isClampingRequired {

            if #available(iOS 14, watchOS 7, *) {

                Logger.store?.error(
                    "Clamping progress value of \(fractionCompleted, privacy: .public) to be within range [0, 1]."
                )

            } else {

                os_log(
                    "Clamping progress value of %{public}@ to be within range [0, 1].",
                    log: .store,
                    type: .error,
                    fractionCompleted
                )
            }
        }

        return min(max(fractionCompleted, 0), 1)
    }
}

public extension CareTaskProgress {

    /// A property set to `true` if the task is considered completed.
    var isCompleted: Bool {

        let isCompleted = fractionCompleted >= 1
        return isCompleted
    }
}

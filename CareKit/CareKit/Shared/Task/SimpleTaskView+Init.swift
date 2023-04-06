/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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

import CareKitStore
import CareKitUI
import Foundation
import SwiftUI

public extension SimpleTaskView {

    /// Create a view using data from an event.
    ///
    /// This view displays a button to toggle completion for the event.
    ///
    /// - Parameters:
    ///   - event: The data be displayed in the view.
    ///   - header: Short and descriptive content that identifies the event.
    ///   - onError: A closure that the struct calls if an error occurs while toggling completion for the event.
    init(
        event: CareStoreFetchedResult<OCKAnyEvent>,
        @ViewBuilder header: () -> Header,
        onError: @escaping (OCKStoreError) -> Void = { _ in }
    ) {

        let progress = event.result.computeProgress(by: .checkingOutcomeExists)

        self.init(
            isComplete: progress.isCompleted,
            action: {
                event.toggleBooleanOutcome { result in
                    switch result {
                    case .success: break
                    case let .failure(error): onError(error)
                    }
                }
            },
            header: header
        )
    }
}

public extension SimpleTaskView where Header == _SimpleTaskViewHeader {

    /// Create a view using data from an event.
    ///
    /// This view displays a button to toggle completion for the event.
    ///
    /// - Parameters:
    ///   - event: The data displayed in the view.
    ///   - onError: A closure that the struct calls if an error occurs while toggling completion for the event.
    init(
        event: CareStoreFetchedResult<OCKAnyEvent>,
        onError: @escaping (OCKStoreError) -> Void = { _ in }
    ) {

        let progress = event.result.computeProgress(by: .checkingOutcomeExists)

        self.init(
            title: Text(event.result.title),
            detail: event.result.detailText,
            isComplete: progress.isCompleted,
            action: {
                event.toggleBooleanOutcome { result in
                    switch result {
                    case .success: break
                    case let .failure(error): onError(error)
                    }
                }
            }
        )
    }
}

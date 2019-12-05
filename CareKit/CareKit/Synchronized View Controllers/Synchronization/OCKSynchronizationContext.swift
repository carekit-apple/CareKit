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

import Combine
import Foundation

/// Provides context for a view model value.
public struct OCKSynchronizationContext<ViewModel> {
    /// The current view model value.
    public let viewModel: ViewModel

    /// The previous view model value.
    public let oldViewModel: ViewModel

    /// Animated flag.
    public let animated: Bool

    public init(viewModel: ViewModel, oldViewModel: ViewModel, animated: Bool) {
        self.viewModel = viewModel
        self.oldViewModel = oldViewModel
        self.animated = animated
    }
}

protocol OptionalProtocol {
    func isSome() -> Bool
}

extension Optional: OptionalProtocol {
    func isSome() -> Bool {
        switch self {
        case .some: return true
        default: return false
        }
    }
}

extension CurrentValueSubject {
    func context() -> Publishers.Scan<CurrentValueSubject<Output, Failure>, OCKSynchronizationContext<Output>> {
        // If the `Output` is an optional, only animate if the preious value was nil. This helps stops animations from occuring on the initial load.
        let animated = value as? OptionalProtocol != nil ? (value as? OptionalProtocol)!.isSome() : true
        let context = OCKSynchronizationContext(viewModel: value, oldViewModel: value, animated: animated)
        return scan(context) { previousContext, newValue -> OCKSynchronizationContext<Output> in
            let animated = previousContext.viewModel as? OptionalProtocol != nil ?
                (previousContext.viewModel as? OptionalProtocol)!.isSome() : true
            return OCKSynchronizationContext(viewModel: newValue, oldViewModel: previousContext.viewModel, animated: animated)
        }
    }
}

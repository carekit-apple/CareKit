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

import CareKitUI
import Foundation
import SwiftUI

/// A card that updates when a controller changes. The view displays a header view, multi-line label, and a completion button.
///
/// In CareKit, this view is intended to display a particular event for a task. The state of the button indicates the completion state of the event.
///
/// # View Updates
/// The view updates with the observed controller. By default, data from the controller is mapped to the view. The mapping can be customized by
/// providing a closure that returns a view. The closure is called whenever the controller changes.
///
/// # Style
/// The card supports styling using `careKitStyle(_:)`.
///
/// ```
///     +-------------------------------------------------------+
///     |                                                       |
///     |  <Title>                                              |
///     |  <Detail>                                             |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     |  <Instructions>                                       |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  |               <Completion Button>               |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```
public struct InstructionsTaskView<Header: View, Footer: View>: View {

    private let content: (_ configuration: InstructionsTaskViewConfiguration) -> CareKitUI.InstructionsTaskView<Header, Footer>

    /// Owns the view model that drives the view.
    @ObservedObject public var controller: OCKInstructionsTaskController

    public var body: some View {
        content(.init(controller: controller))
    }

    /// Create an instance that updates the content view when the observed controller changes.
    /// - Parameter controller: Owns the view model that drives the view.
    /// - Parameter content: Return a view to display whenever the controller changes.
    public init(controller: OCKInstructionsTaskController,
                content: @escaping (_ configuration: InstructionsTaskViewConfiguration) ->
                CareKitUI.InstructionsTaskView<Header, Footer>) {
        self.controller = controller
        self.content = content
    }
}

public extension InstructionsTaskView where Header == HeaderView, Footer == _InstructionsTaskViewFooter {

    /// Create an instance that updates the content view when the observed controller changes. The default view will be displayed whenever the
    /// controller changes.
    /// - Parameter controller: Owns the view model that drives the view.
    init(controller: OCKInstructionsTaskController) {
        self.init(controller: controller, content: { .init(configuration: $0) })
    }
}

private extension CareKitUI.InstructionsTaskView where Header == HeaderView, Footer == _InstructionsTaskViewFooter {
    init(configuration: InstructionsTaskViewConfiguration) {
        self.init(title: Text(configuration.title), detail: configuration.detail.map { Text($0) },
                  instructions: configuration.instructions.map { Text($0) },
                  isComplete: configuration.isComplete, action: configuration.action)
    }
}

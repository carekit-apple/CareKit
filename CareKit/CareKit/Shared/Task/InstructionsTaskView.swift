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

import CareKitStore
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
@available(iOS 14.0, watchOS 7.0, *)
public struct InstructionsTaskView<Header: View, Footer: View>: View {

    private typealias TaskView = SynchronizedTaskView<OCKInstructionsTaskController, CareKitUI.InstructionsTaskView<Header, Footer>>

    private let taskView: TaskView

    public var body: some View {
        taskView
    }

    private init(taskView: TaskView) {
        self.taskView = taskView
    }

    /// Create an instance. The first task and event that match the provided queries will be fetched from the the store and displayed in the view.
    /// The view will update when changes occur in the store.
    /// - Parameters:
    ///     - taskID: The ID of the task to fetch.
    ///     - eventQuery: A query used to fetch an event in the store.
    ///     - storeManager: Wraps the store that contains the task and event to fetch.
    ///     - content: Create a view to display whenever the body is computed.
    public init(taskID: String, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager,
                content: @escaping (_ controller: OCKInstructionsTaskController) -> CareKitUI.InstructionsTaskView<Header, Footer>) {
        taskView = .init(controller: .init(storeManager: storeManager),
                         query: .taskIDs([taskID], eventQuery),
                         content: content)
    }

    /// Create an instance. The first event that matches the provided query will be fetched from the the store and displayed in the view. The view
    /// will update when changes occur in the store.
    /// - Parameters:
    ///     - task: The task associated with the event to fetch.
    ///     - eventQuery: A query used to fetch an event in the store.
    ///     - storeManager: Wraps the store that contains the event to fetch.
    ///     - content: Create a view to display whenever the body is computed.
    public init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager,
                content: @escaping (_ controller: OCKInstructionsTaskController) -> CareKitUI.InstructionsTaskView<Header, Footer>) {
        taskView = .init(controller: .init(storeManager: storeManager),
                         query: .tasks([task], eventQuery),
                         content: content)
    }

    /// Create an instance.
    /// - Parameters:
    ///     - controller: Controller that holds a reference to data displayed by the view.
    ///     - content: Create a view to display whenever the body is computed.
    public init(controller: OCKInstructionsTaskController,
                content: @escaping (_ controller: OCKInstructionsTaskController) -> CareKitUI.InstructionsTaskView<Header, Footer>) {
        taskView = .init(controller: controller, content: content)
    }

    /// Handle any errors that may occur.
    /// - Parameter handler: Handle the encountered error.
    public func onError(_ perform: @escaping (Error) -> Void) -> Self {
        .init(taskView: .init(copying: taskView, settingErrorHandler: perform))
    }
}

@available(iOS 14.0, watchOS 7.0, *)
public extension InstructionsTaskView where Header == _InstructionsTaskViewHeader, Footer == _InstructionsTaskViewFooter {

    /// Create an instance that displays the default content. The first task and event that match the provided queries will be fetched from the the
    /// store and displayed in the view. The view will update when changes occur in the store.
    /// - Parameters:
    ///     - taskID: The ID of the task to fetch.
    ///     - eventQuery: A query used to fetch an event in the store.
    ///     - storeManager: Wraps the store that contains the task and event to fetch.
    ///     - content: Create a view to display whenever the body is computed.
    init(taskID: String, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        self.init(taskID: taskID, eventQuery: eventQuery, storeManager: storeManager) {
            .init(viewModel: $0.viewModel)
        }
    }

    /// Create an instance that displays the default content. The first event that matches the provided query will be fetched from the the store and
    /// displayed in the view. The view will update when changes occur in the store.
    /// - Parameters:
    ///     - task: The task associated with the event to fetch.
    ///     - eventQuery: A query used to fetch an event in the store.
    ///     - storeManager: Wraps the store that contains the event to fetch.
    ///     - content: Create a view to display whenever the body is computed.
    init(task: OCKAnyTask, eventQuery: OCKEventQuery, storeManager: OCKSynchronizedStoreManager) {
        self.init(task: task, eventQuery: eventQuery, storeManager: storeManager) {
            .init(viewModel: $0.viewModel)
        }
    }

    /// Create an instance that displays the default content.
    /// - Parameters:
    ///     - controller: Controller that holds a reference to data displayed by the view.
    init(controller: OCKInstructionsTaskController) {
        taskView = .init(controller: controller) {
            .init(viewModel: $0.viewModel)
        }
    }
}

private extension CareKitUI.InstructionsTaskView where Header == _InstructionsTaskViewHeader, Footer == _InstructionsTaskViewFooter {

    init(viewModel: InstructionsTaskViewModel?) {
        self.init(title: Text(viewModel?.title ?? ""),
                  detail: viewModel?.detail.map(Text.init),
                  instructions: viewModel?.instructions.map(Text.init),
                  isComplete: viewModel?.isComplete ?? false,
                  action: viewModel?.action ?? {})
    }
}

/// Data used to create a `CareKitUI.InstructionsTaskView`.
public struct InstructionsTaskViewModel {

    /// The title text to display in the header.
    public let title: String

    /// The detail text to display in the header.
    public let detail: String?

    /// The instructions text to display under the header.
    public let instructions: String?

    /// The action to perform when the button is tapped.
    public let action: () -> Void

    /// True if the labeled button is complete.
    public let isComplete: Bool
}

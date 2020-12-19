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

struct TaskSection: View {

    var body: some View {
        Section(header: Text("Task")) {
            ForEach(TaskStyle.allCases, id: \.rawValue) { style in
                if style.supportsSwiftUI || style.supportsUIKit {
                    NavigationLink(style.rawValue.capitalized, destination: TaskDestination(style: style))
                }
            }
        }
    }
}

private struct TaskDestination: View {

    @Environment(\.storeManager) private var storeManager

    let style: TaskStyle

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            if style.supportsSwiftUI && style.supportsUIKit {
                PlatformPicker {
                    AdaptedTaskView(style: style, storeManager: storeManager)
                } swiftUIView: {
                    if #available(iOS 14, *) {
                        TaskView(style: style)
                    }
                }
            } else if style.supportsUIKit {
                AdaptedTaskView(style: style, storeManager: storeManager)
            } else if style.supportsSwiftUI {
                if #available(iOS 14, *) {
                    TaskView(style: style)
                }
            }
        }
        .navigationBarTitle(Text(style.rawValue.capitalized), displayMode: .inline)
    }
}

private enum TaskStyle: String, CaseIterable {

    case grid, checklist
    case simple, instructions, labeledValue = "labeled value", numericProgress = "Numeric Progress"
    case buttonLog = "button log"

    var supportsSwiftUI: Bool {
        guard #available(iOS 14, *) else { return false }

        switch self {
        case .simple, .instructions, .labeledValue, .numericProgress: return true
        case .grid, .checklist, .buttonLog: return false
        }
    }

    var supportsUIKit: Bool {
        switch self {
        case .simple, .instructions, .grid, .checklist, .buttonLog: return true
        case .labeledValue, .numericProgress: return false
        }
    }
}

@available(iOS 14.0, *)
private struct TaskView: View {

    @Environment(\.storeManager) private var storeManager

    let style: TaskStyle

    var body: some View {
        CardBackground {
            switch style {
            case .simple:
                SimpleTaskView(taskID: OCKStore.Tasks.doxylamine.rawValue,
                               eventQuery: .init(for: Date()), storeManager: storeManager)
            case .instructions:
                InstructionsTaskView(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                     eventQuery: .init(for: Date()), storeManager: storeManager)
            case .numericProgress:
                VStack(spacing: 16) {
                    // Linked to HealthKit data
                    CareKit.NumericProgressTaskView(taskID: OCKHealthKitPassthroughStore.Tasks.steps.rawValue,
                                                    eventQuery: .init(for: Date()), storeManager: storeManager) { controller in
                        CareKitUI.NumericProgressTaskView(title: Text((controller.viewModel?.title ?? "") + " (HealthKit Linked)"),
                                                          detail: controller.viewModel?.detail.map(Text.init),
                                                          progress: Text(controller.viewModel?.progress ?? ""),
                                                          goal: Text(controller.viewModel?.goal ?? ""),
                                                          instructions: controller.viewModel?.instructions.map(Text.init),
                                                          isComplete: controller.viewModel?.isComplete ?? false)
                    }

                    // Static view
                    CareKitUI.NumericProgressTaskView(title: Text("Steps (Static)"),
                                                      progress: Text("0"),
                                                      goal: Text("100"),
                                                      isComplete: false)

                    // Static view
                    CareKitUI.NumericProgressTaskView(title: Text("Steps (Static)"),
                                                      progress: Text("0"),
                                                      goal: Text("100"),
                                                      isComplete: true)
                }
            case .labeledValue:
                VStack(spacing: 16) {

                    // HealthKit linked view
                    CareKit.LabeledValueTaskView(taskID: OCKHealthKitPassthroughStore.Tasks.steps.rawValue,
                                                 eventQuery: .init(for: Date()), storeManager: storeManager) { controller in
                        CareKitUI.LabeledValueTaskView(title: Text((controller.viewModel?.title ?? "") + " (HealthKit Linked)"),
                                                       detail: controller.viewModel?.detail.map(Text.init),
                                                       state: .fromViewModel(state: controller.viewModel?.state))
                    }

                    // Static view
                    LabeledValueTaskView(title: Text("Heart Rate (Static)"),
                                         detail: Text("Anytime"),
                                         state: .complete(Text("62"), Text("BPM")))

                    // Static view
                    LabeledValueTaskView(title: Text("Heart Rate (Static)"),
                                         detail: Text("Anytime"),
                                         state: .incomplete(Text("NO DATA")))
                }
            default:
                EmptyView()
            }
        }
    }
}

private struct AdaptedTaskView: UIViewControllerRepresentable {

    let style: TaskStyle
    let storeManager: OCKSynchronizedStoreManager

    func makeUIViewController(context: Context) -> UIViewController {
        let listViewController = OCKListViewController()

        let spacer = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 32)))
        listViewController.appendView(spacer, animated: false)

        let taskViewController: UIViewController?
        switch style {
        case .simple:
            taskViewController = OCKSimpleTaskViewController(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                             eventQuery: .init(for: Date()), storeManager: storeManager)
        case .instructions:
            taskViewController = OCKInstructionsTaskViewController(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                                   eventQuery: .init(for: Date()), storeManager: storeManager)
        case .buttonLog:
            taskViewController = OCKButtonLogTaskViewController(taskID: OCKStore.Tasks.nausea.rawValue,
                                                                eventQuery: .init(for: Date()), storeManager: storeManager)
        case .checklist:
            taskViewController = OCKChecklistTaskViewController(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                                eventQuery: .init(for: Date()), storeManager: storeManager)
        case .grid:
            taskViewController = OCKGridTaskViewController(taskID: OCKStore.Tasks.doxylamine.rawValue,
                                                           eventQuery: .init(for: Date()), storeManager: storeManager)
        case .labeledValue, .numericProgress:
            taskViewController = nil
        }

        taskViewController.map { listViewController.appendViewController($0, animated: false) }
        return listViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private extension LabeledValueTaskViewState {

    static func fromViewModel(state: LabeledValueTaskViewModel.State?) -> Self {
        guard let state = state else {
            return .incomplete(Text(""))
        }

        switch state {
        case let .complete(value, label):
            return .complete(Text(value), label.map(Text.init))
        case let .incomplete(label):
            return .incomplete(Text(label))
        }
    }
}

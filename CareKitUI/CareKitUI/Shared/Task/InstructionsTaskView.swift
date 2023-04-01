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
import Foundation
import SwiftUI

#if os(iOS)
private let completionButtonTextPadding: CGFloat = 14
#elseif os(watchOS)
private let completionButtonTextPadding: CGFloat = 8
#endif

/// A card that displays a header view, multi-line label, and a completion button.
///
/// In CareKit, this view is intended to display a particular event for a task. The state of the button indicates the completion state of the event.
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
public struct InstructionsTaskView<Header: View>: View {

    @Environment(\.careKitStyle)
    private var style

    @Environment(\.isCardEnabled)
    private var isCardEnabled

    private let header: Header
    private let instructions: Text?
    private let isComplete: Bool
    private let action: () -> Void

    private var completionButton: some View {
        Button(action: action) {
            RectangularCompletionView(isComplete: isComplete) {
                completionButtonLabel
                    // Allows multiline text to wrap to the next line
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(completionButtonTextPadding)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(NoHighlightStyle())
    }

    @ViewBuilder
    private var completionButtonLabel: some View {
        HStack {
            Text(loc(isComplete ? "COMPLETED" : "MARK_COMPLETE"))
            if isComplete {
                Image(systemName: "checkmark")
            }
        }
    }

    public var body: some View {
        CardView {
            VStack(
                alignment: .leading,
                spacing: style.dimension.directionalInsets1.top
            ) {
                VStack { header }
                instructions?
                    .font(.subheadline)
                    .fontWeight(.medium)
                    // Allows multiline text to wrap to the next line
                    .fixedSize(horizontal: false, vertical: true)
                completionButton
            }
            .padding(isCardEnabled ? [.all] : [])
        }
    }

    /// Create an instance.
    /// - Parameters:
    ///   - instructions: Instructions text
    ///   - isComplete: True if the view denotes the completed state.
    ///   - action: Action to perform when the completion button is tapped.
    ///   - header: Injected at the top of the view.
    public init(
        instructions: Text? = nil,
        isComplete: Bool,
        action: @escaping () -> Void,
        @ViewBuilder header: () -> Header
    ) {
        self.instructions = instructions
        self.isComplete = isComplete
        self.action = action
        self.header = header()
    }
}

public extension InstructionsTaskView where Header == _InstructionsTaskViewHeader {

    /// Create an instance.
    /// - Parameters:
    ///   - title: Title to display in the header.
    ///   - detail: Detail to display in the header.
    ///   - instructions: Longer text displayed in the content of the view.
    ///   - isComplete: True if the view denotes the completed state.
    ///   - action: Action to perform when the completion button is tapped.
    init(
        title: Text,
        detail: Text? = nil,
        instructions: Text? = nil,
        isComplete: Bool,
        action: @escaping () -> Void
    ) {
        self.instructions = instructions
        self.isComplete = isComplete
        self.action = action
        self.header = _InstructionsTaskViewHeader(title: title, detail: detail)
    }
}

/// The default header used by a `InstructionsTaskView`.
public struct _InstructionsTaskViewHeader: View {

    @Environment(\.careKitStyle)
    private var style

    fileprivate let title: Text
    fileprivate let detail: Text?

    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: style.dimension.directionalInsets1.top
        ) {
            HeaderView(title: title, detail: detail)
            Divider()
        }
    }
}

#if DEBUG
struct InstructionsTaskView_Previews: PreviewProvider {

    static var previews: some View {
        ScrollView {
            VStack {

                // Default - Completed
                InstructionsTaskView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    isComplete: false,
                    action: {}
                )

                // Default - Incomplete
                InstructionsTaskView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    isComplete: true,
                    action: {}
                )

                // Custom Header
                InstructionsTaskView(
                    instructions: .loremIpsum,
                    isComplete: true,
                    action: {}
                ) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor)
                            .frame(width: 4)
                        Text("Custom Header").font(.headline)
                    }
                }

                // Larger AX size
                InstructionsTaskView(
                    title: Text("A Longer Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    isComplete: true,
                    action: {}
                )
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

                // Dark mode
                InstructionsTaskView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    isComplete: true,
                    action: {}
                )
                .environment(\.colorScheme, .dark)

            }
            .padding()
        }
    }
}
#endif

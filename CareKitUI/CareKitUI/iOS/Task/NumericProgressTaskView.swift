/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.

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

import Foundation
import SwiftUI

/// A card that displays a header, instructions, and indicators for progress and goal values.
///
/// In CareKit, this view is intended to display a particular event for a task.
///
/// ```
///     +-------------------------------------------------------+
///     |                                                       |
///     |  <Title>                                              |
///     |  <Detail>                                             |
///     |                                                       |
///     |  --------------------------------------------------   |
///     |                                                       |
///     |        <Progress Value>          <Goal Value>         |
///     |        <Progress Label>          <Goal Label>         |
///     |                                                       |
///     |                                                       |
///     |  <Instructions>                                       |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```
public struct NumericProgressTaskView<Header: View>: View {

    @Environment(\.careKitStyle)
    private var style

    @Environment(\.isCardEnabled)
    private var isCardEnabled

    private let header: Header
    private let instructions: Text?
    private let progress: Text
    private let goal: Text
    private let isComplete: Bool

    private var completionImage: Image? {
        guard isComplete else { return nil }
        return Image(systemName: "checkmark.circle.fill")
    }

    @ViewBuilder
    private var progressIndicator: some View {
        AccessibleStack(
            alignment: Alignment(horizontal: .leading, vertical: .center),
            spacing: style.dimension.directionalInsets2.trailing
        ) { isHorizontal in

            Group {
                // Progress
                LabeledValue(
                    value: progress,
                    label: Text(loc("PROGRESS").uppercased()),
                    valueImage: completionImage,
                    alignment: isHorizontal ? .center : .leading
                )
                .foregroundColor(.accentColor)
                .accessibility(value: Text(loc(isComplete ? "COMPLETED" : "INCOMPLETE")))
                // Ensures both labeled values have equal widths
                .frame(maxWidth: isHorizontal ? .infinity : nil)
                // Goal
                LabeledValue(
                    value: goal,
                    label: Text(loc("GOAL").uppercased()),
                    valueImage: nil,
                    alignment: isHorizontal ? .center : .leading
                )
                .foregroundColor(.secondary)
                // Ensures both labeled values have equal widths
                .frame(maxWidth: isHorizontal ? .infinity : nil)
            }
            .multilineTextAlignment(isHorizontal ? .center : .leading)
            .padding(isHorizontal ? .horizontal : [])
        }
    }

    public var body: some View {
        CardView {
            VStack(
                alignment: .leading,
                spacing: style.dimension.directionalInsets1.top
            ) {
                VStack { header }
                progressIndicator
                    // Allows multiline text to wrap
                    .fixedSize(horizontal: false, vertical: true)
                instructions?
                    .font(.caption)
                    .foregroundColor(.secondary)
                    // Allows multiline text to wrap
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(isCardEnabled ? [.all] : [])
        }
    }

    /// Create an instance.
    /// - Parameters:
    ///   - progress: Progress towards a `goal`.
    ///   - goal: The desired goal.
    ///   - instructions: Longer text displayed in the content of the view.
    ///   - isComplete: True if the view denotes the completed state.
    ///   - header: Injected at the top of the view.
    public init(
        progress: Text,
        goal: Text,
        instructions: Text? = nil,
        isComplete: Bool,
        @ViewBuilder header: () -> Header
    ) {
        self.progress = progress
        self.goal = goal
        self.instructions = instructions
        self.isComplete = isComplete
        self.header = header()
    }
}

public extension NumericProgressTaskView where Header == _NumericProgressTaskViewHeader {

    /// Create an instance.
    /// - Parameters:
    ///   - title: Title to display in the header.
    ///   - detail: Detail to display in the header.
    ///   - progress: Progress towards a `goal`.
    ///   - goal: The desired goal.
    ///   - instructions: Longer text displayed in the content of the view.
    ///   - isComplete: True if the view denotes the completed state.
    init(
        title: Text,
        detail: Text? = nil,
        progress: Text,
        goal: Text,
        instructions: Text? = nil,
        isComplete: Bool
    ) {
        self.progress = progress
        self.goal = goal
        self.instructions = instructions
        self.isComplete = isComplete
        self.header = _NumericProgressTaskViewHeader(title: title, detail: detail)
    }
}

/// The default header used by a `NumericProgressTaskView`.
public struct _NumericProgressTaskViewHeader: View {

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

private struct LabeledValue: View {

    let value: Text
    let label: Text
    let valueImage: Image?
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            HStack {
                value
                    .font(Font.title.weight(.bold))
                valueImage?
                    .font(Font.headline.weight(.bold))
            }

            label
                .font(Font.subheadline.weight(.medium))
        }
        .accessibilityElement(children: .combine)
        .accessibility(label: label + Text(",") + value)    // Combine the inner elements into one label
        .accessibility(removeTraits: .isImage)              // Remove the trait inherited from the `labelImage`
    }
}

#if DEBUG

struct NumericProgressTaskView_Previews: PreviewProvider {

    private static let title = Text("Exercise Minutes")
    private static let detail = Text("All Day")

    static var previews: some View {
        ScrollView {
            VStack {

                // Default - Completed
                NumericProgressTaskView(
                    title: title,
                    detail: detail,
                    progress: Text("40"),
                    goal: Text("30"),
                    instructions: .loremIpsum,
                    isComplete: true
                )

                // Default - Incomplete
                NumericProgressTaskView(
                    title: title,
                    detail: detail,
                    progress: Text("12"),
                    goal: Text("30"),
                    instructions: .loremIpsum,
                    isComplete: false
                )

                // No instructions
                NumericProgressTaskView(
                    title: title,
                    detail: detail,
                    progress: Text("12"),
                    goal: Text("30"),
                    isComplete: false
                )

                // Long progress
                NumericProgressTaskView(
                    title: title,
                    detail: detail,
                    progress: Text("10000000"),
                    goal: Text("30"),
                    isComplete: false
                )

                // Long goal
                NumericProgressTaskView(
                    title: title,
                    detail: detail,
                    progress: Text("10"),
                    goal: Text("30000000000"),
                    isComplete: false
                )

                // Custom Header
                NumericProgressTaskView(
                    progress: Text("10"),
                    goal: Text("30"),
                    instructions: .loremIpsum,
                    isComplete: false
                ) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor)
                            .frame(width: 4)
                        Text("Custom Header").font(.headline)
                    }
                }

                // Larger AX size
                NumericProgressTaskView(
                    title: title,
                    detail: detail,
                    progress: Text("4000000000"),
                    goal: Text("30"),
                    instructions: .loremIpsum,
                    isComplete: true
                )
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

                // Dark mode
                NumericProgressTaskView(
                    title: title,
                    detail: detail,
                    progress: Text("40"),
                    goal: Text("30"),
                    instructions: .loremIpsum,
                    isComplete: true
                )
                .environment(\.colorScheme, .dark)
            }
            .padding()
        }
    }
}

#endif

#endif

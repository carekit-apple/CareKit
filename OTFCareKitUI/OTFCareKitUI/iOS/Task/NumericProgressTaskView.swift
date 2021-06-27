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
public struct NumericProgressTaskView<Header: View, Content: View>: View {

    @Environment(\.careKitStyle) private var style
    @Environment(\.isCardEnabled) private var isCardEnabled

    private let isHeaderPadded: Bool
    private let isContentPadded: Bool
    private let header: Header
    private let content: Content
    private let instructions: Text?

    public var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
                VStack { header }
                    .if(isCardEnabled && isHeaderPadded) { $0.padding([.top, .horizontal]) }
                VStack { content }
                    .if(isCardEnabled && isContentPadded) { $0.padding([.horizontal]) }
                    // If this is the last view in the VStack, add padding to the bottom.
                    .if(instructions == nil && isCardEnabled && isContentPadded) { $0.padding([.bottom]) }
                instructions?
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .if(isCardEnabled) { $0.padding([.horizontal, .bottom]) }
            }
        }
    }

    /// Create an instance.
    /// - Parameters:
    ///   - instructions: Instructions text.
    ///   - header: View to inject at the top of the card. Specified content will be stacked vertically.
    ///   - content: View to inject under the header. Specified content will be stacked vertically.
    public init(instructions: Text? = nil, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.init(isHeaderPadded: false, isContentPadded: false, instructions: instructions, header: header, content: content)
    }

    private init(isHeaderPadded: Bool, isContentPadded: Bool, instructions: Text? = nil,
                 @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.isHeaderPadded = isHeaderPadded
        self.isContentPadded = isContentPadded
        self.instructions = instructions
        self.header = header()
        self.content = content()
    }
}

public extension NumericProgressTaskView where Header == _NumericProgressTaskViewHeader {

    /// Create an instance.
    /// - Parameters:
    ///   - title: Title text to display in the header.
    ///   - detail: Detail text to display in the header.
    ///   - instructions: Instructions text.
    ///   - content: View to inject under the header. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, instructions: Text? = nil, @ViewBuilder content: () -> Content) {
        self.init(isHeaderPadded: true, isContentPadded: false, instructions: instructions, header: {
            _NumericProgressTaskViewHeader(title: title, detail: detail)
        }, content: content)
    }
}

public extension NumericProgressTaskView where Content == _NumericProgressTaskViewContent {

    /// Create an instance.
    /// - Parameters:
    ///   - progress: Progress text to display in the sub-header.
    ///   - goal: Goal text to display in the sub-header.
    ///   - instructions: Instructions text.
    ///   - isComplete: True if the goal has been reached.
    ///   - header: View to inject at the top of the card. Specified content will be stacked vertically.
    init(progress: Text, goal: Text, instructions: Text? = nil, isComplete: Bool, @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isContentPadded: true, instructions: instructions, header: header, content: {
            _NumericProgressTaskViewContent(progress: progress, goal: goal, isComplete: isComplete)
        })
    }
}

public extension NumericProgressTaskView where Header == _NumericProgressTaskViewHeader, Content == _NumericProgressTaskViewContent {

    /// Create an instance.
    /// - Parameters:
    ///   - title: Title text to display in the header.
    ///   - detail: Detail text to display in the header.
    ///   - progress: Progress text to display in the sub-header.
    ///   - goal: Goal text to display in the sub-header.
    ///   - instructions: Instructions text.
    ///   - isComplete: True if the goal has been reached.
    init(title: Text, detail: Text? = nil, progress: Text, goal: Text, instructions: Text? = nil, isComplete: Bool) {
        self.init(isHeaderPadded: true, isContentPadded: true, instructions: instructions, header: {
            _NumericProgressTaskViewHeader(title: title, detail: detail)
        }, content: {
            _NumericProgressTaskViewContent(progress: progress, goal: goal, isComplete: isComplete)
        })
    }
}

/// The default header used by a `NumericProgressTaskView`.
public struct _NumericProgressTaskViewHeader: View {

    @Environment(\.careKitStyle) private var style

    fileprivate let title: Text
    fileprivate let detail: Text?

    public var body: some View {
        VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
            HeaderView(title: title, detail: detail)
            Divider()
        }
    }
}

/// The default content used by a `NumericProgressTaskView`.
public struct _NumericProgressTaskViewContent: View {

    fileprivate let progress: Text
    fileprivate let goal: Text
    fileprivate let isComplete: Bool

    private var valueImage: Image? {
        guard isComplete else { return nil }
        return Image(systemName: "checkmark.circle.fill")
    }

    public var body: some View {
        HStack {
            Spacer()
            NumericProgressIndicator(value: progress, label: Text(loc("PROGRESS").uppercased()), valueImage: valueImage)
                .foregroundColor(.accentColor)
                .if(isComplete) {
                    $0.accessibility(value: Text(loc("COMPLETED")))
                }
            Spacer()
            NumericProgressIndicator(value: goal, label: Text(loc("GOAL").uppercased()), valueImage: nil)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

/// A view that displays a labeled value. This is the default view used by the `_NumericProgressTaskViewSubHeader`.
private struct NumericProgressIndicator: View {

    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.careKitStyle) private var style

    let value: Text
    let label: Text
    let valueImage: Image?

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                value
                    .font(Font.title.weight(.bold))
                valueImage
                    .font(.system(size: style.dimension.symbolPointSize2.scaled(), weight: .bold))
            }

            label
                .font(Font.subheadline.weight(.medium))
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .accessibility(label: label + Text(",") + value)    // Combine the inner elements into one label
        .accessibility(removeTraits: .isImage)              // Remove the trait inherited from the `labelImage`
    }
}

#if DEBUG

struct NumericProgressTaskView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {

            NumericProgressTaskView(
                title: Text("Exercise Minutes"),
                detail: Text("Anytime"),
                progress: Text("22"),
                goal: Text("30"),
                instructions: Text(
                    """
                        Take time out of your day to get some exercise. Venture outside and turn play \
                        into high energy activity.
                    """
                ),
                isComplete: false)

                NumericProgressTaskView(
                    title: Text("Exercise Minutes"),
                    detail: Text("Anytime"),
                    progress: Text("22"),
                    goal: Text("30"),
                    instructions: Text(
                        """
                            Take time out of your day to get some exercise. Venture outside and turn play \
                            into high energy activity.
                        """
                    ),
                    isComplete: false)

        }.padding()
    }
}

#endif

#endif

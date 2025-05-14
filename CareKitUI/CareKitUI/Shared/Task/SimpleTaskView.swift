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

import Foundation
import SwiftUI

/// A card that displays a header view and a completion view. The whole view is tappable.
///
/// In CareKit, this view is intended to display a particular event for a task. The state of the button indicates the completion state of the event.
///
/// # Style
/// The card supports styling using `careKitStyle(_:)`.
///
/// ```
///     +-------------------------------------------------------+
///     |                                                       |
///     |  <Title>                              <Completion     |
///     |  <Detail>                              View>          |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```
public struct SimpleTaskView<Header: View>: View {

    @Environment(\.careKitStyle)
    private var style

    @Environment(\.sizeCategory)
    private var sizeCategory

    @Environment(\.isCardEnabled)
    private var isCardEnabled

    private let header: Header
    private let isComplete: Bool
    private let action: () -> Void

    private var completionView: some View {
        CircularCompletionView(isComplete: isComplete) {
            Image(systemName: "checkmark")
                .resizable()
                .padding(style.dimension.buttonHeight2 * 0.3)
                .frame(
                    width: style.dimension.buttonHeight2,
                    height: style.dimension.buttonHeight2
                )
        }
    }

    public var body: some View {
        CardView {
            Button(action: action) {
                HStack(
                    alignment: .center,
                    spacing: style.dimension.directionalInsets2.trailing
                ) {
                    VStack { header }
                    Spacer()
                    completionView
                }
                .padding(isCardEnabled ? [.all] : [])
            }
            .buttonStyle(NoHighlightStyle())
        }
    }

    /// Create an instance.
    /// - Parameters:
    ///   - isComplete: True if the view denotes the completed state.
    ///   - action: The action to perform when the view is tapped.
    ///   - header: The view to inject in the header.
    public init(
        isComplete: Bool,
        action: @escaping () -> Void = {},
        @ViewBuilder header: () -> Header
    ) {
        self.isComplete = isComplete
        self.action = action
        self.header = header()
    }
}

public extension SimpleTaskView where Header == _SimpleTaskViewHeader {

    /// Create an instance.
    /// - Parameters:
    ///   - title: The title to display in the header.
    ///   - detail: The detail to display in the header.
    ///   - isComplete: True if the view denotes the completed state.
    ///   - action: The action to perform when the whole view is tapped.
    init(
        title: Text,
        detail: Text? = nil,
        isComplete: Bool,
        action: @escaping () -> Void = {}
    ) {
        self.isComplete = isComplete
        self.action = action
        self.header = _SimpleTaskViewHeader(title: title, detail: detail)
    }
}

/// The default header used by a `SimpleTaskView`.
public struct _SimpleTaskViewHeader: View {

    fileprivate let title: Text
    fileprivate let detail: Text?

    public var body: some View {
        HeaderView(title: title, detail: detail)
    }
}

#if DEBUG
struct SimpleTaskView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {

                // Default - Completed
                SimpleTaskView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    isComplete: false,
                    action: {}
                )

                // Default - Incomplete
                SimpleTaskView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    isComplete: true,
                    action: {}
                )

                // Custom Header
                SimpleTaskView(
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
                SimpleTaskView(
                    title: Text("A Longer Title"),
                    detail: Text("Detail"),
                    isComplete: true,
                    action: {}
                )
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

                // Dark mode
                SimpleTaskView(
                    title: Text("Title"),
                    detail: Text("Detail"),
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

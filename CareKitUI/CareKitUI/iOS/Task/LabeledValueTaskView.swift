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

/// A card that displays a header and a labeled value.
///
///
/// # Style
/// The card supports styling using `careKitStyle(_:)`.
///
/// ```
///     +-------------------------------------------------------+
///     |                                                       |
///     |  <Title>                           <Value>  <Label>   |
///     |  <Detail>                                             |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```
public struct LabeledValueTaskView<Header: View>: View {

    @Environment(\.careKitStyle)
    private var style

    @Environment(\.isCardEnabled)
    private var isCardEnabled

    @Environment(\.sizeCategory)
    private var sizeCategory

    private let status: LabeledValueTaskViewStatus
    private let header: Header

    @ViewBuilder
    private var labeledValue: some View {
        AccessibleStack(
            alignment: Alignment(horizontal: .trailing, vertical: .lastTextBaseline),
            spacing: 2
        ) { _ in
            status.value?
                .font(Font.title.weight(.bold))
            status.label?
                .font(Font.caption.weight(.medium))
        }
    }

    public var body: some View {
        CardView {
            HStack(spacing: style.dimension.directionalInsets2.trailing) {
                VStack { header }
                Spacer()
                labeledValue
                    // Allow multiline text to wrap
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(status.foregroundColor)
            }
            .padding(isCardEnabled ? [.all] : [])
        }
    }

    /// Create an instance.
    /// - Parameters:
    ///   - status: The status denoted by the view.
    ///   - header: Injected at the top of the view.
    public init(
        status: LabeledValueTaskViewStatus,
        @ViewBuilder header: () -> Header
    ) {
        self.status = status
        self.header = header()
    }
}

public extension LabeledValueTaskView where Header == _LabeledValueTaskViewHeader {

    /// Create an instance with the default header.
    /// - Parameters:
    ///   - title: Title text to display in the header.
    ///   - detail: Detail text to display in the header.
    ///   - status: The status denoted by the view.
    init(
        title: Text,
        detail: Text? = nil,
        status: LabeledValueTaskViewStatus
    ) {
        self.status = status
        self.header = _LabeledValueTaskViewHeader(title: title, detail: detail)
    }
}

/// The  status denoted by a `LabeledValueTaskView`.
public enum LabeledValueTaskViewStatus {

    /// The complete state.
    case complete(_ value: Text, _ label: Text?)

    /// The incomplete state.
    case incomplete(_ label: Text)

    var value: Text? {
        switch self {
        case .complete(let value, _): return value
        case .incomplete: return nil
        }
    }

    var label: Text? {
        switch self {
        case .complete(_, let label): return label
        case .incomplete(let label): return label
        }
    }

    var foregroundColor: Color {
        switch self {
        case .complete: return .accentColor
        case .incomplete: return .secondary
        }
    }

}

/// The default header used by a `LabeledValueTaskView`.
public struct _LabeledValueTaskViewHeader: View {

    fileprivate let title: Text
    fileprivate let detail: Text?

    public var body: some View {
        HeaderView(title: title, detail: detail)
    }
}

#if DEBUG
struct NumericTaskView_Previews: PreviewProvider {
    static var previews: some View {

        ScrollView {
            VStack {

                // Default - Completed
                LabeledValueTaskView(
                    title: Text("Heart Rate"),
                    detail: Text("6:00pm"),
                    status: .complete(Text("60"), Text("BPM"))
                )

                // Default - Incomplete
                LabeledValueTaskView(
                    title: Text("Heart Rate"),
                    detail: Text("6:00pm"),
                    status: .incomplete(Text("Incomplete"))
                )

                // Custom header
                LabeledValueTaskView(
                    status: .complete(Text("60"), Text("BPM"))
                ) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor)
                            .frame(width: 4)
                        Text("Custom Header").font(.headline)
                    }
                }

                // Larger AX size
                LabeledValueTaskView(
                    title: Text("Heart Rate"),
                    detail: Text("6:00pm"),
                    status: .complete(Text("60"), Text("BPM"))
                )
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

                // Dark mode
                LabeledValueTaskView(
                    title: Text("Heart Rate"),
                    detail: Text("6:00pm"),
                    status: .complete(Text("60"), Text("BPM"))
                )
                .environment(\.colorScheme, .dark)
            }
            .padding()
        }
    }
}
#endif

#endif

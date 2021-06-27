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
public struct LabeledValueTaskView<Header: View, DetailDisclosure: View>: View {

    // MARK: - Properties

    @Environment(\.isCardEnabled) private var isCardEnabled

    private let isHeaderPadded: Bool
    private let isDetailDisclosurePadded: Bool
    private let header: Header
    private let detailDisclosure: DetailDisclosure

    public var body: some View {
        CardView {
            HStack {
                VStack { header }
                    .if(isCardEnabled && isHeaderPadded) { $0.padding([.vertical, .leading]) }
                Spacer()
                VStack { detailDisclosure }
                    .if(isCardEnabled && isDetailDisclosurePadded) { $0.padding([.vertical, .trailing]) }
            }
        }
    }

    // MARK: - Init

    private init(isHeaderPadded: Bool, isDetailDisclosurePadded: Bool,
                 @ViewBuilder header: () -> Header, @ViewBuilder detailDisclosure: () -> DetailDisclosure) {
        self.isHeaderPadded = isHeaderPadded
        self.isDetailDisclosurePadded = isDetailDisclosurePadded
        self.header = header()
        self.detailDisclosure = detailDisclosure()
    }

    /// Create an instance.
    /// - Parameters:
    ///   - header: View to inject at the top of the card. Specified content will be stacked vertically
    ///   - detailDisclosure: View to inject to the right of the header. Specified content will be stacked vertically.
    public init(@ViewBuilder header: () -> Header,
                @ViewBuilder detailDisclosure: () -> DetailDisclosure) {
        self.init(isHeaderPadded: false, isDetailDisclosurePadded: false, header: header, detailDisclosure: detailDisclosure)
    }
}

public extension LabeledValueTaskView where Header == _LabeledValueTaskViewHeader {

    /// Create an instance with the default header.
    /// - Parameters:
    ///   - title: Title text to display in the header.
    ///   - detail: Detail text to display in the header.
    ///   - detailDisclosure: View to inject to the right of the header. Specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, @ViewBuilder detailDisclosure: () -> DetailDisclosure) {
        self.init(isHeaderPadded: true, isDetailDisclosurePadded: false, header: {
            _LabeledValueTaskViewHeader(title: title, detail: detail)
        }, detailDisclosure: detailDisclosure)
    }
}

public extension LabeledValueTaskView where DetailDisclosure == _LabeledValueTaskViewDetailDisclosure {

    /// Create an instance with the default detail disclosure.
    /// - Parameters:
    ///   - state: The completion state for the view.
    ///   - header: View to inject at the top of the card. Specified content will be stacked vertically
    init(state: LabeledValueTaskViewState, @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isDetailDisclosurePadded: true, header: header, detailDisclosure: {
            _LabeledValueTaskViewDetailDisclosure(state: state)
        })
    }
}

public extension LabeledValueTaskView where Header == _LabeledValueTaskViewHeader, DetailDisclosure == _LabeledValueTaskViewDetailDisclosure {

    /// Create an instance with the default header and detail disclosure.
    /// - Parameters:
    ///   - title: Title text to display in the header.
    ///   - detail: Detail text to display in the header.
    ///   - state: The completion state of the view.
    init(title: Text, detail: Text? = nil, state: LabeledValueTaskViewState) {
        self.init(isHeaderPadded: true, isDetailDisclosurePadded: true, header: {
            _LabeledValueTaskViewHeader(title: title, detail: detail)
        }, detailDisclosure: {
            _LabeledValueTaskViewDetailDisclosure(state: state)
        })
    }
}

/// The completion state of a `LabeledValueTaskView`.
public enum LabeledValueTaskViewState {

    /// The complete state.
    case complete(_ value: Text, _ label: Text?)

    /// The incomplete state.
    case incomplete(_ label: Text)
}

/// The default detail disclosure used by a `LabeledValueTaskView`.
public struct _LabeledValueTaskViewDetailDisclosure: View {

    fileprivate let state: LabeledValueTaskViewState

    private var value: Text? {
        switch state {
        case .complete(let value, _): return value
        case .incomplete: return nil
        }
    }

    private var label: Text? {
        switch state {
        case .complete(_, let label): return label
        case .incomplete(let label): return label
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .complete: return .accentColor
        case .incomplete: return .secondary
        }
    }

    public var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            value?
                .font(Font.title.weight(.bold))
            label?
                .font(Font.caption.weight(.medium))
        }
        .foregroundColor(foregroundColor)
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
        VStack(spacing: 16) {
            LabeledValueTaskView(title: Text("Heart Rate"), detail: Text("Anytime"),
                                 state: .complete(Text("60"), Text("BPM")))
            LabeledValueTaskView(title: Text("Heart Rate"), detail: Text("Anytime"),
                                 state: .complete(Text("60"), nil))
            LabeledValueTaskView(title: Text("Heart Rate"), detail: Text("Anytime"),
                                 state: .incomplete(Text("NO DATA")))
        }.padding()
    }
}
#endif

#endif

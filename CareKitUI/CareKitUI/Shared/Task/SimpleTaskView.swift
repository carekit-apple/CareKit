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
public struct SimpleTaskView<Header: View, DetailDisclosure: View>: View {

    // MARK: - Properties

    @Environment(\.isCardEnabled) private var isCardEnabled

    private let isHeaderPadded: Bool
    private let isDetailDisclosurePadded: Bool
    private let header: Header
    private let detailDisclosure: DetailDisclosure
    private let action: () -> Void

    public var body: some View {
        CardView {
            Button {
                self.action()
            } label: {
                HStack {
                    VStack { header }
                        .if(isCardEnabled && isHeaderPadded) { $0.padding([.vertical, .leading]) }
                    Spacer()
                    VStack { detailDisclosure }
                        .if(isCardEnabled && isDetailDisclosurePadded) { $0.padding([.vertical, .trailing]) }
                }
            }
            .buttonStyle(NoHighlightStyle())
        }
    }

    // MARK: - Init

    /// Create an instance.
    /// - Parameter action: The action to perform when the view is tapped.
    /// - Parameter header: The header view to inject to the left of the button. The specified content will be stacked vertically.
    /// - Parameter detailDisclosure: The view to inject to the right of the header. The specified content will be stacked vertically.
    public init(action: @escaping () -> Void = {}, @ViewBuilder header: () -> Header, @ViewBuilder detailDisclosure: () -> DetailDisclosure) {
        self.init(isHeaderPadded: false, isDetailDisclosurePadded: false, action: action, header: header, detailDisclosure: detailDisclosure)
    }

    private init(isHeaderPadded: Bool, isDetailDisclosurePadded: Bool,
                 action: @escaping () -> Void = {}, @ViewBuilder header: () -> Header, @ViewBuilder detailDisclosure: () -> DetailDisclosure) {
        self.isHeaderPadded = isHeaderPadded
        self.isDetailDisclosurePadded = isDetailDisclosurePadded
        self.header = header()
        self.detailDisclosure = detailDisclosure()
        self.action = action
    }
}

public extension SimpleTaskView where Header == _SimpleTaskViewHeader {

    /// Create an instance.
    /// - Parameter title: The title text to display in the header.
    /// - Parameter detail: The detail text to display in the header.
    /// - Parameter action: The action to perform when the whole view is tapped.
    /// - Parameter detailDisclosure: The view to inject to the right of the header. The specified content will be stacked vertically.
    init(title: Text, detail: Text? = nil, action: @escaping () -> Void = {}, @ViewBuilder detailDisclosure: () -> DetailDisclosure) {
        self.init(isHeaderPadded: true, isDetailDisclosurePadded: false, action: action, header: {
            _SimpleTaskViewHeader(title: title, detail: detail)
        }, detailDisclosure: detailDisclosure)
    }
}

public extension SimpleTaskView where DetailDisclosure == _SimpleTaskViewDetailDisclosure {

    /// Create an instance.
    /// - Parameter isComplete: True if the circle button is complete.
    /// - Parameter action: The action to perform when the whole view is tapped.
    /// - Parameter header: The header view to inject to the left of the button. The specified content will be stacked vertically.
    init(isComplete: Bool, action: @escaping () -> Void = {}, @ViewBuilder header: () -> Header) {
        self.init(isHeaderPadded: false, isDetailDisclosurePadded: true, action: action, header: header, detailDisclosure: {
            _SimpleTaskViewDetailDisclosure(isComplete: isComplete)
        })
    }
}

public extension SimpleTaskView where Header == _SimpleTaskViewHeader, DetailDisclosure == _SimpleTaskViewDetailDisclosure {

    /// Create an instance.
    /// - Parameter title: The title text to display in the header.
    /// - Parameter detail: The detail text to display in the header.
    /// - Parameter isComplete: True if the circle button is complete.
    /// - Parameter action: The action to perform when the whole view is tapped.
    init(title: Text, detail: Text? = nil, isComplete: Bool, action: @escaping () -> Void = {}) {
        self.init(isHeaderPadded: true, isDetailDisclosurePadded: true, action: action, header: {
            _SimpleTaskViewHeader(title: title, detail: detail)
        }, detailDisclosure: {
            _SimpleTaskViewDetailDisclosure(isComplete: isComplete)
        })
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

/// The default detail disclosure used by a `SimpleTaskView`.
public struct _SimpleTaskViewDetailDisclosure: View {

    @Environment(\.careKitStyle) private var style
    @Environment(\.sizeCategory) private var sizeCategory

    @OSValue<CGFloat>(values: [.watchOS: 6], defaultValue: 16) private var padding

    fileprivate let isComplete: Bool

    public var body: some View {
        CircularCompletionView(isComplete: isComplete) {
            Image(systemName: "checkmark")
                .resizable()
                .padding(padding.scaled())
                .frame(width: style.dimension.buttonHeight2.scaled(), height: style.dimension.buttonHeight2.scaled())
        }
    }
}

#if DEBUG
struct SimpleTaskView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SimpleTaskView(title: Text("Title"), detail: Text("Detail"), isComplete: false, action: {})
            SimpleTaskView(title: Text("Title"), detail: Text("Detail"), isComplete: true, action: {})
        }
        .padding()
    }
}
#endif

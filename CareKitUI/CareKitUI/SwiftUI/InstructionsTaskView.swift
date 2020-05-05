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
public struct InstructionsTaskView<Header: View, Footer: View>: View {

    // MARK: - Properties

    @Environment(\.careKitStyle) private var style

    private let header: Header
    private let footer: Footer
    private let instructions: Text?

    public var body: some View {
        CardView {
            VStack {
                header
            }
            Divider()
            instructions?
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(nil)
            VStack {
                footer
            }
        }
    }

    // MARK: - Init

    /// Create an instance.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    /// - Parameter footer: View to inject under the instructions. Specified content will be stacked vertically.
    public init(instructions: Text?, @ViewBuilder header: () -> Header, @ViewBuilder footer: () -> Footer) {
        self.instructions = instructions
        self.header = header()
        self.footer = footer()
    }
}

public extension InstructionsTaskView where Header == HeaderView {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter footer: View to inject under the instructions. Specified content will be stacked vertically.
    init(title: Text, detail: Text?, instructions: Text?, @ViewBuilder footer: () -> Footer) {
        self.init(instructions: instructions, header: {
            Header(title: title, detail: detail)
        }, footer: footer)
    }
}

public extension InstructionsTaskView where Footer == _InstructionsTaskViewFooter {

    /// Create an instance.
    /// - Parameter isComplete: True if the button under the instructions is in the completed.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter action: Action to perform when the button is tapped.
    /// - Parameter header: Header to inject at the top of the card. Specified content will be stacked vertically.
    init(isComplete: Bool, instructions: Text?, action: (() -> Void)?, @ViewBuilder header: () -> Header) {
        self.init(instructions: instructions, header: header, footer: {
            _InstructionsTaskViewFooter(isComplete: isComplete, action: action)
        })
    }
}

public extension InstructionsTaskView where Header == HeaderView, Footer == _InstructionsTaskViewFooter {

    /// Create an instance.
    /// - Parameter title: Title text to display in the header.
    /// - Parameter detail: Detail text to display in the header.
    /// - Parameter instructions: Instructions text to display under the header.
    /// - Parameter isComplete: True if the button under the instructions is in the completed state.
    /// - Parameter action: Action to perform when the button is tapped.
    init(title: Text, detail: Text?, instructions: Text?, isComplete: Bool, action: (() -> Void)?) {
        self.init(instructions: instructions, header: {
            Header(title: title, detail: detail)
        }, footer: {
            _InstructionsTaskViewFooter(isComplete: isComplete, action: action)
        })
    }
}

/// The default footer used by an `InstructionsTaskView`.
public struct _InstructionsTaskViewFooter: View {

    @Environment(\.careKitStyle) private var style

    private var text: String {
        isComplete ? loc("COMPLETED") : loc("MARK_COMPLETE")
    }

    fileprivate let isComplete: Bool
    fileprivate let action: (() -> Void)?

    public var body: some View {
        Button(action: action ?? {}) {
            RectangularCompletionView(isComplete: isComplete) {
                HStack {
                    Spacer()
                    Text(text)
                    Spacer()
                }
            }
        }.buttonStyle(NoHighlightStyle())
    }
}

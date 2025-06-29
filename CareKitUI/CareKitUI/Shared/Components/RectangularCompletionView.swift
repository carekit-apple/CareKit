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

/// A view that denotes a completion state. The style of the view differs based on the completion state.
///
///  # Style
/// The view supports styling using `careKitStyle(_:)`.
///
/// ```
///     +----------------------+
///     |      <Content>       |
///     +----------------------+
/// ```
public struct RectangularCompletionView<Content: View>: View {

    @Environment(\.careKitStyle) private var style

    private var backgroundColor: Color {
        isComplete ? .init(style.color.tertiaryCustomFill) : .accentColor
    }

    private var foregroundColor: Color {
        isComplete ? .accentColor : .white
    }

    private let content: Content
    private let isComplete: Bool

    public var body: some View {
        VStack {
            content
        }
        .foregroundColor(foregroundColor)
        .background(backgroundColor)
        // Use a clip shape with a continuous rectangle over `.cornerRadius` to create a squircle
        .clipShape(
            RoundedRectangle(cornerRadius: style.appearance.cornerRadius2, style: .continuous)
        )
        .font(Font.subheadline.weight(.medium))
    }

    /// Create an instance.
    /// - Parameters:
    ///   - isComplete: The completion state that affects the style of the view.
    ///   - content: The content of the view. The content will be vertically stacked.
    public init(isComplete: Bool, @ViewBuilder content: () -> Content) {
        self.isComplete = isComplete
        self.content = content()
    }
}

#if DEBUG
struct RectangularCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {

                RectangularCompletionView(isComplete: true) {
                    HStack {
                        Spacer()
                        Text("Mark as Complete")
                        Spacer()
                    }.padding()
                }

                RectangularCompletionView(isComplete: false) {
                    Image(systemName: "checkmark")
                        .padding()
                }
            }.padding()
        }
    }
}
#endif

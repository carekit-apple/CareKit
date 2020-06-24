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

import Foundation
import SwiftUI

/// A view that denotes a completion state. The style of the view differs based on the completion state. The circle will encompass the frame
/// of the provided `content`. To ensure the content is contained within the circle, make sure the content has a square frame.
///
///  # Style
/// The view supports styling using `careKitStyle(_:)`.
///
/// ```
///       *   *   *
///    *             *
///       <Content>
///    *             *
///       *   *   *
/// ```
public struct CircularCompletionView<Content: View>: View {

    @Environment(\.careKitStyle) private var style

    private var fillColor: Color {
        isComplete ? Color.accentColor : Color(style.color.clear)
    }

    private var background: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(self.fillColor)
                Circle().strokeBorder(Color.accentColor, lineWidth: self.lineWidth(for: geo.size))
            }
            .inverseMask(self.content)
        }
    }

    private let content: Content
    private let isComplete: Bool

    public var body: some View {
        VStack {
            // The content helps determine the frame, but it does not need to be visible because it will be cut into the circle using an
            // `inverseMask`.
            content.hidden()
        }
        .clipShape(Circle())
        .background(background)
        .font(Font.body.weight(.bold))
    }

    /// Create an instance.
    /// - Parameters:
    ///   - isComplete: The completion state that affects the style of the view.
    ///   - content: The content of the view. The content will be vertically stacked.
    public init(isComplete: Bool, @ViewBuilder content: () -> Content) {
        self.isComplete = isComplete
        self.content = content()
    }

    // Scaled line width for the current frame size.
    private func lineWidth(for containerSize: CGSize) -> CGFloat {
        let border = style.appearance.borderWidth2...style.appearance.borderWidth1
        let dimension = style.dimension.buttonHeight4...style.dimension.buttonHeight1
        let currentDimension = min(containerSize.width, containerSize.height)

        // Get the distance factor between the two dimension values.
        let factor = currentDimension.interpolationFactor(for: dimension)

        // Flip the factor because we want a higher border width for a smaller dimension.
        return border.lowerBound.interpolated(to: border.upperBound, factor: 1 - factor)
    }
}

#if DEBUG
struct CircularCompletionViewPreviews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {

                CircularCompletionView(isComplete: true) {
                    Text("Complete")
                        .padding()
                        .frame(height: 90)
                }

                CircularCompletionView(isComplete: true) {
                    Text("")
                        .frame(width: 30, height: 30)
                }

                CircularCompletionView(isComplete: false) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .padding()
                        .frame(width: 40, height: 40)
                }

                CircularCompletionView(isComplete: false) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .padding()
                        .frame(width: 30, height: 30)
                }

                CircularCompletionView(isComplete: false) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .padding()
                        .frame(width: 20, height: 20)
                }
            }
        }
    }
}
#endif

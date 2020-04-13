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

import SwiftUI

/// A card whose content can be injected.
///
/// # Style
/// The card supports styling using `careKitStyle(_:)`.
///
/// # Composing Cards
/// To combine SwiftUI views with CareKit views that are already inside of a `CardView`, wrap the views in a new `CardView`. A CareKit view inside of
/// a `CardView` is rendered without its border and background, since it inherits those visual affordances from the surrounding `CardView`.
///
/// ```
/// CardView {
///     CardView {
///         Text("Only the outer card's visual features are rendered.")
///     }
/// }
/// ```
public struct CardView<Content: View>: View {

    // MARK: - Properties

    @Environment(\.careKitStyle) private var style
    @Environment(\.cardEnabled) private var cardEnabled

    private var stackedContent: some View {
        VStack(alignment: .leading, spacing: style.dimension.directionalInsets1.top) {
            content
        }
    }

    private let content: Content

    public var body: some View {
        cardEnabled ?
            ViewBuilder.buildEither(first: stackedContent.modifier(CardModifier(style: self.style))) :
            ViewBuilder.buildEither(second: stackedContent)
    }

    // MARK: - Init

    /// Create a card with injected content.
    /// - Parameter content: Content view injected into the card.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}

private struct CardModifier: ViewModifier {

    let style: OCKStyler

    func body(content: Content) -> some View {
        content
            .padding()
            .background(GeometryReader { geometry in
                RoundedRectangle(cornerRadius: self.style.appearance.cornerRadius2, style: .continuous)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .foregroundColor(Color(self.style.color.secondaryCustomGroupedBackground))
                    .shadow(color: Color(hue: 0, saturation: 0, brightness: 0, opacity: Double(self.style.appearance.shadowOpacity1)),
                            radius: self.style.appearance.shadowRadius1,
                            x: self.style.appearance.shadowOffset1.width,
                            y: self.style.appearance.shadowOffset1.height)
            }).cardEnabled(false)
    }
}

// MARK: - Environment

private struct CardEnabledEnvironmentKey: EnvironmentKey {
    static var defaultValue = true
}

private extension EnvironmentValues {
    var cardEnabled: Bool {
        get { self[CardEnabledEnvironmentKey.self] }
        set { self[CardEnabledEnvironmentKey.self] = newValue }
    }
}

private extension View {
    func cardEnabled(_ enabled: Bool) -> some View {
        return self.environment(\.cardEnabled, enabled)
    }
}

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

    @Environment(\.isCardEnabled) private var isCardEnabled

    private var stackedContent: some View {
        VStack { content }
    }

    private let content: Content

    @ViewBuilder public var body: some View {
        if isCardEnabled {
            stackedContent
                .modifier(CardModifier())
        } else {
            stackedContent
        }
    }

    // MARK: - Init

    /// Create a card with injected content.
    /// - Parameter content: Content view injected into the card.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
}

private struct CardModifier: ViewModifier {

    @Environment(\.careKitStyle) private var style

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: style.appearance.cornerRadius2, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .clipShape(cardShape)
            .background(
                cardShape
                    .foregroundColor(Color(style.color.secondaryCustomGroupedBackground))
                    .shadow(color: Color(hue: 0, saturation: 0, brightness: 0, opacity: Double(style.appearance.shadowOpacity1)),
                            radius: style.appearance.shadowRadius1,
                            x: style.appearance.shadowOffset1.width,
                            y: style.appearance.shadowOffset1.height)
            ).cardEnabled(false)
    }
}

// MARK: - Environment

private struct CardEnabledEnvironmentKey: EnvironmentKey {
    static var defaultValue = true
}

extension EnvironmentValues {
    var isCardEnabled: Bool {
        get { self[CardEnabledEnvironmentKey.self] }
        set { self[CardEnabledEnvironmentKey.self] = newValue }
    }
}

extension View {
    func cardEnabled(_ enabled: Bool) -> some View {
        return self.environment(\.isCardEnabled, enabled)
    }
}

#if DEBUG
struct CardView_Previews: PreviewProvider {

    private static var content: some View {
        VStack(alignment: .leading) {
            Text("Title")
            Text("Detail")
        }
    }

    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    content.padding()
                }

                CardView {
                    VStack(alignment: .leading, spacing: 0) {
                        CardView {
                            content.padding()
                        }
                        Rectangle()
                            .fill(Color(white: 0.975))
                            .frame(height: 44)
                    }
                }
            }.padding()
        }
    }
}
#endif

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

/// A card that displays multiple link buttons. Links buttons are capable of showing content in or out of app. Link buttons can be
/// configured using a `Link`.
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
///     |  | <Link Title>                           <Image>  |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     |  +-------------------------------------------------+  |
///     |  | <Link Title>                           <Image>  |  |
///     |  +-------------------------------------------------+  |
///     |                                                       |
///     +-------------------------------------------------------+
/// ```
public struct LinkView<Header: View>: View {

    @Environment(\.careKitStyle)
    private var style

    @Environment(\.isCardEnabled)
    private var isCardEnabled

    private let header: Header
    private let instructions: Text?
    private let links: [LinkItem]

    @ViewBuilder
    private var linkButtons: some View {
        if !links.isEmpty {
            VStack {
                ForEach(links, id: \.hashValue) {
                    LinkButton(link: $0)
                        // Allows multiline text to wrap to the next line
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    public var body: some View {
        CardView {
            VStack(
                alignment: .leading,
                spacing: style.dimension.directionalInsets1.top
            ) {
                VStack { header }
                instructions?
                    .font(.subheadline)
                    .fontWeight(.medium)
                    // Allows multiline text to wrap to the next line
                    .fixedSize(horizontal: false, vertical: true)
                linkButtons
            }
            .padding(isCardEnabled ? [.all] : [])
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    /// Create an instance.
    /// - Parameters:
    ///   - instructions: Longer text displayed in the content of the view.
    ///   - links: Configurations for each link button.
    ///   - header: Injected at the top of the view.
    public init(
        instructions: Text? = nil,
        links: [LinkItem],
        @ViewBuilder header: () -> Header
    ) {
        self.instructions = instructions
        self.links = links
        self.header = header()
    }
}

public extension LinkView where Header == _LinkViewHeader {

    /// Create an instance.
    /// - Parameters:
    ///   - title: Title to display in the header.
    ///   - detail: Detail to display in the header.
    ///   - instructions: Longer text displayed in the content of the view.
    ///   - links: Configurations for each link button.
    init(
        title: Text,
        detail: Text? = nil,
        instructions: Text? = nil,
        links: [LinkItem]
    ) {
        self.instructions = instructions
        self.links = links
        self.header = _LinkViewHeader(
            title: title,
            detail: detail,
            showsDivider: instructions != nil || !links.isEmpty
        )
    }
}

/// Default header used by a `LinkView`.
public struct _LinkViewHeader: View {

    @Environment(\.careKitStyle)
    private var style

    fileprivate let title: Text
    fileprivate let detail: Text?
    fileprivate let showsDivider: Bool

    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: style.dimension.directionalInsets1.top
        ) {
            HeaderView(title: title, detail: detail)
            if showsDivider {
                Divider()
            }
        }
    }
}

#if DEBUG
struct LinkViewPreview: PreviewProvider {

    static var links: [LinkItem] = [
        .call(phoneNumber: "", title: "Call"),
        .email(recipient: "", title: "Email"),
        .appStore(id: "", title: "App Store"),
        .location("", "", title: "Location"),
        .website("some-url", title: "Website"),
        .url(URL(string: "some-url")!, title: "Custom", symbol: "pencil.circle.fill")
    ]

    static var previews: some View {
        ScrollView {
            VStack {

                // Default
                LinkView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    links: links
                )

                // Invalid website
                LinkView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    links: [.website("", title: "Website")]
                )

                // Empty links
                LinkView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    links: []
                )

                // Empty instructions
                LinkView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    links: [links.first!]
                )

                // Empty fields
                LinkView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    links: []
                )

                // Custom Header
                LinkView(
                    instructions: .loremIpsum,
                    links: [links.first!]
                ) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor)
                            .frame(width: 4)
                        Text("Custom Header").font(.headline)
                    }
                }

                // Large AX size
                LinkView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    links: links
                )
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

                // Dark mode
                LinkView(
                    title: Text("Title"),
                    detail: Text("Detail"),
                    instructions: .loremIpsum,
                    links: links
                )
                .environment(\.colorScheme, .dark)
            }
            .padding()
        }
    }
}
#endif

#endif

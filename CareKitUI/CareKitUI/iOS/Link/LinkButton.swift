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

import Combine
import Foundation
import SwiftUI

/// Button capable of showing content in or out of app. Link buttons can be configured using a `Link`.
///
/// This is the default button used by a `_LinkViewFooter`.
///
/// ```
///       +-------------------------------------------------+
///       | <Title>                                <Image>  |
///       +-------------------------------------------------+
/// ```
@available(iOS 14, *)
struct LinkButton<Label: View>: View {

    @State private var isInAppContentPresented = false

    private let usesDefaultPadding: Bool
    private let label: Label
    private let link: LinkItem

    private init(link: LinkItem, usesDefaultPadding: Bool, @ViewBuilder label: () -> Label) {
        self.usesDefaultPadding = usesDefaultPadding
        self.link = link
        self.label = label()
    }

    /// Create an instance.
    /// - Parameters:
    ///   - link: Configuration for the button.
    ///   - label: Label to display in the button.
    init(link: LinkItem, @ViewBuilder label: () -> Label) {
        self.init(link: link, usesDefaultPadding: false, label: label)
    }

    @ViewBuilder var body: some View {

        // If presenting the destination in-app, create a custom button
        if let url = link.url, !link.presentsInApp {
            Link(destination: url) {
                styled(label: label)
            }

        // Else default to the SwiftUI.Link functionality that opens a destination.
        } else {
            Button {
                isInAppContentPresented = true
            } label: {
                styled(label: label)
            }
            // Present a sheet that displays the in-app content for the URL.
            .sheet(isPresented: $isInAppContentPresented) {
                InAppContent(link: link)
            }
            // An invalid link URL will result in a disabled button.
            .disabled(link.url == nil)
        }
    }

    private func styled<Label: View>(label: Label) -> some View {
        RectangularCompletionView(isComplete: true) {
            label
                .if(usesDefaultPadding) { $0.padding() }
        }
    }
}

@available(iOS 14, *)
extension LinkButton where Label == LinkLabel {

    /// Create an instance.
    /// - Parameters:
    ///   - link: Configuration for the button.
    ///   - title: Title to display in the button' label.
    ///   - image: Image to display in the button's label.
    init(link: LinkItem) {
        self.init(link: link, usesDefaultPadding: true, label: {
            LinkLabel(title: Text(link.title), image: Image(systemName: link.symbol))
        })
    }
}

/// The in-app content for a particular link.
private struct InAppContent: View {

    let link: LinkItem

    @ViewBuilder var body: some View {
        if let url = link.url {
            switch link {
            case .website:
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.bottom)
            default:
                fatalError("Link type does not support in-app content")
            }
        }
    }
}

#endif

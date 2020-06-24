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

import CareKit
import CareKitStore
import CareKitUI
import Contacts
import Foundation
import SwiftUI

struct MiscellaneousSection: View {

    var body: some View {
        Section(header: Text("Miscellaneous")) {
            ForEach(MiscellaneousStyle.allCases, id: \.rawValue) { style in
                if style.supportsSwiftUI || style.supportsUIKit {
                    NavigationLink(style.rawValue.capitalized, destination: MiscellaneousDestination(style: style))
                }
            }
        }
    }
}

private struct MiscellaneousDestination: View {

    @Environment(\.storeManager) private var storeManager

    let style: MiscellaneousStyle

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)

            if style.supportsSwiftUI && style.supportsUIKit {
                PlatformPicker {
                    AdaptedMiscellaneousView(style: style)
                } swiftUIView: {
                    if #available(iOS 14, *) {
                        MiscellaneousView(style: style)
                    }
                }
            } else if style.supportsUIKit {
                AdaptedMiscellaneousView(style: style)
            } else if style.supportsSwiftUI, #available(iOS 14, *) {
                MiscellaneousView(style: style)
            }
        }
        .navigationBarTitle(Text(style.rawValue.capitalized), displayMode: .inline)
    }
}

private enum MiscellaneousStyle: String, CaseIterable {

    case link, featuredContent = "featured content"

    var supportsSwiftUI: Bool {
        switch self {
        case .link: return true
        case .featuredContent: return false
        }
    }

    var supportsUIKit: Bool {
        switch self {
        case .featuredContent: return true
        case .link: return false
        }
    }
}

@available(iOS 14, *)
private struct MiscellaneousView: View {

    var links: [CareKitUI.LinkItem] {
        [
            .website("https://www.apple.com", title: "Apple"),
            .call(phoneNumber: "2135558479", title: "Call"),
            .message(phoneNumber: "2135558479", title: "Message"),
            .email(recipient: "lexitorres@icloud.com", title: "Email"),
            .appStore(id: "0", title: "App Store"),
            .location("37.331686", "-122.030656", title: "Address")
        ]
    }

    let style: MiscellaneousStyle

    var body: some View {
        CardBackground {
            switch style {
            case .link:
                LinkView(title: Text("Links"), links: links)
            default:
                EmptyView()
            }
        }
    }
}

private struct AdaptedMiscellaneousView: UIViewControllerRepresentable {

    let style: MiscellaneousStyle

    func makeUIViewController(context: Context) -> UIViewController {
        let listViewController = OCKListViewController()

        let spacer = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 32)))
        listViewController.appendView(spacer, animated: false)

        let viewController: UIViewController?
        switch style {
        case .featuredContent:
            let featuredContentViewController = FeaturedContentViewController()
            featuredContentViewController.featuredContentView.imageView.image = UIImage(systemName: "heart.fill")
            viewController = featuredContentViewController
        case .link:
            viewController = nil
        }

        viewController.map { listViewController.appendViewController($0, animated: false) }
        return listViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

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
import Foundation
import SwiftUI

struct ContactSection: View {

    var body: some View {
        Section(header: Text("Contact")) {
            ForEach(ContactStyle.allCases, id: \.rawValue) { style in
                NavigationLink(style.rawValue.capitalized, destination: ContactDestination(style: style))
            }
        }
    }
}

private struct ContactDestination: View {

    @Environment(\.storeManager) private var storeManager

    let style: ContactStyle

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            AdaptedTaskView(style: style, storeManager: storeManager)
        }
        .navigationBarTitle(Text(style.rawValue.capitalized), displayMode: .inline)
    }
}

private enum ContactStyle: String, CaseIterable {
    case simple, detailed
}

private struct AdaptedTaskView: UIViewControllerRepresentable {

    let style: ContactStyle
    let storeManager: OCKSynchronizedStoreManager

    func makeUIViewController(context: Context) -> UIViewController {
        let listViewController = OCKListViewController()

        let spacer = UIView(frame: .init(origin: .zero, size: .init(width: 0, height: 32)))
        listViewController.appendView(spacer, animated: false)

        let viewController: UIViewController?
        switch style {
        case .simple:
            viewController = OCKSimpleContactViewController(contactID: OCKStore.Contacts.matthew.rawValue, storeManager: storeManager)
        case .detailed:
            viewController = OCKDetailedContactViewController(contactID: OCKStore.Contacts.matthew.rawValue, storeManager: storeManager)
        }

        viewController.map { listViewController.appendViewController($0, animated: false) }
        return listViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

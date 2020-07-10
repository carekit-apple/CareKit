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

struct HigherOrderSection: View {

    var body: some View {
        Section(header: Text("Higher Order")) {
            ForEach(HigherOrderStyle.allCases, id: \.rawValue) { style in
                NavigationLink(style.rawValue.capitalized, destination: HigherOrderDestination(style: style))
            }
        }
    }
}

private struct HigherOrderDestination: View {

    @Environment(\.storeManager) private var storeManager

    let style: HigherOrderStyle

    var body: some View {
        AdaptedHigherOrderView(style: style, storeManager: storeManager)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text(style.rawValue.capitalized), displayMode: .inline)
    }
}

private enum HigherOrderStyle: String, CaseIterable {
    case tasks, contacts
}

private struct AdaptedHigherOrderView: UIViewControllerRepresentable {

    let style: HigherOrderStyle
    let storeManager: OCKSynchronizedStoreManager

    func makeUIViewController(context: Context) -> UIViewController {
        switch style {
        case .tasks:
            return OCKDailyTasksPageViewController(storeManager: storeManager)
        case .contacts:
            return OCKContactsListViewController(storeManager: storeManager)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

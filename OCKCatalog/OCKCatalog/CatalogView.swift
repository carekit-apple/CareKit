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
import HealthKit
import SwiftUI

struct CatalogView: View {

    @State private var didRequestHealthKitAccess = false
    @State private var isHealthKitAvailable = false

    @ViewBuilder var body: some View {

        // Placeholder background while requesting HealthKit permissions
        if !UIApplication.isRunningTest && !didRequestHealthKitAccess {
            Color(UIColor.secondarySystemGroupedBackground)
                .onAppear {
                    requestHealthKitAccess { success, error in
                        if !success { print(["[ERROR]", error!.localizedDescription].joined()) }
                        didRequestHealthKitAccess = true
                        isHealthKitAvailable = success
                    }
                }

        // HealthKit is not available - show placeholder text
        } else if !UIApplication.isRunningTest && !isHealthKitAvailable {
            Text("Please enable HealthKit access in Settings")
                .font(Font(UIFont.preferredFont(forTextStyle: .title3)))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

        // HealthKit is available - show the main view
        } else {
            NavigationView {
                List {
                    TaskSection()
                    ContactSection()
                    ChartSection()
                    MiscellaneousSection()
                    HigherOrderSection()
                }
                .listStyle(GroupedListStyle())
                .navigationBarTitle(Text("CareKit Catalog"), displayMode: .inline)
            }
        }
    }

    func requestHealthKitAccess(completion: @escaping (Bool, Error?) -> Void) {
        let healthStore = HKHealthStore()
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
        healthStore.requestAuthorization(toShare: nil, read: allTypes, completion: completion)
    }
}

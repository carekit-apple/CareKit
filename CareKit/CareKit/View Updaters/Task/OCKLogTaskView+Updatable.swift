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

import CareKitStore
import CareKitUI
import UIKit

extension OCKLogTaskView {

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Update the stack by updating each item, or adding a new one if necessary based on the number of `outcomeValues`.
    func updateItems(withOutcomeValues outcomeValues: [OCKOutcomeValue], animated: Bool) {
        if outcomeValues.isEmpty {
            clearItems(animated: animated)
        } else {
            for (index, outcomeValue) in outcomeValues.enumerated() {
                guard let date = outcomeValue.updatedDate ?? outcomeValue.createdDate else { break }
                let dateString = OCKLogTaskView.timeFormatter.string(from: date).description

                _ = index < items.count ?
                    updateItem(at: index, withTitle: outcomeValue.stringValue, detail: dateString) :
                    appendItem(withTitle: outcomeValue.stringValue, detail: dateString, animated: animated)
            }
        }
        trimItems(given: outcomeValues, animated: animated)
    }

    // Remove any items that aren't needed
    private func trimItems(given outcomeValues: [OCKOutcomeValue], animated: Bool) {
        let countToRemove = items.count - outcomeValues.count
        for _ in 0..<countToRemove {
            removeItem(at: items.count - 1, animated: animated)
        }
    }
}

private extension OCKOutcomeValue {
    var stringValue: String {
        switch type {
        case .boolean: return booleanValue! ? loc("COMPLETED") : loc("INCOMPLETE")
        default: return String(describing: value).capitalized
        }
    }
}

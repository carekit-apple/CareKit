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

import CareKitUI
import Foundation

extension OCKWeekCalendarView: OCKCompletionStatesUpdatable {
    func updateWith(states: [OCKCompletionRingButton.CompletionState], animated: Bool) {
        // clear the view
        guard !states.isEmpty else {
            completionRingButtons.forEach {
                $0.setState(.dimmed, animated: true)
                $0.accessibilityLabel = nil
                $0.accessibilityValue = nil
            }
            return
        }

        // Else update the ring states
        guard states.count == completionRingButtons.count else {
            fatalError("Number of states and completions rings do not match")
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        completionRingButtons.enumerated().forEach { index, ring in
            let date = Calendar.current.date(byAdding: .day, value: index, to: dateInterval.start)!
            ring.setState(states[index], animated: true)
            ring.accessibilityValue = makeAccessibilityValue(for: states[index])
            ring.accessibilityLabel = dateFormatter.string(from: date)
            ring.accessibilityTraits = ring.isSelected ? [.button, .selected] : [.button]
        }
    }

    private func makeAccessibilityValue(for state: OCKCompletionRingButton.CompletionState) -> String {
        switch state {
        case .dimmed: return loc("NO_TASKS")
        case .empty: return loc("NO_EVENTS")
        case .zero: return "0"
        case .progress(let percent): return "\(Int(percent * 100))%"
        }
    }
}

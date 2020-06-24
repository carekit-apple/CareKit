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

import UIKit

extension Double {
    var normalized: Double {
        return max(0, min(self, 1))
    }
}

extension CGFloat {

    /// Scaled value for the current size category.
    func scaled() -> CGFloat {
        UIFontMetrics.default.scaledValue(for: self)
    }

    /// The value between `self` and `end` with distance of `factor` between 0 and 1.
    func interpolated(to end: CGFloat, factor: CGFloat) -> CGFloat {
        precondition(factor >= 0 && factor <= 1, "Factor should be in range [0, 1]")
        return (self + (factor * (end - self)))
            .clamped(to: (self...end))
    }

    /// Get the interpolation distance factor between 0 and 1 of this value in the given range.
    func interpolationFactor(for range: ClosedRange<CGFloat>) -> CGFloat {
        let denominator = range.upperBound - self
        guard denominator > 0 else { return 1 }
        return ((self - range.lowerBound) / denominator)
            .clamped(to: 0...1)
    }

    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.max(Swift.min(self, range.upperBound), range.lowerBound)
    }
}

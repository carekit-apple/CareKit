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
#if !os(watchOS)

import CareKitStore
import Foundation

extension OCKOutcomeValue {

    // Helps to compare two values that are not of the same type. For example:
    //
    // ```
    //     let intValue = OCKOutcomeValue(Int(1))
    //     let doubleValue = OCKOutcomeValue(Double(2))
    //     let comparisonResult = intValue.value.double == doubleValue.value.double   // compares 1 and 2
    // ```
    //
    // If we instead use the default behavior, we cannot compare values:
    //
    // ```
    //     let intValue = OCKOutcomeValue(Int(1))
    //     let doubleValue = OCKOutcomeValue(Double(2))
    //     let comparison = intValue.doubleValue == doubleValue.doubleValue    // compares `nil` and `2`
    // ```
    //
    // If the underlying value is an integer, this is a lossless operation as long as the integer can be converted to a double without loss of
    // accuracy.
    var numberValue: NSNumber? {
        if let value = integerValue { return NSNumber(value: value) }
        if let value = doubleValue { return NSNumber(value: value) }
        if let value = booleanValue { return NSNumber(value: value) }
        if stringValue != nil { return nil }
        if dataValue != nil { return nil }
        if dateValue != nil { return nil }

        assertionFailure("""
        Could not convert value. This can occur if a new type conforms to `OCKUnderlyingValueType` and there was no attempt \
        to cast to that type here.
        """)

        return nil
    }
}

#endif

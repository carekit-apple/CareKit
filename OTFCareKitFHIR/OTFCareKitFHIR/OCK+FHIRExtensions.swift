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

import Foundation
import ModelsDSTU2
import ModelsR4

extension String {
    func fhirString<T: ExpressibleByStringLiteral>() -> T where T.StringLiteralType == String { T(stringLiteral: self) }
}

extension Calendar.Component {
    var dstu2FHIRUnitString: ModelsDSTU2.FHIRPrimitive<ModelsDSTU2.FHIRString> {
        switch self {
        case .second: return "s"
        case .minute: return "min"
        case .hour: return "h"
        case .day: return "d"
        case .weekOfYear: return "wk"
        case .month: return "mo"
        default: fatalError("Calendar component \(self) is not supported by FHIR.")
        }
    }
}

extension Date {
    var dstu2FHIRDateTime: ModelsDSTU2.DateTime {
        let year = Calendar.current.component(.year, from: self)
        let month = Calendar.current.component(.month, from: self)
        let day = Calendar.current.component(.day, from: self)
        let date = ModelsDSTU2.FHIRDate(year: year, month: UInt8(month), day: UInt8(day))

        let hour = Calendar.current.component(.hour, from: self)
        let minute = Calendar.current.component(.minute, from: self)
        let second = Calendar.current.component(.second, from: self)
        let time = ModelsDSTU2.FHIRTime(hour: UInt8(hour), minute: UInt8(minute), second: Decimal(second))

        return DateTime(date: date, time: time, timezone: TimeZone.current)
    }

    var r4FHIRDateTime: ModelsR4.FHIRPrimitive<ModelsR4.DateTime> {
        let year = Calendar.current.component(.year, from: self)
        let month = Calendar.current.component(.month, from: self)
        let day = Calendar.current.component(.day, from: self)
        let date = ModelsR4.FHIRDate(year: year, month: UInt8(month), day: UInt8(day))

        let hour = Calendar.current.component(.hour, from: self)
        let minute = Calendar.current.component(.minute, from: self)
        let second = Calendar.current.component(.second, from: self)
        let time = ModelsR4.FHIRTime(hour: UInt8(hour), minute: UInt8(minute), second: Decimal(second))

        return FHIRPrimitive(DateTime(date: date, time: time, timezone: TimeZone.current))
    }

    var truncatingNanoSeconds: Date {
        let roundedDown = floor(timeIntervalSinceReferenceDate)
        return Date(timeIntervalSinceReferenceDate: roundedDown)
    }
}

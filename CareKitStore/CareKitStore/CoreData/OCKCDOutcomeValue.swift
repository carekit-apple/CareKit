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

@objc(OCKCDOutcomeValue)
class OCKCDOutcomeValue: OCKCDObject {
    @NSManaged var kind: String? // blood sugar, body weight, etc.
    @NSManaged var units: String?
    @NSManaged var index: NSNumber?
    @NSManaged var outcome: OCKCDOutcome?

    @NSManaged private var typeString: String
    var type: OCKOutcomeValueType {
        get { return OCKOutcomeValueType(rawValue: typeString)! }
        set { typeString = newValue.rawValue }
    }

    @NSManaged var textValue: String?
    @NSManaged var binaryValue: Data?
    @NSManaged var booleanValue: Bool
    @NSManaged var integerValue: Int64
    @NSManaged var doubleValue: Double
    @NSManaged var dateValue: Date?

    var value: OCKOutcomeValueUnderlyingType {
        get {
            switch type {
            case .integer: return Int(integerValue)
            case .double: return doubleValue
            case .boolean: return booleanValue
            case .text: return textValue!
            case .binary: return binaryValue!
            case .date: return dateValue!
            }
        }

        set {
            switch newValue {
            case let int as Int:
                reset()
                integerValue = Int64(int)
                type = .integer

            case let double as Double:
                reset()
                doubleValue = double
                type = .double

            case let bool as Bool:
                reset()
                booleanValue = bool
                type = .boolean

            case let text as String:
                reset()
                textValue = text
                type = .text

            case let binary as Data:
                reset()
                binaryValue = binary
                type = .binary

            case let date as Date:
                reset()
                dateValue = date
                type = .date

            default: fatalError("Unexpected type!")
            }
        }
    }

    private func reset() {
        textValue = nil
        binaryValue = nil
        booleanValue = false
        integerValue = 0
        doubleValue = 0
        dateValue = nil
        index = nil
    }
}

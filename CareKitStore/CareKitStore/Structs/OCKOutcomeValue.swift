/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.

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

/// Any value that can be persisted to `OCKStore` must conform to this protocol.
public protocol OCKOutcomeValueUnderlyingType: Codable {}

extension Int: OCKOutcomeValueUnderlyingType {}
extension Double: OCKOutcomeValueUnderlyingType {}
extension Bool: OCKOutcomeValueUnderlyingType {}
extension String: OCKOutcomeValueUnderlyingType {}
extension Data: OCKOutcomeValueUnderlyingType {}
extension Date: OCKOutcomeValueUnderlyingType {}

/// An enumerator specifying the types of values that can be saved to an `OCKStore`.
public enum OCKOutcomeValueType: String, Codable {
    case integer
    case double
    case boolean
    case text
    case binary
    case date
}

/// An `OCKOutcomeValue` is a representation of any response of measurement that a user gives in response to a task. The underlying type could be
/// any of a number of types including integers, booleans, dates, text, and binary data, among others.
public struct OCKOutcomeValue: Codable, Equatable, CustomStringConvertible {

    public static func == (lhs: OCKOutcomeValue, rhs: OCKOutcomeValue) -> Bool {
        lhs.hasSameValueAs(rhs) &&
        lhs.type == rhs.type &&
        lhs.kind == rhs.kind &&
        lhs.units == rhs.units &&
        lhs.createdDate == rhs.createdDate
    }

    /// An optional property that can be used to specify what kind of value this is (e.g. blood pressure, qualitative stress, weight)
    public var kind: String?

    /// The units for this measurement.
    public var units: String?

    /// The date that this value was created.
    public var createdDate = Date()

    /// The underlying value.
    public var value: OCKOutcomeValueUnderlyingType

    /// The underlying value as an integer.
    public var integerValue: Int? { return value as? Int }

    /// The underlying value as a floating point number.
    public var doubleValue: Double? { return value as? Double }

    /// The underlying value as a boolean.
    public var booleanValue: Bool? { return value as? Bool }

    /// The underlying value as text.
    public var stringValue: String? { return value as? String }

    /// The underlying value as binary data.
    public var dataValue: Data? { return value as? Data }

    /// The underlying value as a date.
    public var dateValue: Date? { return value as? Date }

    /// Holds information about the type of this value.
    public var type: OCKOutcomeValueType {
        if value is Int { return .integer }
        if value is Double { return .double }
        if value is Bool { return .boolean }
        if value is String { return .text }
        if value is Data { return .binary }
        if value is Date { return .date }
        fatalError("Unknown type!")
    }

    public var description: String {
        switch type {
        case .integer: return "\(value as! Int)"
        case .double: return "\(value as! Double)"
        case .boolean: return "\(value as! Bool)"
        case .text: return "\(value as! String)"
        case .binary: return "\(value as! Data)"
        case .date: return "\(value as! Date)"
        }
    }

    /// Initialize by specifying a value and an optional unit
    public init(_ value: OCKOutcomeValueUnderlyingType, units: String? = nil) {
        self.value = value
        self.units = units
    }

    /// Checks if two `OCKOutcomeValue`s have equal value properties, without checking their other properties.
    private func hasSameValueAs(_ other: OCKOutcomeValue) -> Bool {
        switch type {
        case .binary: return dataValue == other.dataValue
        case .boolean: return booleanValue == other.booleanValue
        case .date: return dateValue == other.dateValue
        case .double: return doubleValue == other.doubleValue
        case .integer: return integerValue == other.integerValue
        case .text: return stringValue == other.stringValue
        }
    }

    // The value as an `NSNumber`. This property can be useful when comparing outcome values with an underlying
    // type of Bool, Double, or Int against one another.
    public var numberValue: NSNumber? {
        switch type {
        case .boolean: return NSNumber(value: booleanValue!)
        case .double: return NSNumber(value: doubleValue!)
        case .integer: return NSNumber(value: integerValue!)
        default: return nil
        }
    }

    private enum CodingKeys: CodingKey, CaseIterable {
        case kind
        case units
        case value
        case type
        case createdDate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let valueType = try container.decode(OCKOutcomeValueType.self, forKey: .type)

        switch valueType {
        case .integer:
            value = try container.decode(Int.self, forKey: .value)
        case .double:
            value = try container.decode(Double.self, forKey: .value)
        case .boolean:
            value = try container.decode(Bool.self, forKey: .value)
        case .text:
            value = try container.decode(String.self, forKey: .value)
        case .binary:
            value = try container.decode(Data.self, forKey: .value)
        case .date:
            value = try container.decode(Date.self, forKey: .value)
        }

        kind = try container.decodeIfPresent(String.self, forKey: .kind)
        units = try container.decodeIfPresent(String.self, forKey: .units)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(type, forKey: .type)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(kind, forKey: .kind)
        try container.encodeIfPresent(units, forKey: .units)

        var encodedValue = false
        if let value = integerValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = doubleValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = stringValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = booleanValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = dataValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = dateValue { try container.encode(value, forKey: .value); encodedValue = true }

        guard encodedValue else {
            let message = "Value could not be converted to a concrete type."
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [CodingKeys.value], debugDescription: message))
        }
    }
}

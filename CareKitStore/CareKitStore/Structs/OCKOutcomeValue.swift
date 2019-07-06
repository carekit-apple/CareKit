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
public struct OCKOutcomeValue: Codable, Equatable, OCKObjectCompatible, OCKLocalPersistableSettable {

    // MARK: Codable
    enum CodingKeys: CodingKey, CaseIterable {
        case
        kind, units, localDatabaseID, value, type,
        createdAt, updatedAt, deletedAt, tags, group, externalId, userInfo, source   // OCKObjectCompatible
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        kind = try container.decode(String?.self, forKey: CodingKeys.kind)
        units = try container.decode(String?.self, forKey: CodingKeys.units)
        localDatabaseID = try container.decode(OCKLocalVersionID?.self, forKey: CodingKeys.localDatabaseID)
     
        // use the type to tell which valyue type we must decode
        let type = try container.decode(OCKOutcomeValueType.self, forKey: CodingKeys.type)
        var tempValue: OCKOutcomeValueUnderlyingType?
        switch type {
        case .integer:
            tempValue = try? container.decode(Int?.self, forKey: CodingKeys.value)
        case .double:
            tempValue = try? container.decode(Double?.self, forKey: CodingKeys.value)
        case .boolean:
            tempValue = try? container.decode(Bool?.self, forKey: CodingKeys.value)
        case .text:
            tempValue = try? container.decode(String?.self, forKey: CodingKeys.value)
        case .binary:
            tempValue = try? container.decode(Data?.self, forKey: CodingKeys.value)
        case .date:
            tempValue = try? container.decode(Date?.self, forKey: CodingKeys.value)
        }
        
        guard let existingValue = tempValue else {
            let msg = "Value does not match a OCKOutcomeValueCompatible decodable type."
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.value], debugDescription: msg))
        }
        value = existingValue

        createdAt = try container.decode(Date?.self, forKey: CodingKeys.createdAt)
        updatedAt = try container.decode(Date?.self, forKey: CodingKeys.updatedAt)
        deletedAt = try container.decode(Date?.self, forKey: CodingKeys.deletedAt)
        groupIdentifier = try container.decode(String?.self, forKey: CodingKeys.group)
        tags = try container.decode([String]?.self, forKey: CodingKeys.tags)
        externalID = try container.decode(String?.self, forKey: CodingKeys.externalId)
        source = try container.decode(String?.self, forKey: CodingKeys.source)
        userInfo = try container.decode([String: String]?.self, forKey: CodingKeys.userInfo)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(kind, forKey: .kind)
        try container.encode(units, forKey: .units)
        try container.encode(localDatabaseID, forKey: .localDatabaseID)
        
        var encodedValue = false
        if let value = integerValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = doubleValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = stringValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = booleanValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = dataValue { try container.encode(value, forKey: .value); encodedValue = true } else
        if let value = dateValue { try container.encode(value, forKey: .value); encodedValue = true }
        
        guard encodedValue else {
            let msg = "Value could not be converted to a concrete type."
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [CodingKeys.value], debugDescription: msg))
        }
        
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(deletedAt, forKey: .deletedAt)
        try container.encode(groupIdentifier, forKey: .group)
        try container.encode(tags, forKey: .tags)
        try container.encode(externalID, forKey: .externalId)
        try container.encode(source, forKey: .source)
        try container.encode(userInfo, forKey: .userInfo)
    }
    
    /// An optional property that can be used to specify what kind of value this is (e.g. blood pressure, qualatative stress, weight)
    public var kind: String?
    
    /// The units for this measurement.
    public var units: String?
    
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
    
    // MARK: OCKObjectCompatible
    public internal(set) var localDatabaseID: OCKLocalVersionID?
    public internal(set) var createdAt: Date?
    public internal(set) var updatedAt: Date?
    public internal(set) var deletedAt: Date?
    public var groupIdentifier: String?
    public var tags: [String]?
    public var externalID: String?
    public var source: String?
    public var userInfo: [String: String]?
    public var asset: String?
    public var notes: [OCKNote]?
    
    public var type: OCKOutcomeValueType {
        if value is Int { return .integer }
        if value is Double { return .double }
        if value is Bool { return .boolean }
        if value is String { return .text }
        if value is Data { return .binary }
        if value is Date { return .date }
        fatalError("Unknown type!")
    }
    
    public init(_ value: OCKOutcomeValueUnderlyingType, units: String? = nil) {
        self.value = value
        self.units = units
    }

    public static func == (lhs: OCKOutcomeValue, rhs: OCKOutcomeValue) -> Bool {
        return lhs.localDatabaseID == rhs.localDatabaseID &&
            lhs.externalID == rhs.externalID &&
            lhs.userInfo == rhs.userInfo &&
            lhs.integerValue == rhs.integerValue &&
            lhs.doubleValue == rhs.doubleValue &&
            lhs.booleanValue == rhs.booleanValue &&
            lhs.stringValue == rhs.stringValue &&
            lhs.dataValue == rhs.dataValue &&
            lhs.dateValue == rhs.dateValue &&
            lhs.asset == rhs.asset &&
            lhs.kind == rhs.kind
    }
}

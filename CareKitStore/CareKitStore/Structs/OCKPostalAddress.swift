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
import Contacts

/// A `Codable` subclass of `CNMutablePostalAddress`.
@objc // We subclass for sole purpose of adding conformance to Codable.
public class OCKPostalAddress: CNMutablePostalAddress, Codable {
    
    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: Keys.self)
        self.street = try container.decode(String.self, forKey: .street)
        self.subLocality = try container.decode(String.self, forKey: .subLocality)
        self.city = try container.decode(String.self, forKey: .city)
        self.subAdministrativeArea = try container.decode(String.self, forKey: .subAdministrativeArea)
        self.state = try container.decode(String.self, forKey: .state)
        self.postalCode = try container.decode(String.self, forKey: .postalCode)
        self.country = try container.decode(String.self, forKey: .country)
        self.isoCountryCode = try container.decode(String.self, forKey: .isoCountryCode)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(street, forKey: .street)
        try container.encode(subLocality, forKey: .subLocality)
        try container.encode(city, forKey: .city)
        try container.encode(subAdministrativeArea, forKey: .subAdministrativeArea)
        try container.encode(state, forKey: .state)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encode(country, forKey: .country)
        try container.encode(isoCountryCode, forKey: .isoCountryCode)
    }
    
    public override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private enum Keys: CodingKey, CaseIterable {
        case street
        case subLocality
        case city
        case subAdministrativeArea
        case state
        case postalCode
        case country
        case isoCountryCode
    }
}

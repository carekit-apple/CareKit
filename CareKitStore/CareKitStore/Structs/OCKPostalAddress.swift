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

import Contacts
import Foundation

/// A representation of the postal address for a contact.
public struct OCKPostalAddress: Hashable, Codable, Sendable {

    /// The street name of the address.
    public var street: String

    /// The city name of the address.
    public var city: String

    /// The state name of the address.
    public var state: String

    /// The postal code of the address.
    public var postalCode: String

    /// The country or region name of the address.
    public var country: String

    /// The ISO country code, using the ISO 3166-1 alpha-2 standard.
    public var isoCountryCode: String

    /// The subadministrative area (such as a county or other region) in a postal address.
    public var subAdministrativeArea: String

    /// Additional information associated with the location, typically defined at the city or town level, in a postal address.
    public var subLocality: String

    /// A representation of the postal address for a contact.
    /// - Parameters:
    ///   - street: The street name of the address.
    ///   - city: The city name of the address.
    ///   - state: The state name of the address.
    ///   - postalCode: The postal code of the address.
    ///   - country: The country or region name of the address.
    ///   - isoCountryCode: The ISO country code, using the ISO 3166-1 alpha-2 standard.
    ///   - subAdministrativeArea: The subadministrative area (such as a county or other region) in a postal address.
    ///   - subLocality: Additional information associated with the location, typically defined at the city or town level, in a postal address.
    public init(
        street: String,
        city: String,
        state: String,
        postalCode: String,
        country: String,
        isoCountryCode: String = "",
        subAdministrativeArea: String = "",
        subLocality: String = ""
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.isoCountryCode = isoCountryCode
        self.subAdministrativeArea = subAdministrativeArea
        self.subLocality = subLocality
    }

    public func cnPostalAddress() -> CNPostalAddress {
        let address = CNMutablePostalAddress()
        address.street = street
        address.city = city
        address.state = state
        address.postalCode = postalCode
        address.country = country
        address.isoCountryCode = isoCountryCode
        address.subAdministrativeArea = subAdministrativeArea
        address.subLocality = subLocality
        return address
    }
}

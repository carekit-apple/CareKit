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
#if !os(watchOS)

import Combine
import Contacts
import Foundation
import MapKit

private struct Schemes {
    static let appStore = "itms://itunes.apple.com/app/id/"
    static let call = "tel:"
    static let email = "mailto:"
    static let message = "sms:"
    static let address = "https://maps.apple.com/"
}

private struct Symbols {
    static let call = "phone.circle.fill"
    static let website = "safari.fill"
    static let email = "envelope.circle.fill"
    static let message = "message.circle.fill"
    static let appStore = "arrow.up.right.circle.fill"
    static let address = "location.circle.fill"
}

/// A link item tied to a button in the `LinkView`.
public enum LinkItem: Hashable {

    /// Link to a generic URL.
    case url(_ url: URL, title: String, symbol: String)

    /// Link to a website. Supports opening in app.
    case website(_ urlString: String, title: String)

    /// Link to open an app in the App Store.
    case appStore(id: String, title: String)

    /// Link to a location in Maps.
    case location(_ latitude: String, _ longitude: String, title: String)

    /// Link to call a phone number.
    case call(phoneNumber: String, title: String)

    /// Link to message a phone number.
    case message(phoneNumber: String, title: String)

    /// Link to email a recipient.
    case email(recipient: String, title: String)

    var alertTitle: String {
        switch self {
        case .url: return loc("OPEN_URL")
        case .website: return loc("OPEN_SAFARI")
        case .location: return loc("OPEN_MAPS")
        case .call: return loc("OPEN_PHONE")
        case .message: return loc("OPEN_MESSAGES")
        case .appStore: return loc("OPEN_APP_STORE")
        case .email: return loc("OPEN_MAIL")
        }
    }

    var title: String {
        switch self {
        case let .url(_, title, _): return title
        case let .website(_, title): return title
        case let .location(_, _, title): return title
        case let .call(_, title): return title
        case let .message(_, title): return title
        case let .appStore(_, title): return title
        case let .email(_, title): return title
        }
    }

    var symbol: String {
        switch self {
        case let .url(_, _, symbol): return symbol
        case .website: return Symbols.website
        case .location: return Symbols.address
        case .call: return Symbols.call
        case .message: return Symbols.message
        case .appStore: return Symbols.appStore
        case .email: return Symbols.email
        }
    }

    var presentsInApp: Bool {
        switch self {
        case .url, .location, .call, .message, .email, .appStore: return false
        case .website: return true
        }
    }

    /// The URL for the current link.
    public var url: URL? {
        switch self {
        case let .url(url, _, _):
            return url
        case let .website(urlString, _):
            return URL(string: urlString)
        case let .location(latitude, longitude, _):
            let query = "?ll=\(latitude),\(longitude)"
            return URL(string: Schemes.address + query)
        case let .call(phoneNumber, _):
            return URL(string: Schemes.call + phoneNumber)
        case let .message(phoneNumber, _):
            return URL(string: Schemes.message + phoneNumber)
        case let .email(recipient, _):
            return URL(string: Schemes.email + recipient)
        case let .appStore(id, _):
            return URL(string: Schemes.appStore + id)
        }
    }
}

#endif

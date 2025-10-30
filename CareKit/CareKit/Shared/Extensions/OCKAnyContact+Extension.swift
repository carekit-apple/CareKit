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

import CareKitStore
import Foundation
import MapKit

private let telephoneURLPath = "tel://"

extension OCKAnyContact {

    func phoneCallURL() -> URL? {
        guard let phoneNumber = phoneNumbers?.first?.value else { return nil }

        let urlString =
            telephoneURLPath +
            phoneNumber.toAlphanumeric()

        return URL(string: urlString)
    }

    func cleanedMessagingNumber() -> String? {
        return messagingNumbers?.first?.value.toAlphanumeric()
    }

    func getAddressMapItem(
        completion: @escaping (MKMapItem?) -> Void
    ) {
        guard let address = address else {
            completion(nil)
            return
        }

        // Generate the map item that pinpoints the contact's address
        let geoloc = CLGeocoder()
        geoloc.geocodePostalAddress(address.cnPostalAddress()) { placemarks, error in

            if let error {
                log(.error, "Failed to geocode postal address", error: error)
                completion(nil)
                return
            }

            guard let placemark = placemarks?.first else {
                log(.error, "No placemarks found for geocoding request")
                completion(nil)
                return
            }

            let mkPlacemark = MKPlacemark(placemark: placemark)
            completion(MKMapItem(placemark: mkPlacemark))
        }
    }
}

private extension String {

    func toAlphanumeric() -> String {
        return filter { $0.isNumber }
    }
}

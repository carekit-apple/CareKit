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

import Foundation

/// Marks binary data with an explicit FHIR release and content type.
public struct OCKFHIRResourceData<Release: OCKFHIRRelease, Content: FHIRContentType>: OCKFHIRResource {

    /// The raw FHIR resource data.
    public let data: Data

    /// Initialize `OCKFHIRResourceData` by specifying the raw data, it's release, and content type.
    /// 
    /// - Parameter data: Binary data representing a FHIR resource.
    public init(data: Data) {
        self.data = data
    }

    /// Initialize `OCKFHIRResourceData` by specifying the raw data, it's release, and content type.
    ///
    /// - Parameter release: The release of the FHIR specification used.
    /// - Parameter content: The encoding of the resource content.
    /// - Parameter data: Binary data representing a FHIR resource.
    public init(release: Release.Type, content: Content.Type, data: Data) {
        self.data = data
    }
}

public extension OCKFHIRResourceData where Content == JSON {

    /// Initialize a JSON `OCKFHIRResourceData` by specifying the raw data and release.
    ///
    /// - Parameter release: The release of the FHIR specification used.
    /// - Parameter data: Binary data representing a FHIR resource.
    init(release: Release.Type, data: Data) {
        self.data = data
    }
}

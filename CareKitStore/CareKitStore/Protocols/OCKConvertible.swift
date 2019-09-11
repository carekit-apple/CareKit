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

/// Any value or object that can be used in place of CareKit native values must conform to this protocol.
public protocol OCKConvertible {
    /// The CareKit type that this type can be converted to.
    associatedtype ConversionResult

    /// Converts this type to a new CareKit value.
    func convert() -> ConversionResult
    init(_ value: ConversionResult)
}

public extension OCKConvertible where ConversionResult: OCKVersionable {
    var identifier: String { return convert().identifier }
    var nextVersionID: OCKLocalVersionID? { return convert().nextVersionID }
    var previousVersionID: OCKLocalVersionID? { return convert().previousVersionID }
}

public extension OCKConvertible where ConversionResult: OCKLocalPersistable {
    var localDatabaseID: OCKLocalVersionID? { return convert().localDatabaseID }
}

/// Conforming to this protocol indicates that the conforming object or value can be converted to an `OCKPatient`
public protocol OCKPatientConvertible: OCKVersionable, OCKConvertible where ConversionResult == OCKPatient {}

/// Conforming to this protocol indicates that the conforming object or value can be converted to an `OCKCarePlan`
public protocol OCKCarePlanConvertible: OCKVersionable, OCKConvertible where ConversionResult == OCKCarePlan {}

/// Conforming to this protocol indicates that the conforming object or value can be converted to an `OCKContact`
public protocol OCKContactConvertible: OCKVersionable, OCKConvertible where ConversionResult == OCKContact {}

/// Conforming to this protocol indicates that the conforming object or value can be converted to an `OCKTask`
public protocol OCKTaskConvertible: OCKVersionable, OCKConvertible where ConversionResult == OCKTask {}

/// Conforming to this protocol indicates that the conforming object or value can be converted to an `OCKEvent`
public protocol OCKEventConvertible: OCKConvertible where ConversionResult == OCKEvent<OCKTask, OCKOutcome> {}

/// Conforming to this protocol indicates that the conforming object or value can be converted to an `OCKOutcome`
public protocol OCKOutcomeConvertible: OCKLocalPersistable, OCKConvertible where ConversionResult == OCKOutcome {}

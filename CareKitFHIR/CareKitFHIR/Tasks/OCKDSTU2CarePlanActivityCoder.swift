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
import CareKitStore
import Foundation
import ModelsDSTU2

extension ModelsDSTU2.CarePlanActivity: OCKFHIRResource {
    public typealias Release = DSTU2
}

/// Converts a FHIR DSTU2 `CarePlanActivity` to an `OCKTask`.
///
/// The mapping is predefined to use reasonable defaults, but it is possible to configure
/// the behavior by setting properties on `OCKDSTU2CarePlanActivityCoder`.
public struct OCKDSTU2CarePlanActivityCoder: OCKTaskConverterTraits {

    public typealias Resource = ModelsDSTU2.CarePlanActivity
    public typealias Entity = OCKTask

    // MARK: FHIR CarePlanActivity to OCKTask

    public var getCareKitID: (Resource) throws -> String = { activity in
        guard let id = activity.id?.value?.string else {
            throw OCKFHIRCodingError.missingRequiredField("id")
        }
        return id
    }

    public var getCareKitSchedule: (Resource) throws -> OCKSchedule = { activity in

        // There could be any of 3 kinds of schedules: Timing, Period, String.
        // For now we're only considering the Timing case.
        guard case let .timing(timing) = activity.detail?.scheduled else {
            throw OCKFHIRCodingError.missingRequiredField("schedule")
        }

        return try OCKDSTU2ScheduleCoder().convert(resource: timing)
    }

    public var getCareKitTitle: (Resource) throws -> String? = { activity in
        activity.detail?.description_fhir?.value?.string
    }

    public var getCareKitInstructions: (CarePlanActivity) throws -> String? = { activity in
        nil
    }

    // MARK: OCKTask to FHIR CarePlanActivity

    func newResource() -> Resource { CarePlanActivity() }

    public var setFHIRID: (_ id: String, _ activity: Resource) throws -> Void = { id, activity in
        activity.id = FHIRPrimitive(FHIRString(id))
    }

    public var setFHIRTitle: (_ title: String?, _ activity: Resource) throws -> Void = { title, activity in
        guard let title = title else { return }
        activity.detail = activity.detail ?? CarePlanActivityDetail(prohibited: false)
        activity.detail?.description_fhir = FHIRPrimitive(FHIRString(title))
    }

    public var setFHIRSchedule: (OCKSchedule, CarePlanActivity) throws -> Void = { schedule, activity in
        activity.detail = activity.detail ?? CarePlanActivityDetail(prohibited: false)
        activity.detail?.scheduled = .timing(try OCKDSTU2ScheduleCoder().convert(entity: schedule))
    }

    public var setFHIRInstructions: (String?, CarePlanActivity) throws -> Void = { instructions, activity in
        // no-op
    }
}

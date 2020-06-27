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

protocol OCKTaskConverterTraits: OCKFHIRResourceCoder where Entity == OCKTask {

    // MARK: FHIR CarePlanActivity to OCKTask

    /// A closure that defines how `OCKTask`'s `id` property is mapped from a FHIR Resource.
    var getCareKitID: (Resource) throws -> String { get }

    /// A closure that defines how `OCKTask`'s `schedule` property is mapped from a FHIR Resource.
    var getCareKitSchedule: (Resource) throws -> OCKSchedule { get }

    /// A closure that defines how `OCKTask`'s `title` property is mapped from a FHIR Resource.
    var getCareKitTitle: (Resource) throws -> String? { get }

    /// A closure that defines how `OCKTasks`'s `instructions` property is mapped from a FHIR Resource.
    var getCareKitInstructions: (Resource) throws -> String? { get }

    // MARK: OCKTask to FHIR CarePlanResource

    /// A closure that sets a given id on a given Resource.
    var setFHIRID: (_ id: String, _ Resource: Resource) throws -> Void { get }

    /// A closure that sets a given title on a given Resource.
    var setFHIRTitle: (_ title: String?, _ Resource: Resource) throws -> Void { get }

    /// A closure that sets a given schedule on a given Resource.
    var setFHIRSchedule: (_ schedule: OCKSchedule, _ Resource: Resource) throws -> Void { get }

    /// A closure that sets the given instructions on a given medication order.
    var setFHIRInstructions: (String?, Resource) throws -> Void { get }

    /// Create a new Resource with all properties set to the default value.
    /// - Note: This is basically a stand in for requiring the associated type to have a default init.
    func newResource() -> Resource
}

extension OCKTaskConverterTraits {

    public func convert(resource: Resource) throws -> OCKTask {

        var task = OCKTask(
            id: try getCareKitID(resource),
            title: try getCareKitTitle(resource),
            carePlanUUID: nil,
            schedule: try getCareKitSchedule(resource))

        task.instructions = try getCareKitInstructions(resource)

        return task
    }

    public func convert(entity: OCKTask) throws -> Resource {
        let medicationOrder = newResource()
        try setFHIRID(entity.id, medicationOrder)
        try setFHIRTitle(entity.title, medicationOrder)
        try setFHIRInstructions(entity.instructions, medicationOrder)
        try setFHIRSchedule(entity.schedule, medicationOrder)
        return medicationOrder
    }
}

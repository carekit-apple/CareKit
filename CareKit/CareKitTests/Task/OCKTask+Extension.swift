/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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

@testable import CareKitStore
import Foundation

extension OCKTask {

    static func sample(
        uuid: UUID,
        id: String,
        title: String? = nil,
        instructions: String? = nil,
        groupIdentifier: String? = nil,
        schedule: OCKSchedule = .dailyAtTime(
            hour: 7, minutes: 0,
            start: Calendar.current.startOfDay(for: Date()),
            end: nil,
            text: nil
        ),
        impactsAdherence: Bool = true
    ) -> OCKTask {
        var task = OCKTask(
            id: id,
            title: title,
            carePlanUUID: nil,
            schedule: schedule
        )
        task.uuid = uuid
        task.instructions = instructions
        task.groupIdentifier = groupIdentifier
        task.impactsAdherence = impactsAdherence
        return task
    }

    func events(for date: Date) -> [OCKEvent<OCKTask, OCKOutcome>] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(
            byAdding: DateComponents(day: 1, second: -1),
            to: startOfDay
        )!
        return schedule
            .events(from: startOfDay, to: endOfDay)
            .map { OCKEvent(task: self, outcome: nil, scheduleEvent: $0) }
    }

    func anyEvents(for date: Date) -> [OCKAnyEvent] {
        events(for: date)
            .map(\.anyEvent)
    }

    func event(
        occurrence: Int,
        outcomeValues: [OCKOutcomeValue] = []
    ) -> OCKEvent<OCKTask, OCKOutcome> {
        let outcome = !outcomeValues.isEmpty ?
            OCKOutcome(
                taskUUID: uuid,
                taskOccurrenceIndex: occurrence,
                values: outcomeValues
            ) :
            nil

        let event = OCKEvent(
            task: self,
            outcome: outcome,
            scheduleEvent: schedule.event(forOccurrenceIndex: occurrence)!
        )
        return event
    }

    func anyEvent(
        occurrence: Int,
        outcomeValues: [OCKOutcomeValue] = []
    ) -> OCKAnyEvent {
        let event = self.event(occurrence: occurrence, outcomeValues: outcomeValues)
        return OCKAnyEvent(task: event.task, outcome: event.outcome, scheduleEvent: event.scheduleEvent)
    }
}

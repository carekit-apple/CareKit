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

private extension OCKAnyEvent {

    // Check if an event matches another event
    func matches(_ other: OCKAnyEvent) -> Bool {
        return
            other.scheduleEvent.occurrence == scheduleEvent.occurrence &&
            other.task.id == task.id
    }
}

/// A data structure that holds events from a multiplicity of tasks.
public struct OCKTaskEvents {

    private var events: [String: [OCKAnyEvent]] = [:]   // Maps a task identifier to a list of events belonging to that task
    private var sortedKeys: [String] = []               // Task identifiers used to index `events`. Sorted by most recently added.

    /// Returns the first event, if any, among the events for all tasks.
    public var firstEvent: OCKAnyEvent? {
        return event(forIndexPath: .init(row: 0, section: 0))
    }

    /// Returns the events for the first task.
    public var firstEvents: [OCKAnyEvent]? {
        return events(forSection: 0)
    }

    /// Adds an event.
    public mutating func addEvent(_ event: OCKAnyEvent) {
        let id = event.task.id
        let modifiedEvent = event

        // Add the event to the dictionary based on the task identifier
        if events[id] != nil {
            guard events[id]!.allSatisfy({ !$0.matches(event) }) else { return }    // Check for duplicates
            events[id]?.append(modifiedEvent)

        // Else create a new dictionary key for the event
        } else {
            events[id] = [modifiedEvent]
            sortedKeys.append(id)
        }
    }

    /// Updates an event, if it already exists, otherwise does nothing.
    public mutating func updateEvent(_ event: OCKAnyEvent) {
        let id = event.task.id
        guard let index = events[id]?.firstIndex(where: { $0.matches(event) }) else { return }
        events[id]?[index] = event
    }

    /// Returns the event at an index path, where the section represents the task and the item corresponds to the event index.
    public func event(forIndexPath indexPath: IndexPath) -> OCKAnyEvent? {
        guard let events = events(forSection: indexPath.section) else { return nil }
        guard indexPath.row < events.count else { return nil }
        return events[indexPath.row]
    }

    /// Returns all the events for the task in a section.
    public func events(forSection section: Int) -> [OCKAnyEvent]? {
        guard section < sortedKeys.count else { return nil }
        guard let events = self.events[sortedKeys[section]] else { fatalError("Sorted key not found in dictionary") }
        return events
    }

    /// Returns true if the given event is already present.
    public func containsEvent(_ event: OCKAnyEvent) -> Bool {
        let id = event.task.id
        for storedEvent in events[id] ?? [] {
            if storedEvent.matches(event) {
                return true
            }
        }
        return false
    }
}

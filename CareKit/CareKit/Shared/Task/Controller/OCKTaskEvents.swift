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

/// A data structure that holds events for multiple tasks.
///
/// This data structure acts much like an ordered set. Events are ordered by least recently added, and an event is only valid if it is unique
/// when compared to all other existing events. An event `x` is considered unique if:
///
/// 1. The task associated with `x` has a non-nil stable identity.
/// 2. There is no other event `y` in the data structure whose stable identity, and associated task's stable identity, match that of `x`.
///
/// Stable identity is defined by the `id` property of the `Identifiable` protocol.
public struct OCKTaskEvents: Collection, Identifiable {

    public var id: String {
        var hasher = Hasher()
        events
            .flatMap { $0.map(\.id) }
            .forEach { hasher.combine($0) }
        let id = hasher.finalize()
        return "\(id)"
    }

    /// Unique tasks.
    public var tasks: [OCKAnyTask] {
        (0..<events.count).compactMap { section in
            events[section].first?.task
        }
    }

    /// Each section contains events that have tasks with matching stable identities.
    private var events: [[OCKAnyEvent]] = []

    /// Create an instance.
    /// - Parameter events: Supply the events to store. Only unique events will be stored.
    public init(events: [OCKAnyEvent] = []) {
        events.forEach { append(event: $0) }
    }

    // Check for existence of an event with a particular uniqueness definition.
    /// - Parameter event: The event used to check for a uniqueness match.
    public func contains(event: OCKAnyEvent) -> Bool {
        indexPath(of: event) != nil
    }

    /// Append an event. The event will only be appended if it unique.
    /// - Parameter event: The event to append.
    /// - Returns: (event, true) if the `event` was successfully appended.
    ///            (event, false) If the `event` already exists.
    ///            (nil, false) If the provided event's task has a nil stable identity.
    @discardableResult
    public mutating func append(event: OCKAnyEvent) -> (OCKAnyEvent?, Bool) {
        // The task needs to have a stable identity. Sections are created based on the task's stable identity.
        guard event.task.stableID != nil else { return (nil, false) }

        // First make sure there is no matching event already stored in the data structure.
        let indexPath = self.indexPath(of: event)
        guard indexPath == nil else { return (self[indexPath!.section][indexPath!.row], false) }

        // Append the event to the matching section if one exists.
        if let section = section(for: event.task) {
            events[section].append(event)
            return (event, true)
        }

        // Otherwise, create a new section for the event.
        events.append([event])
        return (event, true)
    }

    /// Get all events that have matching tasks. Two tasks match if they have equal stable identities defined by the `Identifiable` protocol.
    /// - Parameter task: Task used to match for the desired events.
    public func events(forTask task: OCKAnyTask) -> [OCKAnyEvent] {
        guard let section = section(for: task) else { return [] }
        return events[section]
    }

    // Remove an event with a particular uniqueness definition.
    /// - Parameter event: The event used to check for a uniqueness match.
    /// - Returns: The event that was removed, otherwise nil.
    @discardableResult
    public mutating func remove(event: OCKAnyEvent) -> OCKAnyEvent? {
        guard let indexPath = indexPath(of: event) else { return nil }
        var updatedEvents = events[indexPath.section]
        let removedEvent = updatedEvents.remove(at: indexPath.row)

        // If the removed event was the last one in the section, remove the whole section.
        guard !updatedEvents.isEmpty else {
            events.remove(at: indexPath.section)
            return removedEvent
        }

        events[indexPath.section] = updatedEvents
        return removedEvent
    }

    /// Update an event with a particular uniqueness definition. The event will be inserted if it does not yet exist.
    /// - Parameter event: The event used to check for a uniqueness match.
    /// - Returns: The event that was updated. The return value will be nil if the event's task has a nil stable identity.
    @discardableResult
    public mutating func update(event: OCKAnyEvent) -> OCKAnyEvent? {
        // Update the matching event
        if let matchIndexPath = indexPath(of: event) {
            events[matchIndexPath.section][matchIndexPath.row] = event
            return event
        // Else append the event
        } else {
            let result = append(event: event)
            return result.0
        }
    }

    private func section(for task: OCKAnyTask) -> Int? {
        return events.firstIndex { $0.first?.task.matches(task) == true }
    }

    private func indexPath(of event: OCKAnyEvent) -> IndexPath? {
        guard let section = section(for: event.task) else { return nil }
        guard let row = events[section].firstIndex(where: { $0.matches(event) }) else { return nil }
        return .init(row: row, section: section)
    }

    // MARK: - Collection

    // Note: This struct uses default implementations for Collection methods thanks to its reliance on Array. The only exception is the use
    // of a custom subsequence. This customization should be tested.

    public typealias Iterator = Array<[OCKAnyEvent]>.Iterator
    public typealias Index = Array<[OCKAnyEvent]>.Index
    public typealias Element = Array<[OCKAnyEvent]>.Element
    public typealias SubSequence = OCKTaskEvents

    public var startIndex: Index { events.startIndex }
    public var endIndex: Index { events.endIndex }

    public func makeIterator() -> Iterator { events.makeIterator() }
    public func index(after i: Index) -> Index { events.index(after: i) }
    public subscript(index: Index) -> Iterator.Element { events[index] }

    public subscript(range: Range<IndexPath.Index>) -> SubSequence {
        // Set the underlying data structure directly so that this operation is 0(1), as required by the `Collection` protocol.
        var slice = OCKTaskEvents()
        slice.events = Array(events[range])
        return slice
    }
}

private extension OCKAnyEvent {

    /// The matching criteria used to check for uniqueness of two events.
    func matches(_ other: OCKAnyEvent) -> Bool {
        id == other.id && task.matches(task)
    }
}

private extension OCKAnyTask {

    /// The matching criteria used to check for uniqueness of two tasks.
    func matches(_ other: OCKAnyTask) -> Bool {
        stableID == other.stableID
    }

    var stableID: String? { uuid?.uuidString }
}

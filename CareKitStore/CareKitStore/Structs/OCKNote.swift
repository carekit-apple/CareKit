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

/// `OCKNote` can be attached to all other CareKit objects and values. Use cases may include a physician leaving a note on a task when it is modified
/// to explain why a medication dose was changed, or a note left from a patient to a care provider explaining why they weren't able to complete a
/// task on a certain occassion.
public struct OCKNote: Codable, Equatable, OCKObjectCompatible {
    
    /// The person who created this note.
    public var author: String?

    /// A title for the note.
    public var title: String?

    /// The note content.
    public var content: String?

    // MARK: OCKObjectCompatible
    internal var uuid: UUID?
    public internal(set) var createdDate: Date?
    public internal(set) var updatedDate: Date?
    public internal(set) var schemaVersion: OCKSemanticVersion?
    public var groupIdentifier: String?
    public var tags: [String]?
    public var remoteID: String?
    public var userInfo: [String: String]?
    public var source: String?
    public var asset: String?
    public var notes: [OCKNote]?
    public var timezone: TimeZone

    /// Initialize a new note with an optional author, title, and content.
    ///
    /// - Parameters:
    ///   - author: The person who created the note.
    ///   - title: The title of the note.
    ///   - content: The note's text content.
    public init(author: String?, title: String?, content: String?) {
        self.author = author
        self.title = title
        self.content = content
        self.timezone = TimeZone.current
    }
}

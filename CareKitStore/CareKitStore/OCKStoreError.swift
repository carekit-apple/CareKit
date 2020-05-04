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

/// `OCKStoreError`s will be emitted from `OCKStoreProtocol` conformers if there is problem during a transaction.
public enum OCKStoreError: LocalizedError {
    /// Occurs when a fetch fails.
    case fetchFailed(reason: String)

    /// Occurs when adding an entity fails.
    case addFailed(reason: String)

    /// Occurs when an update to an existing entity fails.
    case updateFailed(reason: String)

    /// Occurs when deleting an existing entity fails.
    case deleteFailed(reason: String)

    /// Occurs when synchronization with a remote server fails.
    case remoteSynchronizationFailed(reason: String)

    /// Occurs when an invalid value is provided.
    case invalidValue(reason: String)

    /// Occurs when an asynchronous action takes too long.
    /// - Note: This is intended for use by remote databases.
    case timedOut(reason: String)

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let reason): return "Failed to fetch: \(reason)"
        case .addFailed(let reason): return "Failed to add: \(reason)"
        case .updateFailed(let reason): return "Failed to update: \(reason)"
        case .deleteFailed(let reason): return "Failed to delete: \(reason)"
        case .remoteSynchronizationFailed(let reason): return "Sync failed: \(reason)"
        case .timedOut(let reason): return "Timed out: \(reason)"
        case .invalidValue(let reason): return "Invalid value: \(reason)"
        }
    }
}

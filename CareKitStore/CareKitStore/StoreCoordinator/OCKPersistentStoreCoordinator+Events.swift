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

import Foundation
import Synchronization

extension OCKStoreCoordinator {

    public func anyEvents(matching query: OCKEventQuery) -> CareStoreQueryResults<OCKAnyEvent> {

        let stores = state.withLock { state in
            return state.readOnlyEventStores + state.eventStores
        }

        let eventsStreams = stores.map {
            $0.anyEvents(matching: query)
        }

        let events = combineMany(
            sequences: eventsStreams,
            sort: { combinedResult in
                return combinedResult.sorted { $0.scheduleEvent.start < $1.scheduleEvent.start }
            }
        )

        return events
    }

    public func fetchAnyEvents(
        query: OCKEventQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<[OCKAnyEvent]>) {

        let stores = state.withLock { state in
            return state.readOnlyEventStores + state.eventStores
        }

        let closures = stores.map({ store in { done in
            store.fetchAnyEvents(query: query, callbackQueue: callbackQueue, completion: done) }
        })

        aggregateAndFlatten(closures, callbackQueue: callbackQueue, completion: completion)
    }

    public func fetchAnyEvent(
        forTask task: OCKAnyTask,
        occurrence: Int,
        callbackQueue: DispatchQueue,
        completion: @escaping OCKResultClosure<OCKAnyEvent>) {

        let stores = state.withLock { state in
            return state.readOnlyEventStores + state.eventStores
        }

        let closures = stores.map({ store in { done in
            store.fetchAnyEvent(forTask: task, occurrence: occurrence, callbackQueue: callbackQueue, completion: done) }
        })

        getFirstValidResult(closures, callbackQueue: callbackQueue, completion: completion)
    }
}

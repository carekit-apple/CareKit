/*
 Copyright (c) 2022, Apple Inc. All rights reserved.
 
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

extension OCKReadOnlyEventStore where Task: OCKAnyVersionableTask {

    /// Fetch partial event data for task version chains. This method will start by fetching the latest version
    /// of each task that matches the provided query. It will then walk back the version chain for each task
    /// and compute the partial events that occur for each version.
    ///
    /// An event will be produced for a task on a particular date if the version of the task is effective. As a
    /// result, any outcomes that exist on a particular date for a task version that is not effective will be lost.
    /// The `OCKStore` protects developers from making that mistake when they modify the store.
    func fetchPartialEvents(
        query: OCKTaskQuery,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<[PartialEvent<Task>], OCKStoreError>) -> Void
    ) {
        let latestTaskVersionsQuery = makeLatestTaskVersionsQuery(from: query)

        guard let dateInterval = latestTaskVersionsQuery.dateInterval else {
            fatalError("Date interval should be set in makeLatestTaskVersionsQuery(from:)")
        }

        fetchTaskVersionChains(
            query: latestTaskVersionsQuery,
            effectiveAfter: dateInterval.start,
            callbackQueue: callbackQueue
        ) { result in

            switch result {

            case let .success(taskVersionChains):

                let partialEvents = taskVersionChains
                    .flatMap {
                        self.makePartialEvents(
                            taskVersionChain: $0,
                            dateInterval: dateInterval
                        )
                    }

                completion(.success(partialEvents))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

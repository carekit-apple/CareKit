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

func chooseFirst<T>(then singularResultClosure: OCKResultClosure<T>?, replacementError: OCKStoreError) -> OCKResultClosure<[T]> {
    return { arrayResult in
        switch arrayResult {
        case .failure(let error):
            singularResultClosure?(.failure(error))
        case .success(let array):
            if let first = array.first { singularResultClosure?(.success(first)); return }
            singularResultClosure?(.failure(replacementError))
        }
    }
}

// Performs an array of operations and completes with the aggregated results or an an error, if any any occurs.
func aggregate<U>(_ closures: [(@escaping OCKResultClosure<[U]>) -> Void], callbackQueue: DispatchQueue,
                  completion: @escaping OCKResultClosure<[U]>) {
    let group = DispatchGroup()
    var error: OCKStoreError?
    var values: [U] = []

    for closure in closures {
        group.enter()
        closure({ result in
            switch result {
            case .failure(let storeError): error = storeError
            case .success(let storeValues): values.append(contentsOf: storeValues)
            }
            group.leave()
        })
    }

    group.notify(queue: callbackQueue) {
        if let error = error { completion(.failure(error)); return }
        completion(.success(values))
    }
 }

// Performs an array of operations and completes with the first result.
func getFirstValidResult<T>(_ closures: [(@escaping OCKResultClosure<T>) -> Void], callbackQueue: DispatchQueue,
                            completion: @escaping OCKResultClosure<T>) {
    let group = DispatchGroup()
    var values: [T] = []

    for closure in closures {
        group.enter()
        closure({ result in
            switch result {
            case .failure: break
            case .success(let fetchedValue):
                values.append(fetchedValue)
            }
            group.leave()
        })
    }

    group.notify(queue: callbackQueue) {
        guard let firstValue = values.first else {
            completion(.failure(.invalidValue(reason: "All of the operations failed.")))
            return
        }
        completion(.success(firstValue))
    }
}

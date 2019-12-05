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

/// CareKit can support any store that conforms to this protocol. The `OCKStore` class included in CareKit is a CoreData store that the implements
/// `OCKStoreProtocol` to provide on device storage. Support for other databases such as JSON files, REST API's, websockets, and 3rd part databases
/// can be added by conforming them to `OCKStoreProtocol`.
///
/// `OCKStoreProtocol` requires that a minimum level of functionality be provided, and then provides enhanced functionality via protocol extensions.
/// The methods provided by protocol extensions are naive implementations and are not efficient. Developers may wish to use the customization points
/// on `OCKStoreProtocol` to provide more efficient implementations that take advantage of the underlying database's native features.
///
/// - Remark: All methods defined in this protocol are required to be implemented as batch operations and should function as transactions.
/// If any one operation should fail, the state of the store should be returned to the state it was in before the transaction began. For example,
/// if an attempt to save an array of 10 outcomes fails on the 6th outcome, the first successfully persisted 6 outcomes must be rolled back to restore
/// the store to the state it was in prior to the transaction.
public typealias OCKStoreProtocol = OCKPatientStore & OCKCarePlanStore & OCKContactStore & OCKEventStore
public typealias OCKAnyStoreProtocol = OCKAnyPatientStore & OCKAnyCarePlanStore & OCKAnyContactStore & OCKAnyEventStore

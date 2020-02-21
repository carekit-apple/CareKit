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

import CoreData
import Foundation

/// The default store used in CareKit. The underlying database used is CoreData.
open class OCKStore: OCKStoreProtocol, OCKCoreDataStoreProtocol, Equatable {

    /// The delegate receives callbacks when the contents of the patient store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    public weak var patientDelegate: OCKPatientStoreDelegate?

    /// The delegate receives callbacks when the contents of the care plan store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    public weak var carePlanDelegate: OCKCarePlanStoreDelegate?

    /// The delegate receives callbacks when the contents of the contacts store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    public weak var contactDelegate: OCKContactStoreDelegate?

    /// The delegate receives callbacks when the contents of the tasks store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    public weak var taskDelegate: OCKTaskStoreDelegate?

    /// The delegate receives callbacks when the contents of the outcome store are modified.
    /// In `CareKit` apps, the delegate will be set automatically, and it should not be modified.
    public weak var outcomeDelegate: OCKOutcomeStoreDelegate?

    /// The configuration can be modified to enable or disable versioning of database entities.
    public var configuration = OCKStoreConfiguration()

    /// Two instances of `OCKStore` are considered to be equal if they have the same name and store type.
    public static func == (lhs: OCKStore, rhs: OCKStore) -> Bool {
        lhs.name == rhs.name && lhs.storeType == rhs.storeType
    }

    /// The name of the store. When the store type is `onDisk`, this name will be used for the SQLite filename.
    public let name: String

    /// The store type determines where data is stored. Generally `onDisk` should be chosen in order to persist data, but `inMemory` may be useful
    /// for development and testing purposes.
    internal let storeType: OCKCoreDataStoreType

    /// Initialize a new store by specifying its name and store type. Store's with conflicting names and types must not be created.
    ///
    /// - Parameters:
    ///   - name: A unique name for the store. It will be used for the filename if stored on disk.
    ///   - type: The type of store to be used.
    public init(name: String, type: OCKCoreDataStoreType = .onDisk) {
        self.storeType = type
        self.name = name
    }

    // MARK: Internal

    internal lazy var persistentContainer: NSPersistentContainer = {
        makePersistentContainer()
    }()

    internal lazy var context: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()
}

internal extension NSPredicate {
    func including(groupIdentifiers: [String]) -> NSPredicate {
        let groupPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDObject.groupIdentifier), groupIdentifiers)
        return NSCompoundPredicate(andPredicateWithSubpredicates: [self, groupPredicate])
    }
}

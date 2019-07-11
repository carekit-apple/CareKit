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

protocol OCKCDManageable: AnyObject, NSFetchRequestResult {
    static var entityName: String { get }
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
}

extension OCKCDManageable {
    static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        return request
    }

    static func sortedFetchRequest(withPredicate predicate: NSPredicate) -> NSFetchRequest<Self> {
        let request = sortedFetchRequest
        request.predicate = predicate
        return request
    }
}

extension OCKCDManageable where Self: NSManagedObject {
    static var entityName: String { return entity().name! }

    /// Fetches all objects from the store matching the provided predicate. This method queries all the way down
    /// to the database layer because while we may be able to find some objects matching the query in memory, we
    /// cannot guarantee that there aren't more yet to be loaded from the database
    ///
    /// - Parameters:
    ///   - context: the context in which to search
    ///   - predicate: a predicate to match against
    ///   - configureFetchRequest: a closure in which you may customize the fetch request
    /// - Returns: all objects matching the give predicate
    static func fetchFromStore(in context: NSManagedObjectContext, where predicate: NSPredicate,
                               configureFetchRequest: ((NSFetchRequest<Self>) -> Void)? = nil) -> [Self] {
        let request = sortedFetchRequest(withPredicate: predicate)
        configureFetchRequest?(request)
        guard let results = try? context.fetch(request) else { fatalError("This should never fail") }
        return results
    }
}

extension OCKCDManageable where Self: OCKVersionable & NSManagedObject {
    static func validateNewIdentifiers(_ identifiers: [String], in context: NSManagedObjectContext) throws {
        guard Set(identifiers).count == identifiers.count else {
            throw OCKStoreError.invalidValue(reason: "Identifiers contains duplicate values! [\(identifiers)]")
        }

        let existingPredicate = NSPredicate(format: "%K IN %@", #keyPath(OCKCDVersionedObject.identifier), identifiers)
        let existingIdentifiers = fetchFromStore(in: context, where: existingPredicate, configureFetchRequest: { request in
            request.propertiesToFetch = [#keyPath(OCKCDVersionedObject.identifier)]
        }).map { $0.identifier }

        guard existingIdentifiers.isEmpty else {
            let objectClass = String(describing: type(of: self))
            throw OCKStoreError.invalidValue(reason: "\(objectClass) with identifiers [\(Set(existingIdentifiers))] already exists!")
        }
    }

    static func validateUpdateIdentifiers(_ identifiers: [String], in context: NSManagedObjectContext) throws {
        guard Set(identifiers).count == identifiers.count else {
            throw OCKStoreError.invalidValue(reason: "Identifiers contains duplicate values! [\(identifiers)]")
        }
    }
}

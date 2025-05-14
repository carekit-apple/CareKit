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

#if !os(watchOS)

import CareKitStore
import CareKitUI
import UIKit


/// A synchronizer that creates and updates a list of contact views.
public final class _OCKContactsListViewSynchronizer<
    ContactViewSynchronizer: ViewSynchronizing
>: ViewSynchronizing where
    ContactViewSynchronizer.View: OCKContactDisplayable,
    ContactViewSynchronizer.ViewModel == OCKAnyContact?
{


    private let contactViewSynchronizer: ContactViewSynchronizer

    weak var contactViewDelegate: OCKContactViewDelegate?

    init(contactViewSynchronizer: ContactViewSynchronizer) {
        self.contactViewSynchronizer = contactViewSynchronizer
    }

    public func makeView() -> UIView {
        return OCKListView()
    }

    public func updateView(
        _ view: UIView,
        context: OCKSynchronizationContext<[OCKAnyContact]>
    ) {
        guard let stackView = (view as? OCKListView)?.stackView else {
            assertionFailure("Invalid view type")
            return
        }

        // Update each contact view if needed
        for (index, newContact) in context.viewModel.enumerated() {

            // 1. Ensure the contact has changed before doing the work to update the view

            let oldContact = index < context.oldViewModel.count ?
                context.oldViewModel[index] : nil

            guard
                oldContact == nil ||
                !oldContact!.isEqual(to: newContact)
            else {
                continue
            }

            // 2. Update the contact view with the new context

            let context = OCKSynchronizationContext(
                viewModel: newContact,
                oldViewModel: oldContact,
                animated: context.animated
            )

            let contactView: ContactViewSynchronizer.View = {
                // Check if we need to create a new contact view to add to the stack
                if index >= stackView.arrangedSubviews.count {
                    let contactView = contactViewSynchronizer.makeView()
                    stackView.addArrangedSubview(contactView, animated: context.animated)
                }

                guard let contactView = stackView.arrangedSubviews[index] as? ContactViewSynchronizer.View else {
                    fatalError("Invalid view type")
                }
                return contactView
            }()

            contactViewSynchronizer.updateView(contactView, context: context)

            contactView.tag = index  // The tag can be later used to locate the corresponding contact for the view
            contactView.delegate = contactViewDelegate
        }

        // Remove extra views in the stack
        trimExtraneousItemViews(in: stackView, context: context)
    }

    func contact(
        forView view: UIView & OCKContactDisplayable,
        contacts: [OCKAnyContact]
    ) -> OCKAnyContact? {
        return contacts[view.tag]
    }

    private func trimExtraneousItemViews(
        in stackView: OCKStackView,
        context: OCKSynchronizationContext<[OCKAnyContact]>
    ) {
        // Compute the number of item views that exceed the number of contacts
        let countToRemove = max(
            stackView.arrangedSubviews.count - context.viewModel.count,
            0
        )

        // Remove the extra item views
        for _ in 0..<countToRemove {
            guard let toRemove = stackView.arrangedSubviews.last else { continue }
            stackView.removeArrangedSubview(toRemove, animated: context.animated)
        }
    }
}

#endif

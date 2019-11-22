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
import CareKitUI
import UIKit

/// A view controller displaying views in an `OCKListView`.
/// `OCKDailyPageViewController` uses `OCKListViewController`s to display scrollable stacks of
/// embedded view controllers.
open class OCKListViewController: UIViewController {

    // MARK: Properties

    /// The list view that displays the view controller's views.
    var listView: OCKListView {
        guard let view = self.view as? OCKListView else { fatalError("Unsupported view type.") }
        return view
    }

    // MARK: - Life cycle

    override open func loadView() {
        view = OCKListView()
    }

    // MARK: - Methods

    /// Sets up the containment of `viewController` in OCKListViewController and appends its view
    /// to the vertical stack of listed views.
    ///
    /// - Parameters:
    ///   - viewController: The view controller with the view to append. If the new child view controller
    ///   is already the child of a container view controller, it is removed from that container before being appended..
    ///   - animated: Pass `true` to animate the addition of the `viewController`'s view.
    open func appendViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.setupContainment(in: self, stackView: listView.stackView, animated: animated)
    }

    /// Appends `view` to the vertical stack of listed views.
    ///
    /// - Parameters:
    ///   - view: The view to append to the current end of the list.
    ///   - animated: Pass `true` to animate the addition of the view.
    open func appendView(_ view: UIView, animated: Bool) {
        listView.stackView.addArrangedSubview(view, animated: animated)
    }

    /// Sets up the containment of `viewController` in OCKListViewController and inserts its view
    /// in the vertical stack of listed views at the specified index.
    ///
    /// - Parameters:
    ///   - viewController: The view controller with the view to insert. If the view controller is already the child of
    ///   a container view controller, it is removed from that container before being inserted.
    ///   - index: The index at which to insert the `viewController`'s view. This value must not be greater
    ///   than the number of views in the `OCKListViewController`. If the index is out of bounds, this method
    ///    throws an internalInconsistencyException exception.
    ///   - animated: Pass `true` to animate the insertion of `viewController`'s view.
    open func insertViewController(_ viewController: UIViewController, at index: Int, animated: Bool) {
        viewController.setupContainment(in: self, stackView: listView.stackView, at: index, animated: animated)
    }

    /// Inserts a view in the vertical stack of listed views at the specified index.
    ///
    /// - Parameters:
    ///   - view: The view to insert in the list.
    ///   - index: The index at which to insert `view`. This value must not be greater than the number of views
    ///   in the `OCKListViewController`. If the index is out of bounds, this method throws an
    ///   internalInconsistencyException exception.
    ///   - animated: Pass `true` to animate the insertion of `view`.
    open func insertView(_ view: UIView, at index: Int, animated: Bool) {
        listView.stackView.insertArrangedSubview(view, at: index, animated: animated)
    }

    /// Removes the view located at `index`.
    ///
    /// - Parameter index: The index of the view to be removed. This must be a valid index in the number of views listed.
    open func remove(at index: Int) {
        let view = listView.stackView.arrangedSubviews[index]
        if let viewController = children.first(where: { $0.view == view }) {
            viewController.clearContainment()
        } else {
            view.removeFromSuperview()
        }
    }

    /// Removes all displayed views without animation.
    open func clear() {
        listView.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        children.forEach { $0.clearContainment() }
    }
}

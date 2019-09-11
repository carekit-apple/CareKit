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
import Combine
import Foundation
import UIKit

/// Provides context for a view model value.
public struct OCKSynchronizationContext<ViewModel> {
    /// The current view model value.
    public let viewModel: ViewModel?

    /// The previous view model value.
    public let oldViewModel: ViewModel?

    /// Animated flag.
    public let animated: Bool
}

protocol OCKSynchronizedViewControllerDelegate: AnyObject {
    func synchronizedViewController<V: UIView, VM: Equatable>(_ viewController: OCKSynchronizedViewController<V, VM>,
                                                              didUpdate synchronizedView: V,
                                                              withContext context: OCKSynchronizationContext<VM>)
}

/// Abstract class that handles synchronization between a view model and a view.
///
/// To specify the view used by this view controller, specialize the generic `View` and override the `makeView()` method.
///
/// To set a new `viewModel` value, call `setViewModel(viewModel:animated)`. This will trigger an update to view.
///
/// To update the view based on the current context, override the `updateView(view:context)`. This method will be called any time
/// `setViewModel(viewModel:animated)` is called. Do not call this method directly.
///
/// To set a subscription, call the `subscribe(makeSubscription)` method and provide a block to make a subscription. You will generally want to call
/// `setViewModel(viewModel:animated)` inside the block to trigger updates when the view model changes. The life cycle of the subscription is handled
/// internally.
open class OCKSynchronizedViewController<View: UIView, ViewModel: Equatable>: UIViewController {
    // MARK: Properties

    private var cachedContext: OCKSynchronizationContext<ViewModel>?
    private var subscription: AnyCancellable?
    var unsubscribesWhenNotShown = true
    weak var synchronizationDelegate: OCKSynchronizedViewControllerDelegate?

    /// True if setting a new view model that is equal to the previous view model will trigger a view update.
    var updatesViewWithDuplicates = true

    /// The view that is synchronized with the view model.
    public var synchronizedView: View {
        guard let view = view as? View else { fatalError("Unsupported view type.") }
        return view
    }

    /// The data that is used to populate the view.
    public private (set) var viewModel: ViewModel?

    // MARK: Life Cycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func loadView() {
        view = makeView()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Update the view if a cached update has been waiting
        if let context = cachedContext {
            updateView(synchronizedView, context: context)
        }

        renewSubscriptionIfNeeded()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renewSubscriptionIfNeeded()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if unsubscribesWhenNotShown {
            cancelSubscription()
        }
    }

    // MARK: - Functions

    private func renewSubscriptionIfNeeded() {
        guard subscription == nil else { return }
        subscribe()
    }

    private func cancelSubscription() {
        subscription?.cancel()
        subscription = nil
    }

    /// Make the view that is used by this view controller. The view will be lazy loaded.
    open func makeView() -> View {
        fatalError("Need to override makeView()")
    }

    /// Update the view with new `context` information. The default implementation of this method does nothing and should not be called, override to
    /// define custom behavior. Do not call this method directly when the view needs an update, rather, call `updateView(view:context)`.
    /// - Parameter view: The view to update.
    /// - Parameter context: The context used to update the view.
    open func updateView(_ view: View, context: OCKSynchronizationContext<ViewModel>) {
        fatalError("Need to override updateView(view:context:)")
    }

    /// Create a subscription whose life cycle will be handled by the view controller. The stream should ideally call
    /// `setViewModel(viewModel:animated)` when new view model data appears.
    ///
    /// This method will get called when the view is loaded. If you need to setup the subscription at a more specific time, see `subcribe()`.
    open func makeSubscription() -> AnyCancellable? {
        fatalError("Need to override makeSubscription()")
    }

    /// Set the view model and trigger an update to the view. If the view has not yet been loaded, the update will occur once it has loaded.
    /// - Parameter viewModel: New view model value.
    /// - Parameter animated: True to animate changes to the view.
    open func setViewModel(_ viewModel: ViewModel?, animated: Bool) {
        if !updatesViewWithDuplicates && viewModel == self.viewModel { return }
        let context = OCKSynchronizationContext(viewModel: viewModel, oldViewModel: self.viewModel, animated: animated)
        self.viewModel = viewModel

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // update the view if it is loaded
            if self.isViewLoaded {
                self.updateView(self.synchronizedView, context: context)
                self.synchronizationDelegate?.synchronizedViewController(self, didUpdate: self.synchronizedView, withContext: context)
            // else cache the update for when the view is loaded
            } else {
                self.cachedContext = context
            }
        }
    }

    /// Cancels and renews the current subscription defined in `makeSubscription()`. This method will be called by default when the view is loaded.
    open func subscribe() {
        cancelSubscription()
        subscription = makeSubscription()
    }
}

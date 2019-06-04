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
import UIKit
import Combine
import CareKitStore

internal protocol OCKViewUpdaterDelegate: class {
    func viewUpdater<ViewModel>(_ viewController: UIViewController, didUpdate view: UIView, with viewModel: ViewModel)
}

/// The `OCKSynchronizedViewController` acts as an absctract base class for many of CareKit's view controllers.
/// It contains basic functionality pertaining to life cycles and subscription management. It should not be instantiated directly.
open class OCKSynchronizedViewController<ViewModel>: UIViewController {
    
    // MARK: Properties
    
    internal typealias UpdateView = (_ viewModel: ViewModel?, _ animated: Bool) -> Void
    internal typealias ModelDidChange = (UpdateView, _ viewToUpdate: UIView, _ viewModel: ViewModel?, _ animated: Bool) -> Void
    internal typealias CustomModelDidChange = (_ viewToUpdate: UIView, _ viewModel: ViewModel?, _ animated: Bool) -> Void
    
    internal var subscription: Cancellable?
    private var modelDidChange: ModelDidChange = { _, _, _, _ in }
    private var updateView: UpdateView = { _, _ in }
    internal weak var viewUpdaterDelegate: OCKViewUpdaterDelegate?
    internal var unsubscribesWhenNotShown = false
    private var _loadView: () -> UIView

    // MARK: Life Cycle
    
    internal init(loadCustomView: @escaping () -> UIView, modelDidChange: @escaping CustomModelDidChange) {
        self._loadView = loadCustomView
        super.init(nibName: nil, bundle: nil)
        self.modelDidChange = { (_, view, viewModel, animated) in modelDidChange(view, viewModel, animated) }
    }
    
    internal init<View: UIView & OCKBindable>(loadDefaultView: @escaping () -> View,
                                              modelDidChange: ModelDidChange? = nil) where View.Model == ViewModel {
        self._loadView = loadDefaultView
        super.init(nibName: nil, bundle: nil)
        self.updateView = { [weak self] viewModel, animated in
            guard let self = self else { return }
            guard let view = self.view as? View else { fatalError("Unexpected view type") }
            view.updateView(with: viewModel, animated: animated)
            self.viewUpdaterDelegate?.viewUpdater(self, didUpdate: view, with: viewModel)
        }
        
        // Use the block that was passed in as a parameter, if it is nil, use the default
        self.modelDidChange = modelDidChange ?? { (superBindModel, _, viewModel, animated) in superBindModel(viewModel, animated) }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func loadView() {
        view = _loadView()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        subscribe()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renewSubscriptionIfNeeded()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if unsubscribesWhenNotShown {
            cancelSubscription()
        }
    }
    
    // This should be overriden by subsclasses
    internal func subscribe() {
        cancelSubscription()
    }
    
    internal func cancelSubscription() {
        subscription?.cancel()
        subscription = nil
    }
    
    internal func renewSubscriptionIfNeeded() {
        guard subscription == nil else { return }
        subscribe()
    }
    
    // Call this to update the view and call the delegate method to notify listeners that the view has been updated.
    internal func modelUpdated(viewModel: ViewModel?, animated: Bool) {
        self.modelDidChange(self.updateView, self.view, viewModel, animated)
        self.viewUpdaterDelegate?.viewUpdater(self, didUpdate: view, with: viewModel)
    }
}

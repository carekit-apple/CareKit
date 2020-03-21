/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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
import Combine
import MessageUI
import UIKit

/// Types wishing to receive updates from taskCategory view controllers can conform to this protocol.
public protocol OCKTaskCategoryViewControllerDelegate: AnyObject {

    /// Called when an unhandled error is encountered in a taskCategory view controller.
    /// - Parameters:
    ///   - viewController: The view controller in which the error was encountered.
    ///   - didEncounterError: The error that was unhandled.
    func taskCategoryViewController<C: OCKTaskCategoryControllerProtocol, VS: OCKTaskCategoryViewSynchronizerProtocol>(
        _ viewController: OCKTaskCategoryViewController<C, VS>, didEncounterError: Error)
}

/// A view controller that displays a taskCategory view and keep it synchronized with a store.
open class OCKTaskCategoryViewController<Controller: OCKTaskCategoryControllerProtocol, ViewSynchronizer: OCKTaskCategoryViewSynchronizerProtocol>:
UIViewController, OCKTaskCategoryViewDelegate {

    // MARK: Properties

    /// If set, the delegate will receive updates when import events happen
    public weak var delegate: OCKTaskCategoryViewControllerDelegate?

    /// Handles the responsibility of updating the view when data in the store changes.
    public let viewSynchronizer: ViewSynchronizer

    /// Handles the responsibility of interacting with data from the store.
    public let controller: Controller

    /// The view that is being synchronized against the store.
    public var taskCategoryView: ViewSynchronizer.View {
        guard let view = self.view as? ViewSynchronizer.View else { fatalError("View should be of type \(ViewSynchronizer.View.self)") }
        return view
    }

    private var viewDidLoadCompletion: (() -> Void)?
    private var viewModelSubscription: AnyCancellable?

    // MARK: - Life Cycle

    /// Initialize with a controller and synchronizer.
    public init(controller: Controller, viewSynchronizer: ViewSynchronizer) {
        self.controller = controller
        self.viewSynchronizer = viewSynchronizer
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    override open func loadView() {
        view = viewSynchronizer.makeView()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        taskCategoryView.delegate = self

        // Begin listening for changes in the view model. Note, when we subscribe to the view model, it sends its current value through the stream
        startObservingViewModel()

        viewDidLoadCompletion?()
    }

    // MARK: - Methods

    // Create a subscription that updates the view when the view model is updated.
    private func startObservingViewModel() {
        viewModelSubscription?.cancel()
        viewModelSubscription = controller.objectWillChange
            .context()
            .sink { [view] context in
                guard let typedView = view as? ViewSynchronizer.View else { fatalError("View should be of type \(ViewSynchronizer.View.self)") }
                self.viewSynchronizer.updateView(typedView, context: context)
            }
    }

    @objc
    private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    func handleResult<Success>(_ result: Result<Success, Error>, successCompletion: (_ value: Success) -> Void) {
        switch result {
        case .failure(let error): delegate?.taskCategoryViewController(self, didEncounterError: error)
        case .success(let value): successCompletion(value)
        }
    }

    func handleThrowable<T>(method: () throws -> T, success: (T) -> Void) {
        do {
            let result = try method()
            success(result)
        } catch {
            delegate?.taskCategoryViewController(self, didEncounterError: error)
        }
    }

    // MARK: - OCKTaskCategoryViewDelegate
    open func didSelectTaskCategoryView(_ taskCategoryView: UIView & OCKTaskCategoryDisplayable) {
        guard let taskCategory = controller.objectWillChange.value as? OCKTaskCategory else { return }
        guard let store = controller.store as? OCKAnyStoreProtocol else { return }
        let storeManager = OCKSynchronizedStoreManager(wrapping: store)
        let rootViewController = OCKDailyTasksPageViewController(storeManager: storeManager, taskCategory: taskCategory)
        rootViewController.navigationItem.rightBarButtonItem =
        UIBarButtonItem(title: "Done", style: .plain, target: self,
                        action: #selector(dismissViewController))
        let navigationController = UINavigationController(rootViewController: rootViewController)
        self.present(navigationController, animated: true, completion: nil)
    }
}

public extension OCKTaskCategoryViewController where Controller: OCKTaskCategoryController {

    /// Initialize a view controller that displays a task category. Fetches and stays synchronized with the task category.
    /// - Parameter viewSynchronizer: Manages the taskCategory view.
    /// - Parameter query: Used to fetch the task category to display.
    /// - Parameter storeManager: Wraps the store that contains the task category to fetch.
    convenience init(viewSynchronizer: ViewSynchronizer, query: OCKAnyTaskCategoryQuery, storeManager: OCKSynchronizedStoreManager) {
        self.init(controller: .init(storeManager: storeManager), viewSynchronizer: viewSynchronizer)
        viewDidLoadCompletion = { [weak self] in
            self?.controller.fetchAndObserveTaskCategory(forQuery: query, errorHandler: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.taskCategoryViewController(self, didEncounterError: error)
            })
        }
    }

    /// Initialize a view controller that displays a task category in the store. Stays synchronized with the provided task category.
    /// - Parameter viewSynchronizer: Manages the task category view.
    /// - Parameter taskCategory: The task category to display.
    /// - Parameter storeManager: Wraps the store that contains the task category to fetch.
    convenience init(viewSynchronizer: ViewSynchronizer, taskCategory: OCKAnyTaskCategory, storeManager: OCKSynchronizedStoreManager) {
        self.init(controller: .init(storeManager: storeManager), viewSynchronizer: viewSynchronizer)
        viewDidLoadCompletion = { [weak self] in
            self?.controller.observeTaskCategory(taskCategory)
        }
    }

    /// Initialize a view controller that displays a task category. Fetches and stays synchronized with the task category.
    /// - Parameter viewSynchronizer: Manages the task category view.
    /// - Parameter taskCategoryID: The user-defined unique identifier for the task category to fetch.
    /// - Parameter storeManager: Wraps the store that contains the task category to fetch.
    convenience init(viewSynchronizer: ViewSynchronizer, taskCategoryID: String, storeManager: OCKSynchronizedStoreManager) {
        self.init(controller: .init(storeManager: storeManager), viewSynchronizer: viewSynchronizer)
        viewDidLoadCompletion = { [weak self] in
            self?.controller.fetchAndObserveTaskCategory(withID: taskCategoryID, errorHandler: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.taskCategoryViewController(self, didEncounterError: error)
            })
        }
    }
}


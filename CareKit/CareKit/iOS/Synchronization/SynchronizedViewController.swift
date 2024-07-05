/*
 Copyright (c) 2021, Apple Inc. All rights reserved.
 
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

#if !os(watchOS) && !os(macOS)

import UIKit

/// A view controller that updates its view using a stream of data.
///
/// This view controller observes a stream of data from the view it's mapped to,
/// according to `viewSynchronizer`.
///
/// For example,  you want to create a view that is synchronized with a stream of integers. Begin by defining a view
/// synchronizer that creates and updates a `UILabel`:
///
/// ```swift
/// final class NumericLabelViewSynchronizer: ViewSynchronizing {
///
///     func makeView() -> UILabel {
///         return UILabel()
///     }
///
///     func updateView(
///         _ view: UILabel,
///         context: OCKSynchronizationContext<Int>
///     ) {
///         view.text = "\(context.viewModel)"
///     }
/// }
/// ```
/// Next, instantiate a synchronized view controller using the view synchronizer and a stream of integers:
///
/// ```swift
/// let viewController = SynchronizedViewController(
///     initialViewModel: 0,
///     viewModels: [1, 2, 3].async,
///     viewSynchronizer: NumericLabelViewSynchronizer()
/// )
/// ```
///
/// The view displays the `initialViewModel` when it's first instantiated. It then displays each
/// value in the stream of integers.
open class SynchronizedViewController<ViewSynchronizer: ViewSynchronizing>: UIViewController {

    /// The data displayed in ``SynchronizedViewController/typedView``.
    public var viewModel: ViewSynchronizer.ViewModel {
        context.viewModel
    }

    /// The view that the view synchronizer creates.
    public var typedView: ViewSynchronizer.View {
        guard let typedView = view as? ViewSynchronizer.View else {
            fatalError("View has the wrong type.")
        }
        return typedView
    }

    let viewSynchronizer: ViewSynchronizer
    
    private var updateViewWhenNeeded: () async -> Void = {}
    private var context: OCKSynchronizationContext<ViewSynchronizer.ViewModel>

    /// A view controller that updates its view using a stream of data.
    ///
    /// - Parameters:
    ///   - initialViewModel: The initial value displayed in the view.
    ///   - viewModels: An asynchronous sequence of data that appears in the view.
    ///   - viewSynchronizer: The object that creates and updates the view.
    public init<S: AsyncSequence>(
        initialViewModel: ViewSynchronizer.ViewModel,
        viewModels: S,
        viewSynchronizer: ViewSynchronizer
    ) where S.Element == ViewSynchronizer.ViewModel {

        self.viewSynchronizer = viewSynchronizer

        context = OCKSynchronizationContext(
            viewModel: initialViewModel,
            oldViewModel: initialViewModel,
            animated: false
        )

        super.init(nibName: nil, bundle: nil)

        updateViewWhenNeeded = { [weak self] in

            await self?.updateViewWhenNeeded(viewModels: viewModels)
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    override open func loadView() {
        view = viewSynchronizer.makeView()
    }

    override open func viewDidLoad() {

        super.viewDidLoad()

        // Update the view with the initial view model
        viewSynchronizer.updateView(typedView, context: context)

        // Update the view when new view models are received
        Task {
            await updateViewWhenNeeded()
        }
    }

    /// Reset the state of the view if an error occurs.
    ///
    /// The user interface assumes successful user interactions, and displays the corresponding state immediately.
    /// If an interaction is unsuccessful, use this method to reset the user interface.
    func resetViewOnError<Success, Error>(result: Result<Success, Error>) {

        guard case .failure = result else { return }

        let nonAnimatedContext = OCKSynchronizationContext(
            viewModel: context.viewModel,
            oldViewModel: context.oldViewModel,
            animated: false
        )

        viewSynchronizer.updateView(typedView, context: nonAnimatedContext)
    }

    private func updateViewWhenNeeded<S: AsyncSequence>(
        viewModels: S
    ) async where S.Element == ViewSynchronizer.ViewModel {

        do {

            for try await viewModel in viewModels {

                let newContext = OCKSynchronizationContext(
                    viewModel: viewModel,
                    oldViewModel: context.viewModel,
                    animated: true
                )

                context = newContext

                viewSynchronizer.updateView(typedView, context: newContext)
            }

        } catch {

            // Refresh the view with the last valid context
            viewSynchronizer.updateView(typedView, context: context)

            log(
                .debug,
                "Encountered an error while streaming data from the CareKit store",
                error: error
            )
        }
    }
}

#endif

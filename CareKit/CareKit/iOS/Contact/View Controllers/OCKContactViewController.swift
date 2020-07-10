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
#if canImport(MessageUI)

import CareKitStore
import CareKitUI
import Combine
import MessageUI
import UIKit

/// Types wishing to receive updates from contact view controllers can conform to this protocol.
public protocol OCKContactViewControllerDelegate: AnyObject {

    /// Called when an unhandled error is encountered in a contact view controller.
    /// - Parameters:
    ///   - viewController: The view controller in which the error was encountered.
    ///   - error: The error that was unhandled.
    func contactViewController<C: OCKContactController, VS: OCKContactViewSynchronizerProtocol>(
        _ viewController: OCKContactViewController<C, VS>, didEncounterError error: Error)
}

/// A view controller that displays a contact view and keep it synchronized with a store.
open class OCKContactViewController<Controller: OCKContactController, ViewSynchronizer: OCKContactViewSynchronizerProtocol>:
UIViewController, OCKContactViewDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {

    // MARK: Properties

    /// If set, the delegate will receive updates when import events happen
    public weak var delegate: OCKContactViewControllerDelegate?

    /// Handles the responsibility of updating the view when data in the store changes.
    public let viewSynchronizer: ViewSynchronizer

    /// Handles the responsibility of interacting with data from the store.
    public let controller: Controller

    /// The view that is being synchronized against the store.
    public var contactView: ViewSynchronizer.View {
        guard let view = self.view as? ViewSynchronizer.View else { fatalError("View should be of type \(ViewSynchronizer.View.self)") }
        return view
    }

    private let query: OCKSynchronizedContactQuery?
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Life Cycle

    /// Initialize with a controller and synchronizer.
    public init(controller: Controller, viewSynchronizer: ViewSynchronizer) {
        self.controller = controller
        self.viewSynchronizer = viewSynchronizer
        self.query = nil
        super.init(nibName: nil, bundle: nil)
    }

    /// Initialize a view controller that displays a contact in the store. Stays synchronized with the provided contact.
    /// - Parameter viewSynchronizer: Manages the contact view.
    /// - Parameter contact: The contact to display.
    /// - Parameter storeManager: Wraps the store that contains the contact to fetch.
    public init(viewSynchronizer: ViewSynchronizer, contact: OCKAnyContact, storeManager: OCKSynchronizedStoreManager) {
        self.controller = .init(storeManager: storeManager)
        self.viewSynchronizer = viewSynchronizer
        self.query = .contact(contact)
        super.init(nibName: nil, bundle: nil)
    }

    /// Initialize a view controller that displays a contact. Fetches and stays synchronized with the contact.
    /// - Parameter viewSynchronizer: Manages the contact view.
    /// - Parameter contactID: The user-defined unique identifier for the contact to fetch.
    /// - Parameter storeManager: Wraps the store that contains the contact to fetch.
    public init(viewSynchronizer: ViewSynchronizer, contactID: String, storeManager: OCKSynchronizedStoreManager) {
        self.controller = .init(storeManager: storeManager)
        self.viewSynchronizer = viewSynchronizer
        self.query = .contactID(contactID)
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
        contactView.delegate = self

        // Begin listening for changes in the view model. Note, when we subscribe to the view model, it sends its current value through the stream
        startObservingViewModel()

        // Listen for any errors encountered by the controller.
        controller.$error
            .compactMap { $0 }
            .sink { [unowned self] error in
                if self.delegate == nil {
                    log(.error, "A task error occurred, but no delegate was set to forward it to!", error: error)
                }
                self.delegate?.contactViewController(self, didEncounterError: error)
            }
            .store(in: &self.cancellables)

        // Fetch and observe data if needed.
        query?.perform(using: controller)
    }

    // MARK: - Methods

    // Create a subscription that updates the view when the view model is updated.
    private func startObservingViewModel() {
        controller.$contact
            .context(currentValue: controller.contact, animateIf: { oldValue, _ in oldValue != nil })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                guard let self = self else { return }
                self.viewSynchronizer.updateView(self.contactView, context: context)
            }
            .store(in: &cancellables)
    }

    @objc
    private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }

    func handleResult<Success>(_ result: Result<Success, Error>, successCompletion: (_ value: Success) -> Void) {
        switch result {
        case .failure(let error):
            if delegate == nil {
                log(.error, "A contact error occurred, but no delegate was set to forward it to!", error: error)
            }
            delegate?.contactViewController(self, didEncounterError: error)
        case .success(let value): successCompletion(value)
        }
    }

    func handleThrowable<T>(method: () throws -> T, success: (T) -> Void) {
        do {
            let result = try method()
            success(result)
        } catch {
            if delegate == nil {
                log(.error, "A contact error occurred, but no delegate was set to forward it to!", error: error)
            }
            delegate?.contactViewController(self, didEncounterError: error)
        }
    }

    // MARK: - OCKContactViewDelegate

    /// Present an alert to call the contact. By default, calls the first phone number in the contact's list of phone numbers.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the call process.
    open func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateCall sender: Any?) {
        handleThrowable(method: controller.initiateCall) { url in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    /// Present the UI to message the contact. By default, the first messaging number will be used.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the messaging process.
    open func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateMessage sender: Any?) {
        handleThrowable(method: controller.initiateMessage) { [weak self] viewController in
            guard let self = self else { return }
            viewController.messageComposeDelegate = self
            self.present(viewController, animated: true, completion: nil)
        }
    }

    /// Present the UI to email the contact. By default, the first email address will be used.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the email process.
    open func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateEmail sender: Any?) {
        handleThrowable(method: controller.initiateEmail) { [weak self] viewController in
            guard let self = self else { return }
            viewController.mailComposeDelegate = self
            self.present(viewController, animated: true, completion: nil)
        }
    }

    /// Present a map with a marker on the contact's address.
    /// - Parameter contactView: The view that displays the contact.
    /// - Parameter sender: The sender that is initiating the address lookup process.
    open func contactView(_ contactView: UIView & OCKContactDisplayable, senderDidInitiateAddressLookup sender: Any?) {
        controller.initiateAddressLookup { [weak self] result in
            self?.handleResult(result) { mapItem in
                mapItem.openInMaps(launchOptions: nil)
            }
        }
    }

    open func didSelectContactView(_ contactView: UIView & OCKContactDisplayable) {
        handleThrowable(method: controller.initiateSystemContactLookup) { [weak self] contactViewController in
            contactViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self,
                                                                                      action: #selector(dismissViewController))
            let navigationController = UINavigationController(rootViewController: contactViewController)
            present(navigationController, animated: true, completion: nil)
        }
    }

    // MARK: - MFMessageComposeViewControllerDelegate

    open func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: - MFMailComposeViewControllerDelegate

    open func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

#endif

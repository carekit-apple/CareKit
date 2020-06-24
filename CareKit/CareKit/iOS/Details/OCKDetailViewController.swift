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
#if !os(watchOS)

import CareKitUI
import UIKit

/// A view controller that can be customized to display the details of another view.
/// The detail view's content stack view can be populated with arbitrary content.
open class OCKDetailViewController: UIViewController {

    private let html: OCKDetailView.StyledHTML?
    private let imageOverlayStyle: UIUserInterfaceStyle
    private let showsCloseButton: Bool

    /// A detailed content view.
    public private(set) lazy var detailView: OCKDetailView = {
        let view = OCKDetailView(html: html, imageOverlayStyle: imageOverlayStyle, showsCloseButton: showsCloseButton)
        view.closeButton?.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        return view
    }()

    /// Create an instance.
    /// - Parameter html: HTML to render as the `bodyLabel` text.
    /// - Parameter imageOverlayStyle: The interface style of the overlay over the image. Use `.unspecified` for no overlay.
    /// - Parameter showsCloseButton: True if the view should show a close button.
    public init(html: OCKDetailView.StyledHTML? = nil, imageOverlayStyle: UIUserInterfaceStyle = .unspecified, showsCloseButton: Bool = false) {
        self.html = html
        self.imageOverlayStyle = imageOverlayStyle
        self.showsCloseButton = showsCloseButton
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    override open func loadView() {
        view = detailView
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
    }

    @objc
    private func didTapCloseButton() {
        dismiss(animated: true)
    }
}
#endif

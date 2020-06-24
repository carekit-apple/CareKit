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

import CareKit
import CareKitUI
import Foundation
import UIKit

class FeaturedContentViewController: UIViewController, OCKFeaturedContentViewDelegate {

    static let html = """
        <p>It&#39s tough balancing a busy schedule. During the busiest of times, healthy routines are often the first things we sacrifice to \
        make more room in the day for work or family. But sacrificing healthy \
        habits will end up hurting us in the long run - They give us strength and energy to go about our day. Preparing healthy meals doesn&#39tq \
        require exotic ingredients and endless time in the kitchen.</p> \
        <br> \
        <p class="headline">Avocado Tomato Toast</p> \
        <p class="subheadline">10 minutes</p>
        <br> \
        <p>Avocados are everywhere these days, and for good reason. They&#39re incredibly filling and a great replacement for other foods that /
        are high in fat. Sprinkle on some granulated garlic and a touch of red pepper if you&#39re feeling adventurous.</p>
    """

    static let css = """
        .headline { \
            font-size: 23px; \
            font-weight: 700; \
        }

        .subheadline { \
            font-size: 15px; \
            font-weight: 300; \
        } \
        p { \
            padding: 0px; \
            margin: 0px; \
        }
    """

    private let imageOverlayStyle: UIUserInterfaceStyle

    lazy var featuredContentView: OCKFeaturedContentView = {
        let view = OCKFeaturedContentView(imageOverlayStyle: imageOverlayStyle)
        view.delegate = self
        return view
    }()

    init(imageOverlayStyle: UIUserInterfaceStyle = .unspecified) {
        self.imageOverlayStyle = imageOverlayStyle
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(*, unavailable)
    override func loadView() {
        view = featuredContentView
    }

    func didTapView(_ view: OCKFeaturedContentView) {
        let detailViewController = OCKDetailViewController(html: .init(html: Self.html, css: Self.css),
                                                           imageOverlayStyle: .unspecified, showsCloseButton: true)

        // Copy over data
        detailViewController.detailView.imageView.image = featuredContentView.imageView.image
        detailViewController.detailView.imageLabel.text = featuredContentView.label.text

        present(detailViewController, animated: true)
    }
}

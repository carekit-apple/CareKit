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

import UIKit

/// A view enclosing a scrollable stack view.
internal class OCKListView: OCKView {

    override var backgroundColor: UIColor? {
        didSet {
            contentView.backgroundColor = backgroundColor
            scrollView.backgroundColor = backgroundColor
        }
    }

    // MARK: Properties

    /// The stack view embedded inside the scroll view.
    let stackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .vertical
        return stackView
    }()

    /// The scroll view that contains the stack view.
    let scrollView = UIScrollView()

    let contentView = UIView()

    // MARK: - Life Cycle

    override init() {
        super.init()
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: Methods

    private func setup() {
        addSubviews()
        styleSubviews()
        constrainSubviews()
    }

    private func styleSubviews() {
        scrollView.alwaysBounceVertical = true
    }

    private func addSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
    }

    private func constrainSubviews() {
        [scrollView, contentView, stackView].forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ] + scrollView.constraints(equalTo: self) +
            contentView.constraints(equalTo: scrollView))
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        contentView.directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
        backgroundColor = cachedStyle.color.customGroupedBackground
        stackView.spacing = cachedStyle.dimension.directionalInsets1.top
    }
}

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

import CareKitUI
import UIKit

internal class OCKHeaderBodyView: OCKView {

    enum Constants {
        static let headerContentHeight: CGFloat = 60
        static let topMargin: CGFloat = 20
        static let margin: CGFloat = 16
    }

    // MARK: Properties

    var headerHeight: CGFloat {
        return Constants.headerContentHeight + 2 * Constants.margin
    }

    var headerInset: CGFloat {
        return headerHeight + Constants.topMargin
    }

    private let headerView: UIView
    private let bodyView: UIView

    private let headerBackgroundView: UIView = {
        let view = UIView()
        return view
    }()

    private let separatorView = OCKSeparatorView()

    // MARK: Life cycle

    init(headerView: UIView, bodyView: UIView) {
        self.headerView = headerView
        self.bodyView = bodyView
        super.init()
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    private func setup() {
        addSubviews()
        constrainSubviews()
    }

    private func addSubviews() {
        [bodyView, headerBackgroundView, separatorView, headerView].forEach { addSubview($0) }
    }

    private func constrainSubviews() {
        [headerBackgroundView, separatorView, bodyView, headerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            headerView.centerYAnchor.constraint(equalTo: headerBackgroundView.centerYAnchor),
            headerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: Constants.headerContentHeight),

            headerBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerBackgroundView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            headerBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerBackgroundView.heightAnchor.constraint(equalToConstant: headerHeight),

            separatorView.bottomAnchor.constraint(equalTo: headerBackgroundView.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: headerBackgroundView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: headerBackgroundView.trailingAnchor)
        ] + bodyView.constraints(equalTo: self))
    }

    override func styleDidChange() {
        super.styleDidChange()
        let style = self.style()
        backgroundColor = style.color.customGroupedBackground
        headerBackgroundView.backgroundColor = style.color.customGroupedBackground
        directionalLayoutMargins = style.dimension.directionalInsets1
    }
}

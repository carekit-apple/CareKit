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

open class OCKCartesianChartView: OCKView, OCKChartDisplayable {

    // MARK: Properties

    private let contentView = OCKView()

    private let headerContainerView = UIView()

    /// Handles events related to an `OCKChartDisplayable` object.
    public weak var delegate: OCKChartViewDelegate?

    /// Vertical stack view that
    public let contentStackView: OCKStackView = {
        let stackView = OCKStackView()
        stackView.axis = .vertical
        return stackView
    }()

    /// A default `OCKHeaderView`.
    public let headerView = OCKHeaderView()

    /// The main content of the view.
    public let graphView: OCKCartesianGraphView

    // MARK: - Life Cycle

    /// Create a chart with a specified type. Available charts include bar, plot, and scatter.
    ///
    /// - Parameter type: The type of the chart.
    public init(type: OCKCartesianGraphView.PlotType) {
        graphView = OCKCartesianGraphView(type: type)
        super.init()
        setup()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    override func setup() {
        super.setup()
        addSubviews()
        constrainSubviews()
        setupGestures()
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapHeader))
        headerView.addGestureRecognizer(tapGesture)
    }

    private func addSubviews() {
        addSubview(contentView)
        contentView.addSubview(contentStackView)
        headerContainerView.addSubview(headerView)
        [headerContainerView, graphView].forEach { contentStackView.addArrangedSubview($0) }
    }

    private func constrainSubviews() {

        [contentView, contentStackView, headerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let height = heightAnchor.constraint(equalToConstant: 225)
        height.priority = .defaultLow

        NSLayoutConstraint.activate(
            contentStackView.constraints(equalTo: contentView, directions: [.horizontal]) +
            contentStackView.constraints(equalTo: contentView.layoutMarginsGuide, directions: [.vertical]) +
            headerView.constraints(equalTo: headerContainerView.layoutMarginsGuide, directions: [.horizontal]) +
            headerView.constraints(equalTo: headerContainerView, directions: [.vertical]) +
            contentView.constraints(equalTo: self) +
            [height])
    }

    @objc
    private func didTapHeader() {
        delegate?.didSelectChartView(self)
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        let cardBuilder = OCKCardBuilder(cardView: self, contentView: contentView)
        cardBuilder.enableCardStyling(true, style: cachedStyle)
        contentStackView.spacing = cachedStyle.dimension.directionalInsets1.top
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
        headerContainerView.directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
    }
}

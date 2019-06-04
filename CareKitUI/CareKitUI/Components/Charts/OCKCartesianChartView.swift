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

open class OCKCartesianChartView: UIView, OCKCardable {
    
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
    
    private let headerContainerView = UIView()
    
    /// Create a chart with a specified type. Available charts include bar, plot, and scatter.
    ///
    /// - Parameter type: The type of the chart.
    public init(type: OCKCartesianGraphView.PlotType) {
        graphView = OCKCartesianGraphView(type: type)
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubviews()
        styleSubviews()
        constrainSubviews()
    }
    
    private func addSubviews() {
        addSubview(contentStackView)
        headerContainerView.addSubview(headerView)
        [headerContainerView, graphView].forEach { contentStackView.addArrangedSubview($0) }
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
        enableCardStyling(true)
        contentStackView.spacing = directionalLayoutMargins.bottom * 2
    }
    
    private func constrainSubviews() {
        [contentStackView, headerView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: directionalLayoutMargins.leading * 2),
            headerView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -directionalLayoutMargins.trailing * 2),
            headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: directionalLayoutMargins.top * 2),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -directionalLayoutMargins.bottom * 2)
        ])
    }
}

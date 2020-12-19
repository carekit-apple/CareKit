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

class OCKGridView: UIView, OCKCartesianGridProtocol {
    override class var layerClass: AnyClass {
        return OCKGridLayer.self
    }

    private let layout = OCKResponsiveLayout<CGFloat>(
        defaultLayout: 4,
        anySizeClassRuleSet: [
            .init(layout: 6, greaterThanOrEqualToContentSizeCategory: .small),
            .init(layout: 8, greaterThanOrEqualToContentSizeCategory: .medium),
            .init(layout: 10, greaterThanOrEqualToContentSizeCategory: .large),
            .init(layout: 12, greaterThanOrEqualToContentSizeCategory: .extraLarge),
            .init(layout: 14, greaterThanOrEqualToContentSizeCategory: .accessibilityMedium),
            .init(layout: 16, greaterThanOrEqualToContentSizeCategory: .accessibilityLarge),
            .init(layout: 18, greaterThanOrEqualToContentSizeCategory: .accessibilityExtraLarge)
        ]
    )

    private var gridLayer: OCKGridLayer {
        return layer as! OCKGridLayer
    }

    var numberOfDivisions: Int {
        return gridLayer.numberOfVerticalDivisions
    }

    var xMinimum: CGFloat? {
        get { return gridLayer.xMinimum }
        set { gridLayer.xMinimum = newValue }
    }

    var xMaximum: CGFloat? {
        get { return gridLayer.xMaximum }
        set { gridLayer.xMaximum = newValue }
    }

    var yMinimum: CGFloat? {
        get { return gridLayer.yMinimum }
        set { gridLayer.yMinimum = newValue }
    }

    var yMaximum: CGFloat? {
        get { return gridLayer.yMaximum }
        set { gridLayer.yMaximum = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {

        let fontSize = layout.responsiveLayoutRule(traitCollection: traitCollection)
        gridLayer.fontSize = fontSize

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let fontSize = layout.responsiveLayoutRule(traitCollection: traitCollection)
        gridLayer.fontSize = fontSize

    }
}

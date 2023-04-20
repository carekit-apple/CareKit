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
@testable import CareKitUI
import XCTest

class OCKResponsiveLayoutTests: XCTestCase {
    enum DefaultTestLayouts {
        // Completely arbitrary
        case spiral(Int), rotation(CGFloat)
    }

    enum SizeClassTestLayouts {
        case columns(Int), estimatedWidth(CGFloat), list
    }

    let defaultTestLayoutDefinition = OCKResponsiveLayout<DefaultTestLayouts>(
        defaultLayout: .spiral(3),
        anySizeClassRuleSet: [
            .init(layout: .spiral(5), greaterThanOrEqualToContentSizeCategory: .small),
            .init(layout: .rotation(90), greaterThanOrEqualToContentSizeCategory: .large)
        ]
    )

    let extraSmallTestLayoutDefinition = OCKResponsiveLayout<DefaultTestLayouts>(
        defaultLayout: .spiral(3),
        anySizeClassRuleSet: [
            .init(layout: .spiral(4), greaterThanOrEqualToContentSizeCategory: .extraSmall),
            .init(layout: .rotation(90), greaterThanOrEqualToContentSizeCategory: .large)
        ]
    )

    let undefinedTestLayoutDefinition = OCKResponsiveLayout<DefaultTestLayouts>(
        defaultLayout: .spiral(3),
        anySizeClassRuleSet: [
            .init(layout: .spiral(4), greaterThanOrEqualToContentSizeCategory: .small),
            .init(layout: .rotation(90), greaterThanOrEqualToContentSizeCategory: .large)
        ]
    )

    let sizeClassTestLayoutDefinition = OCKResponsiveLayout<SizeClassTestLayouts>(
        defaultLayout: .estimatedWidth(200),
        anySizeClassRuleSet: [
            .init(layout: .columns(3), greaterThanOrEqualToContentSizeCategory: .medium),
            .init(layout: .columns(2), greaterThanOrEqualToContentSizeCategory: .extraLarge),
            .init(layout: .list, greaterThanOrEqualToContentSizeCategory: .accessibilityMedium)
        ],

        sizeClassSpecificRuleSets: [
            // ~ iPad
            OCKResponsiveLayout.SizeClassRuleSet(
                sizeClass: (horizontal: .regular, vertical: .regular),
                rules: [
                    .init(layout: .estimatedWidth(200)),
                    .init(layout: .estimatedWidth(300), greaterThanOrEqualToContentSizeCategory: .large),
                    .init(layout: .columns(3), greaterThanOrEqualToContentSizeCategory: .extraLarge),
                    .init(layout: .list, greaterThanOrEqualToContentSizeCategory: .accessibilityLarge)
                ]
            ),

            // ~ iPhone horizontal
            OCKResponsiveLayout.SizeClassRuleSet(
                sizeClass: (horizontal: .regular, vertical: .compact),
                rules: [
                    .init(layout: .estimatedWidth(150)),
                    .init(layout: .estimatedWidth(250), greaterThanOrEqualToContentSizeCategory: .large),
                    .init(layout: .columns(4), greaterThanOrEqualToContentSizeCategory: .extraLarge),
                    .init(layout: .list, greaterThanOrEqualToContentSizeCategory: .accessibilityLarge)
                ]
            )
        ]
    )

    func testDefaultLayoutUpperContentSizeCategory() {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: .large)
        let result = defaultTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .rotation(let val): XCTAssert(val == 90)
        default: XCTFail("Result was unexpected value")
        }
    }

    func testDefaultLayoutAboveUpperContentSizeCategory() {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        let result = defaultTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .rotation(let val): XCTAssert(val == 90)
        default: XCTFail("Result was unexpected value")
        }
    }

    func testDefaultLayoutLowerContentSizeCategory() {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: .extraSmall)
        let result = defaultTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .spiral(let val): XCTAssert(val == 3)
        default: XCTFail("Result was unexpected value")
        }
    }

    func testDefaultLayoutExactContentSizeCategory() {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: .small)
        let result = defaultTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .spiral(let val): XCTAssert(val == 5)
        default: XCTFail("Result was unexpected value")
        }
    }

    func testDefaultLayoutGapBetweenContentSizeCategories() {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: .medium)
        let result = defaultTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .spiral(let val): XCTAssert(val == 5)
        default: XCTFail("Result was unexpected value")
        }
    }

    func testDefaultLayoutGapBetweenContentSizeCategoriesFailure() {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: .medium)
        let result = defaultTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .spiral(let val): XCTAssertFalse(val == 3)
        default: break
        }
    }

    func testDefaultLayoutSize() {
        let missingDefaultLayoutDefinition = OCKResponsiveLayout<DefaultTestLayouts>(
            defaultLayout: .spiral(5),
            anySizeClassRuleSet: [
                .init(layout: .spiral(6), greaterThanOrEqualToContentSizeCategory: .small),
                .init(layout: .rotation(90), greaterThanOrEqualToContentSizeCategory: .large)
            ]
        )

        let traitCollection = UITraitCollection(preferredContentSizeCategory: .medium)
        let result = missingDefaultLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .spiral(let val): XCTAssert(val == 6)
        default: XCTFail("Layout was unexpected value")
        }

        let failureTraitCollection = UITraitCollection(preferredContentSizeCategory: .extraSmall)

        switch missingDefaultLayoutDefinition.responsiveLayoutRule(traitCollection: failureTraitCollection) {
        case .spiral(let val): XCTAssert(val == 5)
        default: XCTFail("Layout was unexpected value")
        }
    }

    func testSizeClassMatch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .regular),
            UITraitCollection(preferredContentSizeCategory: .large)
        ])

        let result = sizeClassTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .estimatedWidth(let val): XCTAssert(val == 300)
        default: XCTFail("Layout was unexpected value")
        }
    }

    func testOverValueSizeClassMatch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .regular),
            UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        ])

        let result = sizeClassTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .list: break
        default: XCTFail("Layout was unexpected value")
        }
    }

    func testOtherSizeClassMatch() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(horizontalSizeClass: .regular),
            UITraitCollection(preferredContentSizeCategory: .large)
        ])

        let result = sizeClassTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .estimatedWidth(250): break
        default: XCTFail("Layout was unexpected value")
        }
    }

    func testExtraSmallOverrideDefault() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(horizontalSizeClass: .regular),
            UITraitCollection(preferredContentSizeCategory: .extraSmall)
        ])

        let result = extraSmallTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .spiral(let val): XCTAssert(val == 4)
        default: XCTFail("Layout was unexpected value")
        }
    }

    func testUndefinedDefault() {
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(horizontalSizeClass: .regular),
            UITraitCollection(preferredContentSizeCategory: .extraSmall)
        ])

        let result = undefinedTestLayoutDefinition.responsiveLayoutRule(traitCollection: traitCollection)

        switch result {
        case .spiral(let val): XCTAssert(val == 3)
        default: XCTFail("Layout was unexpected value")
        }
    }

    func testSizeClassMissingContentSizeCategory() {
        let missingSizeClassTestLayoutDefinition = OCKResponsiveLayout<SizeClassTestLayouts>(
            defaultLayout: .estimatedWidth(200),
            anySizeClassRuleSet: [],
            sizeClassSpecificRuleSets: [
                // ~ iPad
                OCKResponsiveLayout.SizeClassRuleSet(
                    sizeClass: (horizontal: .regular, vertical: .regular),
                    rules: [
                        .init(layout: .estimatedWidth(300), greaterThanOrEqualToContentSizeCategory: .large),
                        .init(layout: .columns(3), greaterThanOrEqualToContentSizeCategory: .extraLarge),
                        .init(layout: .list, greaterThanOrEqualToContentSizeCategory: .accessibilityLarge)
                    ]
                )
            ]
        )

        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .regular),
            UITraitCollection(preferredContentSizeCategory: .extraSmall)
        ])

        let result = missingSizeClassTestLayoutDefinition.responsiveLayoutRule(
            traitCollection: traitCollection
        )

        switch result {
        case .estimatedWidth(let val): XCTAssert(val == 200)
        default: XCTFail("Layout was unexpected value")
        }
    }
}
#endif

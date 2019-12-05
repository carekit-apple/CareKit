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

/// Accessible view configuration that contains layout information for different `UserInterfaceSizeClass`
/// and `UIContentSizeCategory` combinations.
public struct OCKResponsiveLayout<LayoutOption> {

    // MARK: - Instance Properties

    /// A default `SizeClassRuleSet` to apply for different `UIContentSizeCategory`'s when the
    ///  exact `UserInterfaceSizeClass` is not important.
    public let defaultRuleSet: SizeClassRuleSet<LayoutOption>

    /// A set of `UserInterfaceSizeClass` specific rule sets to provide different accessible layouts
    /// for specific size class combinations.
    public let sizeClassSpecificRuleSets: [SizeClassRuleSet<LayoutOption>]

    /// A lightweight typealias for a horizontal and vertical `UIUserInterfaceSizeClass` definition.
    ///
    /// See [Adaptivity and Layout](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/)
    /// on the Human Interface Guidelines for all possible combinations.
    public typealias SizeClass = (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass)

    // MARK: - Initializers

    /// Initialize a `OCKResponsiveLayout` with default and specific size class rules.
    ///
    /// - Parameter defaultRuleSet: The default layout rules  for when no matching size class rule is
    /// provided, usually when layouts need to support dynamic type, but not size class.
    /// - Parameter sizeClassSpecificRuleSets: Size class specific layout rule sets
    public init(
        defaultLayout: LayoutOption,
        anySizeClassRuleSet: [OCKResponsiveLayout.Rule<LayoutOption>],
        sizeClassSpecificRuleSets: [SizeClassRuleSet<LayoutOption>] = []) {

        let defaultRule = Rule(layout: defaultLayout, greaterThanOrEqualToContentSizeCategory: .unspecified)

        self.defaultRuleSet = SizeClassRuleSet<LayoutOption>(
            sizeClasses: [(horizontal: .unspecified, vertical: .unspecified)],
            rules: [defaultRule] + anySizeClassRuleSet
        )

        self.sizeClassSpecificRuleSets = sizeClassSpecificRuleSets
    }

    // MARK: - Nested Definitions

    /// A layout rule for a given `UIContentSizeCategory`.
    public struct Rule<Layout> {

        /// A selected `UIContentSizeCategory` for the given layout.
        public let contentSizeCategory: UIContentSizeCategory

        /// A provided layout to display at or above the given `UIContentSizeCategory`.
        public let layout: Layout

        /// Initialize a rule with a `Layout` defined by the user and a `UIContentSizeCategory` to display
        /// the layout at.
        /// - Parameter layout: The `Layout` to display at or above the given `UIContentSizeCategory`
        /// - Parameter contentSizeCategory: The `UIContentSizeCategory` that this layout will display at
        /// or above
        public init(
            layout: Layout,
            greaterThanOrEqualToContentSizeCategory contentSizeCategory: UIContentSizeCategory = .extraSmall
        ) {
            self.contentSizeCategory = contentSizeCategory
            self.layout = layout
        }
    }

    /// A set of `UIContentSizeCategory` specific rules for a given size class.
    public struct SizeClassRuleSet<LayoutOption> {

        /// A set of rules (combinations of `UIUserInterFaceSizeClass` combinations and user defined layouts.
        public let rules: [OCKResponsiveLayout<LayoutOption>.Rule<LayoutOption>]

        /// The valid size class combinations for this set of rules
        public let sizeClasses: [SizeClass]

        /// Initialize a `SizeClassRuleSet` with a set of `UIUserInterfaceSizeClass` combinations and
        /// `UIContentSizeCategory` specific rules.
        /// - Parameter sizeClasses: The `SizeClass` horizontal and vertical definitions for the rules
        /// - Parameter rules: The `UIContentSizeCategory` rules for these size classes
        public init(
            sizeClasses: [SizeClass],
            rules: [OCKResponsiveLayout<LayoutOption>.Rule<LayoutOption>]
        ) {
            self.sizeClasses = sizeClasses
            self.rules = rules
        }

        /// Initialize a `SizeClassRuleSet` with a `UIUserInterfaceSizeClass` combination and
        /// `UIContentSizeCategory` specific rules.
        /// - Parameter sizeClass: The `SizeClass` horizontal and vertical definition for the rules
        /// - Parameter rules: The `UIContentSizeCategory` rules for this size class
        public init(
            sizeClass: SizeClass = (horizontal: .unspecified, vertical: .unspecified),
            rules: [OCKResponsiveLayout<LayoutOption>.Rule<LayoutOption>]
        ) {
            self.init(sizeClasses: [sizeClass], rules: rules)
        }
    }

    // MARK: - Instance Methods

    /// Get a generic `LayoutOption` that has been mapped to a `UserInterfaceSizeClass` and
    /// `UIContentSizeCategory` for comparison provided by a given `UITraitCollection`.
    /// - Parameter traitCollection: The trait collection to extract device and accessility information.
    ///
    /// A UITraitCollection contains additional size and accessibility information beyond
    /// `UserInterfaceSizeClass` and `UIContentSizeCategory`. This class and method could be extended
    /// to respond to other changes beyond these two, however these are `Comparable` and provide a balance
    /// between convenient and flexibility. Consider creating additional factory methods instead of
    /// extending this method to respond to `contentSize` or `contentInsets` to maintain this convenience.
    public func responsiveLayoutRule(traitCollection: UITraitCollection) -> LayoutOption {

        func setContainsCurrentSizeClass(set: SizeClassRuleSet<LayoutOption>) -> Bool {
            return set.sizeClasses.contains { width, height -> Bool in
                return width == traitCollection.horizontalSizeClass && height == traitCollection.verticalSizeClass
            }
        }

        func largestMatchingRule(rules: [Rule<LayoutOption>]) -> Rule<LayoutOption>? {
            return rules.last { rule -> Bool in
                return rule.contentSizeCategory <= traitCollection.preferredContentSizeCategory
            }
        }

        func layoutOptionForLayoutRuleSet(set: SizeClassRuleSet<LayoutOption>) -> LayoutOption {
            let sorted = set.rules.sorted(by: { $0.contentSizeCategory < $1.contentSizeCategory })

            guard let layout =
                largestMatchingRule(rules: sorted)?.layout
                ?? largestMatchingRule(rules: self.defaultRuleSet.rules)?.layout else {
                        fatalError(
                            """
                            A layout could not be determined which should be impossible due to `defaultLayout: LayoutOption` in the
                            OCKResponsiveLayout class being non-optional.
                            """
                        )
            }

            return layout
        }

        let ruleSet = self.sizeClassSpecificRuleSets
            .first(where: { setContainsCurrentSizeClass(set: $0) })
            ?? defaultRuleSet

        return layoutOptionForLayoutRuleSet(set: ruleSet)

    }
}

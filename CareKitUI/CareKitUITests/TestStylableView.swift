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

@testable import CareKitUI
import XCTest

private class MockStylableView: OCKView {
    override func styleDidChange() {
        super.styleDidChange()
        layer.cornerRadius = style().appearance.cornerRadius1
    }
}

private class MockOverridingView: OCKView {
    static let cornerRadius: CGFloat = 2

    override func styleDidChange() {
        super.styleDidChange()
        subviews.forEach { $0.layer.cornerRadius = MockOverridingView.cornerRadius }
    }
}

private struct MockAppearanceStyle: OCKAppearanceStyler {
    var cornerRadius1: CGFloat { 1 }
}

private struct MockStyle: OCKStyler {
    var appearance: OCKAppearanceStyler { MockAppearanceStyle() }
}

class TestStylableView: XCTestCase {
    private let defaultStyle = OCKStyle()
    private let customStyle = MockStyle()

    // Default style should exist on init
    func testDefaultStyle() {
        let view = MockStylableView()
        XCTAssertNotNil(view.layer.cornerRadius)
        XCTAssertEqual(view.layer.cornerRadius, defaultStyle.appearance.cornerRadius1)
    }

    // Custom style should exist when set
    func testCustomStyle() {
        let view = MockStylableView()
        view.customStyle = customStyle
        XCTAssertNotNil(view.layer.cornerRadius)
        XCTAssertEqual(view.layer.cornerRadius, customStyle.appearance.cornerRadius1)
    }

    // Custom style can be reset to the default style
    func testClearCustomStyle() {
        let view = MockStylableView()
        view.customStyle = customStyle
        view.customStyle = nil
        XCTAssertNotNil(view.layer.cornerRadius)
        XCTAssertEqual(view.layer.cornerRadius, defaultStyle.appearance.cornerRadius1)
    }

    // default style should pass linearly through subviews
    func testDefaultLinearInheritance() {
        let views = (0..<3).map { _ in MockStylableView() }
        views[0].addSubview(views[1])
        views[1].addSubview(views[2])

        views.enumerated().forEach {
            let message = "Failed for view at index \($0)"
            XCTAssertNotNil($1.layer.cornerRadius, message)
            XCTAssertEqual($1.layer.cornerRadius, defaultStyle.appearance.cornerRadius1, message)
        }
    }

    // Custom style should pass linearly through subviews
    func testCustomLinearInheritance() {
        // On the first iteration, set the style then embed the view. On the second, embed the view then set the style
        for iteration in (0..<2) {
            let views = (0..<3).map { _ in MockStylableView() }
            if iteration == 0 { views[0].customStyle = customStyle }
            views[0].addSubview(views[1])
            views[1].addSubview(views[2])
            if iteration == 1 { views[0].customStyle = customStyle }

            views.enumerated().forEach {
                let message = "Failed for view at index \($0), iteration: \(iteration)"
                XCTAssertNotNil($1.layer.cornerRadius, message)
                XCTAssertEqual($1.layer.cornerRadius, customStyle.appearance.cornerRadius1, message)
            }
        }
    }

    // Custom style should pass linearly through subviews of the view whose custom style was set, without affecting its parents
    func testCustomLinearNonInheritance() {
        // On the first iteration, set the style then embed the view. On the second, embed the view then set the style
        for iteration in (0..<2) {
            let views = (0..<3).map { _ in MockStylableView() }
            if iteration == 0 { views[1].customStyle = customStyle }
            views[0].addSubview(views[1])
            views[1].addSubview(views[2])
            if iteration == 1 { views[1].customStyle = customStyle }

            views.enumerated().forEach {
                let style: OCKStyler = $0 == 0 ? defaultStyle : customStyle
                let message = "Failed for view at index \($0), iteration: \(iteration)"
                XCTAssertNotNil($1.layer.cornerRadius, message)
                XCTAssertEqual($1.layer.cornerRadius, style.appearance.cornerRadius1, message)
            }
        }
    }

    // Custom style should switch back to default when a custom styled view is removed from a view hierarchy
    func testCustomLinearRemoval() {
        // On the first iteration, set the style then embed the view. On the second, embed the view then set the style
        for iteration in (0..<2) {
            let views = (0..<3).map { _ in MockStylableView() }
            if iteration == 0 { views[0].customStyle = customStyle }
            views[0].addSubview(views[1])
            views[1].addSubview(views[2])
            if iteration == 1 { views[0].customStyle = customStyle }
            views[1].removeFromSuperview()

            views.enumerated().forEach {
                let style: OCKStyler = $0 == 0 ? customStyle : defaultStyle
                let message = "Failed for view at index \($0), iteration: \(iteration)"
                XCTAssertNotNil($1.layer.cornerRadius, message)
                XCTAssertEqual($1.layer.cornerRadius, style.appearance.cornerRadius1, message)
            }
        }
    }

    // Custom style should propogate through view that has two children
    func testCustomBranchingInheritance() {
        // On the first iteration, set the style then embed the view. On the second, embed the view then set the style
        for iteration in (0..<2) {
            let views = (0..<3).map { _ in MockStylableView() }
            if iteration == 0 { views[0].customStyle = customStyle }
            views[0].addSubview(views[1])
            views[0].addSubview(views[2])
            if iteration == 1 { views[0].customStyle = customStyle }

            views.enumerated().forEach {
                let message = "Failed for view at index \($0), iteration: \(iteration)"
                XCTAssertNotNil($1.layer.cornerRadius, message)
                XCTAssertEqual($1.layer.cornerRadius, customStyle.appearance.cornerRadius1, message)
            }
        }
    }

    // View with multiple children should have default style when one child is custom styled
    func testCustomBranchingNonInheritance() {
        // On the first iteration, set the style then embed the view. On the second, embed the view then set the style
        for iteration in (0..<2) {
            let views = (0..<3).map { _ in MockStylableView() }
            if iteration == 0 { views[1].customStyle = customStyle }
            views[0].addSubview(views[1])
            views[0].addSubview(views[2])
            if iteration == 1 { views[1].customStyle = customStyle }

            views.enumerated().forEach {
                let style: OCKStyler = $0 == 1 ? customStyle : defaultStyle
                let message = "Failed for view at index \($0), iteration: \(iteration)"
                XCTAssertNotNil($1.layer.cornerRadius, message)
                XCTAssertEqual($1.layer.cornerRadius, style.appearance.cornerRadius1, message)
            }
        }
    }

    // The `styleDidChange` method should be called from the inside out with respect to the view hierarchy
    func testOverridingInnerStyle() {
        let outerView = MockOverridingView()
        let innerView = MockStylableView()
        outerView.addSubview(innerView)
        outerView.customStyle = customStyle
        XCTAssertNotNil(innerView.layer.cornerRadius)
        XCTAssertEqual(innerView.layer.cornerRadius, MockOverridingView.cornerRadius)
    }
}

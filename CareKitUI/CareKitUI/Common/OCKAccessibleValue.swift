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

/// A value that scales with the current content size category.
struct OCKAccessibleValue<Container> {

    /// The value before scaling for the content size category.
    internal private(set) var rawValue: CGFloat {
        didSet { apply() }
    }

    /// The value after scaling for the content size category.
    var scaledValue: CGFloat { return rawValue.scaled() }

    private var keyPath: KeyPath<Container, CGFloat>
    private let applyScaledValue: (_ scaledValue: CGFloat) -> Void

    init(container: Container, keyPath: KeyPath<Container, CGFloat>, apply: @escaping (_ scaledValue: CGFloat) -> Void) {
        self.keyPath = keyPath
        rawValue = container[keyPath: keyPath]
        self.applyScaledValue = apply
    }

    /// Update the raw value with a new container. Will use the existing keypath to set the raw value.
    mutating func update(withContainer container: Container) {
        rawValue = container[keyPath: keyPath]
    }

    /// Update the raw value with a new container and keypath to access the raw value.
    mutating func update(withContainer container: Container, keyPath: KeyPath<Container, CGFloat>) {
        self.keyPath = keyPath
        rawValue = container[keyPath: keyPath]
    }

    /// Apply the scaled value.
    func apply() {
        self.applyScaledValue(scaledValue)
    }
}

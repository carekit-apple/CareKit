//
//  OCKSlider.swift
//
//
//  Created by Dylan Li on 8/03/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import SwiftUI

/// The style of an OCK Slider.
public enum OCKSliderStyle {
    
    /// An OCKSlider style with a bar shaped body and tick marks. The dimensions of the slider  are determined by an instance of OCKSliderDimensions.
    ///
    /// ```
    ///      |      ,      ,      ,      ,      |
    ///      +––––––––––––––––––––––––––––––––––+
    ///     |                                    |
    ///     |                                    |
    ///      +––––––––––––––––––––––––––––––––––+
    ///      |      '      '      '      '      |
    /// ```
    case filler(OCKSliderDimensions)
    
    /// An OCK Slider that uses the body of a system slider.
    case system
}

/// The dimensions that determine the size and frame of an OCKSlider with a filler style
public struct OCKSliderDimensions {
    let sliderHeight: CGFloat
    let frameHeightMultiplier: CGFloat
    
    /// Create an instance
    /// - Parameter sliderHeight: Height of the bar of the slider.  Default value is 40.
    /// - Parameter frameHeightMultiplier: Value to multiply the slider height by to attain the hieght of the frame enclosing the slider. Default value is 1.7.
    public init(sliderHeight: CGFloat = 40, frameHeightMultiplier: CGFloat = 1.7) {
        self.sliderHeight = sliderHeight
        self.frameHeightMultiplier = frameHeightMultiplier
    }
}

#endif

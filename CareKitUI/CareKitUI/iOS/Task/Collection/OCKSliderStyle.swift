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
    case CareKitSlider(OCKSliderDimensions)
    
    /// An OCK Slider that uses the body of a system slider.
    case UISlider
}

/// The dimensions that determine the size and frame of an OCKSlider with a filler style
public struct OCKSliderDimensions {
    let height: CGFloat
    let cornerRadius: CGFloat?
    
    /// Create an instance
    /// - Parameter sliderHeight: Height of the bar of the slider.  Default value is 40.
    /// - Parameter cornerRadius: Radius of the rounded corners of the slider. The default value is determined as a fraction of the slider height.
    public init(height: CGFloat = 40, cornerRadius: CGFloat? = nil) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
}

#endif

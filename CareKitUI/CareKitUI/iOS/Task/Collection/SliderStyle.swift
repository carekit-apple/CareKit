//
//  SliderStyle.swift
//
//
//  Created by Dylan Li on 8/03/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

#if !os(watchOS)

import SwiftUI

/// The style of a CareKit Slider.
public enum SliderStyle {
    
    /// An OCKSlider style with a bar shaped body. The dimensions of the slider  are determined by an instance of OCKSliderDimensions.
    ///
    /// ```
    ///      +–––––––––––––––––––––––––––––––+
    ///     |   |    |    |    |    |    |    |
    ///     |   |    |    |    |    |    |    |
    ///      +–––––––––––––––––––––––––––––––+
    /// ```
    case ticked
    
    /// A CareKit Slider that uses the body of a system slider.
    case system
}

#endif

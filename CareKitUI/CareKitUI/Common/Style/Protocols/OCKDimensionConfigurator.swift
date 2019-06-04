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

/// A configurator that defines constants view sizes.
public protocol OCKDimensionConfigurator {
    var separatorHeight: CGFloat { get }
    var completionRingLineWidth: CGFloat { get }
    var checkViewLineWidth: CGFloat { get }
    var imageHeight1: CGFloat { get }
    var stackSpacing1: CGFloat { get }
    
    var buttonHeight3: CGFloat { get }
    var buttonHeight2: CGFloat { get }
    var buttonHeight1: CGFloat { get }
    
    var iconHeight5: CGFloat { get }
    var iconHeight4: CGFloat { get }
    var iconHeight3: CGFloat { get }
    var iconHeight2: CGFloat { get }
    var iconHeight1: CGFloat { get }
    
    var linePlotDefaultMarkerSize: CGFloat { get }
    var barPlotDefaultMarkerSize: CGFloat { get }
    var scatterPlotDefaultMarkerSize: CGFloat { get }
}

public extension OCKDimensionConfigurator {
    var separatorHeight: CGFloat { return 1 }
    var completionRingLineWidth: CGFloat { return 4 }
    var checkViewLineWidth: CGFloat { return 3 }
    var imageHeight1: CGFloat { return 150 }
    var stackSpacing1: CGFloat { return 8 }
    
    var buttonHeight3: CGFloat { return 20 }
    var buttonHeight2: CGFloat { return 40 }
    var buttonHeight1: CGFloat { return 60 }
    
    var iconHeight5: CGFloat { return 8 }
    var iconHeight4: CGFloat { return 14 }
    var iconHeight3: CGFloat { return 18 }
    var iconHeight2: CGFloat { return 25 }
    var iconHeight1: CGFloat { return 40 }
    
    var linePlotDefaultMarkerSize: CGFloat { return 3 }
    var barPlotDefaultMarkerSize: CGFloat { return 12 }
    var scatterPlotDefaultMarkerSize: CGFloat { return 5 }
}

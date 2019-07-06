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

internal extension UIFont {
    
    static let fontSizesTable: [TextStyle: [UIContentSizeCategory: CGFloat]] = [
        .headline: OCKStyle.font.headlineFontSizes,
        .callout: OCKStyle.font.calloutFontSizes,
        .caption1: OCKStyle.font.caption1FontSizes,
        .caption2: OCKStyle.font.caption2FontSizes,
        .footnote: OCKStyle.font.footnoteFontSizes,
        .largeTitle: OCKStyle.font.largeTitleFontSizes,
        .subheadline: OCKStyle.font.subheadlineFontSizes,
        .title1: OCKStyle.font.title1FontSizes,
        .title2: OCKStyle.font.title2FontSizes,
        .title3: OCKStyle.font.title3FontSizes
    ]
    
    static func preferredCustomFont(forTextStyle textStyle: TextStyle, weight: Weight) -> UIFont {
        let sizeCategory = UIApplication.shared.preferredContentSizeCategory
        let customPointSize = fontSizesTable[textStyle]?[sizeCategory]  // framework/developer defined point size
        let defaultDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        let size = customPointSize ?? defaultDescriptor.pointSize
        let fontDescriptor = UIFontDescriptor(fontAttributes: [
            UIFontDescriptor.AttributeName.size: size,
            UIFontDescriptor.AttributeName.family: UIFont.systemFont(ofSize: size).familyName
        ])
        
        // add the font weight too the descriptor
        let weightedFontDescriptor = fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weight
            ]
        ])
        return UIFont(descriptor: weightedFontDescriptor, size: 0)
    }
}

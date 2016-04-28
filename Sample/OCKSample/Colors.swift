/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
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

enum Colors {
    
    case Red, Green, Blue, LightBlue, Pink, Purple, Yellow
    
    var color: UIColor {
        switch self {
            case .Red:
                return UIColor(red: 0xEF / 255.0, green: 0x44 / 255.0, blue: 0x5B / 255.0, alpha: 1.0)
                
            case .Green:
                return UIColor(red: 0x8D / 255.0, green: 0xC6 / 255.0, blue: 0x3F / 255.0, alpha: 1.0)
                
            case .Blue:
                return UIColor(red: 0x3E / 255.0, green: 0xA1 / 255.0, blue: 0xEE / 255.0, alpha: 1.0)
                
            case .LightBlue:
                return UIColor(red: 0x9C / 255.0, green: 0xCF / 255.0, blue: 0xF8 / 255.0, alpha: 1.0)
                
            case .Pink:
                return UIColor(red: 0xF2 / 255.0, green: 0x6D / 255.0, blue: 0x7D / 255.0, alpha: 1.0)
                
            case .Purple:
                return UIColor(red: 0x9B / 255.0, green: 0x59 / 255.0, blue: 0xB6 / 255.0, alpha: 1.0)
            
            case .Yellow:
                return UIColor(red: 0xF1 / 255.0, green: 0xDF / 255.0, blue: 0x15 / 255.0, alpha: 1.0)
        }
    }
}

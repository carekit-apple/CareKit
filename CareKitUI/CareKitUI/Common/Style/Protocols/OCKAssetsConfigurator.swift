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

/// A configurator that defines constants for asset names.
public protocol OCKAssetsConfigurator {
    var arrow: String { get }
    var badge: String { get }
    var calendar: String { get }
    var care: String { get }
    var check: String { get }
    var checkSmall: String { get }
    var email: String { get }
    var exercise: String { get }
    var food: String { get }
    var hcProvider: String { get }
    var heart: String { get }
    var insights: String { get }
    var location: String { get }
    var meditate: String { get }
    var meds: String { get }
    var messages: String { get }
    var phone: String { get }
    var profile: String { get }
    var respiration: String { get }
    var sports: String { get }
    var webLink: String { get }
    var clock: String { get }
}

public extension OCKAssetsConfigurator {
    var arrow: String { "Arrow" }
    var badge: String { "Badge" }
    var calendar: String { "Calendar" }
    var care: String { "Care" }
    var check: String { "Check" }
    var checkSmall: String { "CheckSmall" }
    var email: String { "Email" }
    var exercise: String { "Exercise" }
    var food: String { "Food" }
    var hcProvider: String { "HCProvider" }
    var heart: String { "Heart" }
    var insights: String { "Insights" }
    var location: String { "Location" }
    var meditate: String { "Meditate" }
    var meds: String { "Meds" }
    var messages: String { "Messages" }
    var phone: String { "Phone" }
    var profile: String { "Profile" }
    var respiration: String { "Respiration" }
    var sports: String { "Sports" }
    var webLink: String { "WebLink" }
    var clock: String { "Clock" }
}

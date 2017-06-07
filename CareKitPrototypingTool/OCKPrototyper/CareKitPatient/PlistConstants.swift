/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


import Foundation


struct PlistConstants {
    struct Root {
        static let patient = "Patient Info"
        static let activities = "Care Contents"
        static let insight = "Insights"
        static let connect = "Contacts"
        static let viewControllerCustomization = "UI Customization"
    }
    
    struct Customization {
        static let careContent = "careContentUI"
        static let insights = "insightsUI"
        static let connect = "connectUI"
        
        struct Keys {
            static let title = "title"
            static let image = "image"
            static let selectedImage = "selectedImage"
        }
        struct CareContentUI {
            static let glyphType = "glyphType"
            static let glyphTintColor = "glyphTintColor"
            static let readOnlyHeader = "readOnlyHeader"
            static let optionalHeader = "optionalHeader"
        }
    }
    
    struct PatientInfo {
        struct Keys {
            static let identifier = "identifier"
            static let name = "name"
            static let detailInfo = "detailInfo"
            static let tintColor = "tintColor"
            static let monogram = "monogram"
            static let image = "image"
        }
    }
    
    struct Activity {
        struct Keys {
            static let type = "type"
            static let identifier = "identifier"
            static let groupIdentifier = "groupIdentifier"
            static let title = "title"
            static let text = "text"
            static let tintColor = "tintColor"
            static let instructions = "instructions"
            static let imageURL = "imageURL"
            static let optional = "optional"
            static let schedule = "schedule"
            static let thresholds = "thresholds"
            static let resettable = "resultResettable"
        }
        struct Schedule {
            static let startDate = "activityStartDate"
            static let endDate = "activityEndDate"
            static let occurences = "occurencesOnEachDay"
            static let weeksToSkip = "weeksToSkip"
            struct StartDate {
                static let month = "mm"
                static let day = "dd"
                static let year = "yyyy"
            }
            struct EndDate {
                static let month = "mm"
                static let day = "dd"
                static let year = "yyyy"
            }
        }
        struct Thresholds {
            static let value = "value"
            static let type = "type"
            static let upperValue = "upperValue"
            static let title = "title"
        }
    }
    
    struct Insights {
        static let message = "message"
        static let widgets = "patientWidgets"
        static let charts = "charts"
        static let rings = "rings"
        struct Message {
            static let title = "title"
            static let text = "text"
            static let tintColor = "tintColor"
            static let type = "type"
        }
        struct Widgets {
            static let title = "title"
            static let text = "text"
            static let tintColor = "tintColor"
        }
        struct Charts {
            static let numberOfCharts = "numberOfCharts"
            static let numberOfSeries = "numberOfSeries"
            static let numberOfSets = "numberOfSets"
            static let minimumScaleRange = "miminumScaleRange"
            static let maximumScaleRange = "maximumScaleRange"
        }
        struct Rings {
            static let title = "title"
            static let text = "text"
            static let tintColor = "tintColor"
            static let value = "value"
            static let glyphType = "glyphType"
        }
    }
    
    struct Contacts {
        static let type = "type"
        static let name = "name"
        static let relation = "relation"
        static let contactInfoItems = "contactInfoItems"
        static let tintColor = "tintColor"
        static let monogram = "monogram"
        static let image = "image"
        struct ContactInfoItems {
            static let phone = "phone"
            static let email = "email"
            static let sms = "sms"
            static let facetimeAudio = "facetimeAudio"
            static let facetimeVideo = "facetimeVideo"
        }
    }
    
    
}


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

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler(CLKComplicationTimeTravelDirections())
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.hideOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping((CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        let template = getTemplate(forCompletionPercentage: getCurrentCompletionPercentage(), complication: complication)
        if template != nil {
            handler(CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template!))
        } else {
            handler(nil)
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(getTemplate(forCompletionPercentage: nil, complication: complication))
    }
    
    
    // MARK: Rendering Templates
    
    func getTemplate(forCompletionPercentage completionPercentage : Int?, complication : CLKComplication) -> CLKComplicationTemplate? {
        var textToDisplay : String
        if completionPercentage == nil || completionPercentage == -1 {
            // completionPercentage of -1 indicates request for nil to be displayed by InterfaceController
            textToDisplay = "--%"
        } else {
            textToDisplay = "\(completionPercentage!)%"
        }
        
        
        switch complication.family {
        case .modularLarge:
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Care Completion")
            template.tintColor = InterfaceController.watchTintColor
            template.body1TextProvider = CLKSimpleTextProvider(text: textToDisplay)
            
            if completionPercentage != nil && completionPercentage != -1 {
                let eventsRemaining = getEventsRemaining()
                switch eventsRemaining {
                case 0:
                    template.body2TextProvider = CLKSimpleTextProvider(text: "Care Plan complete")
                case 1:
                    template.body2TextProvider = CLKSimpleTextProvider(text: "1 event remaining")
                default:
                    template.body2TextProvider = CLKSimpleTextProvider(text: "\(getEventsRemaining()) events remaining")
                }
            }
            
            return template
            
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallStackImage()
            template.line1ImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Modular")!)
            template.line2TextProvider = CLKSimpleTextProvider(text: textToDisplay)
            template.tintColor = InterfaceController.watchTintColor
            return template
            
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.textProvider = CLKSimpleTextProvider(text: textToDisplay)
            template.tintColor = InterfaceController.watchTintColor
            return template
            
        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            if completionPercentage == nil && completionPercentage != -1 {
                template.textProvider = CLKSimpleTextProvider(text: "Care Plan")
            } else {
                switch completionPercentage! {
                case 100:
                    template.textProvider = CLKSimpleTextProvider(text: "Care Complete")
                default:
                    template.textProvider = CLKSimpleTextProvider(text: "Care Plan: " + textToDisplay)
                }
            }
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.tintColor = InterfaceController.watchTintColor
            return template
            
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallStackImage()
            template.line1ImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!)
            template.line2TextProvider = CLKSimpleTextProvider(text: textToDisplay)
            template.tintColor = InterfaceController.watchTintColor
            return template
            
        case .extraLarge:
            let template = CLKComplicationTemplateExtraLargeStackImage()
            template.line1ImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/X-Large")!)
            template.line2TextProvider = CLKSimpleTextProvider(text: textToDisplay)
            template.tintColor = InterfaceController.watchTintColor
            template.highlightLine2 = false
            return template
            
        default:
            return nil
        }
    }
    
    // MARK: Updates
    
    func getCurrentCompletionPercentage() -> Int {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: "currentCompletionPercentage")
    }
    
    func getEventsRemaining() -> Int {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: "eventsRemaining")
    }
    
}

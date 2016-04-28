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

import CareKit

class BuildInsightsOperation: NSOperation {
    
    // MARK: Properties
    
    var medicationEvents: DailyEvents?
    
    var backPainEvents: DailyEvents?
    
    private(set) var insights = [OCKInsightItem.emptyInsightsMessage()]
    
    // MARK: NSOperation
    
    override func main() {
        // Do nothing if the operation has been cancelled.
        guard !cancelled else { return }
        
        // Create an array of insights.
        var newInsights = [OCKInsightItem]()
        
        if let insight = createMedicationAdherenceInsight() {
            newInsights.append(insight)
        }
        
        if let insight = createBackPainInsight() {
            newInsights.append(insight)
        }
        
        // Store any new insights thate were created.
        if !newInsights.isEmpty {
            insights = newInsights
        }
    }
    
    // MARK: Convenience
    
    func createMedicationAdherenceInsight() -> OCKInsightItem? {
        // Make sure there are events to parse.
        guard let medicationEvents = medicationEvents else { return nil }
        
        // Determine the start date for the previous week.
        let calendar = NSCalendar.currentCalendar()
        let now = NSDate()
        
        let components = NSDateComponents()
        components.day = -7
        let startDate = calendar.weekDatesForDate(calendar.dateByAddingComponents(components, toDate: now, options: [])!).start
        
        var totalEventCount = 0
        var completedEventCount = 0
        
        for offset in 0..<7 {
            components.day = offset
            let dayDate = calendar.dateByAddingComponents(components, toDate: startDate, options: [])!
            let dayComponents = NSDateComponents(date: dayDate, calendar: calendar)
            let eventsForDay = medicationEvents[dayComponents]
            
            totalEventCount += eventsForDay.count
            
            for event in eventsForDay {
                if event.state == .Completed {
                    completedEventCount += 1
                }
            }
        }
        
        guard totalEventCount > 0 else { return nil }
        
        // Calculate the percentage of completed events.
        let medicationAdherence = Float(completedEventCount) / Float(totalEventCount)
        
        // Create an `OCKMessageItem` describing medical adherence.
        let percentageFormatter = NSNumberFormatter()
        percentageFormatter.numberStyle = .PercentStyle
        let formattedAdherence = percentageFormatter.stringFromNumber(medicationAdherence)!

        let insight = OCKMessageItem(title: "Medication Adherence", text: "Your medication adherence was \(formattedAdherence) last week.", tintColor: Colors.Pink.color, messageType: .Tip)
        
        return insight
    }
    
    func createBackPainInsight() -> OCKInsightItem? {
        // Make sure there are events to parse.
        guard let medicationEvents = medicationEvents, backPainEvents = backPainEvents else { return nil }
        
        // Determine the date to start pain/medication comparisons from.
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = -7
        
        let startDate = calendar.dateByAddingComponents(components, toDate: NSDate(), options: [])!

        // Create formatters for the data.
        let dayOfWeekFormatter = NSDateFormatter()
        dayOfWeekFormatter.dateFormat = "E"
        
        let shortDateFormatter = NSDateFormatter()
        shortDateFormatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("Md", options: 0, locale: shortDateFormatter.locale)

        let percentageFormatter = NSNumberFormatter()
        percentageFormatter.numberStyle = .PercentStyle

        /*
            Loop through 7 days, collecting medication adherance and pain scores
            for each.
        */
        var medicationValues = [Float]()
        var medicationLabels = [String]()
        var painValues = [Int]()
        var painLabels = [String]()
        var axisTitles = [String]()
        var axisSubtitles = [String]()
        
        for offset in 0..<7 {
            // Determine the day to components.
            components.day = offset
            let dayDate = calendar.dateByAddingComponents(components, toDate: startDate, options: [])!
            let dayComponents = NSDateComponents(date: dayDate, calendar: calendar)
            
            // Store the pain result for the current day.
            if let result = backPainEvents[dayComponents].first?.result, score = Int(result.valueString) where score > 0 {
                painValues.append(score)
                painLabels.append(result.valueString)
            }
            else {
                painValues.append(0)
                painLabels.append(NSLocalizedString("N/A", comment: ""))
            }
            
            // Store the medication adherance value for the current day.
            let medicationEventsForDay = medicationEvents[dayComponents]
            if let adherence = percentageEventsCompleted(medicationEventsForDay) where adherence > 0.0 {
                // Scale the adherance to the same 0-10 scale as pain values.
                let scaledAdeherence = adherence * 10.0
                
                medicationValues.append(scaledAdeherence)
                medicationLabels.append(percentageFormatter.stringFromNumber(adherence)!)
            }
            else {
                medicationValues.append(0.0)
                medicationLabels.append(NSLocalizedString("N/A", comment: ""))
            }
            
            axisTitles.append(dayOfWeekFormatter.stringFromDate(dayDate))
            axisSubtitles.append(shortDateFormatter.stringFromDate(dayDate))
        }

        // Create a `OCKBarSeries` for each set of data.
        let painBarSeries = OCKBarSeries(title: "Pain", values: painValues, valueLabels: painLabels, tintColor: Colors.Blue.color)
        let medicationBarSeries = OCKBarSeries(title: "Medication Adherence", values: medicationValues, valueLabels: medicationLabels, tintColor: Colors.LightBlue.color)

        /*
            Add the series to a chart, specifing the scale to use for the chart
            rather than having CareKit scale the bars to fit.
        */
        let chart = OCKBarChart(title: "Back Pain",
                                text: nil,
                                tintColor: Colors.Blue.color,
                                axisTitles: axisTitles,
                                axisSubtitles: axisSubtitles,
                                dataSeries: [painBarSeries, medicationBarSeries],
                                minimumScaleRangeValue: 0,
                                maximumScaleRangeValue: 10)
        
        return chart
    }
    
    /**
        For a given array of `OCKCarePlanEvent`s, returns the percentage that are
        marked as completed.
    */
    private func percentageEventsCompleted(events: [OCKCarePlanEvent]) -> Float? {
        guard !events.isEmpty else { return nil }
        
        let completedCount = events.filter({ event in
            event.state == .Completed
        }).count
     
        return Float(completedCount) / Float(events.count)
    }
}

/**
 An extension to `SequenceType` whose elements are `OCKCarePlanEvent`s. The
 extension adds a method to return the first element that matches the day
 specified by the supplied `NSDateComponents`.
 */
extension SequenceType where Generator.Element: OCKCarePlanEvent {
    
    func eventForDay(dayComponents: NSDateComponents) -> Generator.Element? {
        for event in self where
                event.date.year == dayComponents.year &&
                event.date.month == dayComponents.month &&
                event.date.day == dayComponents.day {
            return event
        }
        
        return nil
    }
}

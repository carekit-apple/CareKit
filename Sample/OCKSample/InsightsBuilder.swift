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

class InsightsBuilder {
    
    /// An array if `OCKInsightItem` to show on the Insights view.
    fileprivate(set) var insights = [OCKInsightItem.emptyInsightsMessage()]
    
    fileprivate let carePlanStore: OCKCarePlanStore
    
    fileprivate let updateOperationQueue = OperationQueue()
    
    required init(carePlanStore: OCKCarePlanStore) {
        self.carePlanStore = carePlanStore
    }

    /**
        Enqueues `NSOperation`s to query the `OCKCarePlanStore` and update the
        `insights` property.
    */
    func updateInsights(_ completion: ((Bool, [OCKInsightItem]?) -> Void)?) {
        // Cancel any in-progress operations. 
        updateOperationQueue.cancelAllOperations()

        // Get the dates the current and previous weeks.
        let queryDateRange = calculateQueryDateRange()
        
        /*
            Create an operation to query for events for the previous week's
            `TakeMedication` activity.
         */
        
        let medicationEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                     activityIdentifier: ActivityType.takeMedication.rawValue,
                                                                     startDate: queryDateRange.start,
                                                                     endDate: queryDateRange.end)
        
        /*
         Create an operation to query for events for the previous week's
         `HamstringStretch` activity.
         */
        
        let hamstringStretchEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                           activityIdentifier: ActivityType.hamstringStretch.rawValue,
                                                                           startDate: queryDateRange.start,
                                                                           endDate: queryDateRange.end)
        
        /*
         Create an operation to query for events for the previous week's
         `OutdoorWalk` activity.
         */
        
        let outdoorWalkEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                      activityIdentifier: ActivityType.outdoorWalk.rawValue,
                                                                      startDate: queryDateRange.start,
                                                                      endDate: queryDateRange.end)
        
        /*
         Create an operation to query for events for the previous week's
         `BloodGlucose` activity.
         */
        
        let bloodGlucoseEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                       activityIdentifier: ActivityType.bloodGlucose.rawValue,
                                                                       startDate: queryDateRange.start,
                                                                       endDate: queryDateRange.end)
        
        /*
         Create an operation to query for events for the previous week's
         `Weight` activity.
         */
        
        let weightEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                 activityIdentifier: ActivityType.weight.rawValue,
                                                                 startDate: queryDateRange.start,
                                                                 endDate: queryDateRange.end)
        
        /*
         Create an operation to query for events for the previous week's
         `Mood` activity.
         */
        
        let moodEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                               activityIdentifier: ActivityType.mood.rawValue,
                                                               startDate: queryDateRange.start,
                                                               endDate: queryDateRange.end)
        
        /*
            Create an operation to query for events for the previous week and
            current weeks' `BackPain` assessment.
         */
        
        let backPainEventsOperation = QueryActivityEventsOperation(store: carePlanStore,
                                                                   activityIdentifier: ActivityType.backPain.rawValue,
                                                                   startDate: queryDateRange.start,
                                                                   endDate: queryDateRange.end)

        /*
            Create a `BuildInsightsOperation` to create insights from the data
            collected by query operations.
        */
        let buildInsightsOperation = BuildInsightsOperation()
        
        /*
            Create an operation to aggregate the data from query operations into
            the `BuildInsightsOperation`.
        */
        let aggregateDataOperation = BlockOperation {
            // Copy the queried data from the query operations to the `BuildInsightsOperation`.
            buildInsightsOperation.medicationEvents = medicationEventsOperation.dailyEvents
            buildInsightsOperation.hamstringStretchEvents = hamstringStretchEventsOperation.dailyEvents
            buildInsightsOperation.outdoorWalkEvents = outdoorWalkEventsOperation.dailyEvents
            buildInsightsOperation.bloodGlucoseEvents = bloodGlucoseEventsOperation.dailyEvents
            buildInsightsOperation.weightEvents = weightEventsOperation.dailyEvents
            buildInsightsOperation.moodEvents = moodEventsOperation.dailyEvents
            buildInsightsOperation.backPainEvents = backPainEventsOperation.dailyEvents
        }
        
        /*
            Use the completion block of the `BuildInsightsOperation` to store the
            new insights and call the completion block passed to this method.
        */
        buildInsightsOperation.completionBlock = { [unowned buildInsightsOperation] in
            let completed = !buildInsightsOperation.isCancelled
            let newInsights = buildInsightsOperation.insights
            
            // Call the completion block on the main queue.
            OperationQueue.main.addOperation {
                if completed {
                    completion?(true, newInsights)
                }
                else {
                    completion?(false, nil)
                }
            }
        }
        
        // The aggregate operation is dependent on the query operations.
        aggregateDataOperation.addDependency(medicationEventsOperation)
        aggregateDataOperation.addDependency(hamstringStretchEventsOperation)
        aggregateDataOperation.addDependency(outdoorWalkEventsOperation)
        aggregateDataOperation.addDependency(bloodGlucoseEventsOperation)
        aggregateDataOperation.addDependency(weightEventsOperation)
        buildInsightsOperation.addDependency(moodEventsOperation)
        aggregateDataOperation.addDependency(backPainEventsOperation)
        
        // The `BuildInsightsOperation` is dependent on the aggregate operation.
        buildInsightsOperation.addDependency(aggregateDataOperation)
        
        // Add all the operations to the operation queue.
        updateOperationQueue.addOperations([
            medicationEventsOperation,
            hamstringStretchEventsOperation,
            outdoorWalkEventsOperation,
            bloodGlucoseEventsOperation,
            weightEventsOperation,
            moodEventsOperation,
            backPainEventsOperation,
            aggregateDataOperation,
            buildInsightsOperation
        ], waitUntilFinished: false)
    }
    
    fileprivate func calculateQueryDateRange() -> (start: DateComponents, end: DateComponents) {
        let calendar = Calendar.current
        let now = Date()
        
        let currentWeekRange = calendar.weekDatesForDate(now)
        let previousWeekRange = calendar.weekDatesForDate(currentWeekRange.start.addingTimeInterval(-1))
        
        let queryRangeStart = calendar.dateComponents([.year, .month, .day, .era], from: previousWeekRange.start)
        let queryRangeEnd = calendar.dateComponents([.year, .month, .day, .era], from: now)
        
        return (start: queryRangeStart, end: queryRangeEnd)
    }
}



protocol InsightsBuilderDelegate: class {
    func insightsBuilder(_ insightsBuilder: InsightsBuilder, didUpdateInsights insights: [OCKInsightItem])
}

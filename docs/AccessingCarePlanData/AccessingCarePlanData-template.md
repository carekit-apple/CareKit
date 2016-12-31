<br/>
<sub>These materials are for informational purposes only and do not constitute legal advice. You should contact an attorney to obtain advice with respect to the development of a CareKit app and any applicable laws.</sub>

# Accessing Care Plan Data

CareKit stores your treatment plan in a database. This database is located at the URL you provided when you instantiated your app's `OCKCarePlanStore` object. CareKit automatically creates the database the first time you instantiate your care plan store. For more information on instantiating your care plan store, see  [Creating the Care Card > Instantiating the Care Plan Store](../CreatingTheCareCard/CreatingTheCareCard.html#InstantiatingTheCarePlanStore).

CareKit's database is encrypted using standard file system encryption. Specifically, the database uses `NSFileProtectionComplete` encryption, which means the database is stored in an encrypted format on disk and cannot be read from or written to while the device is locked or booting.

Additionally, when working with CareKit data, you don't access this database directly. Instead, you interact with the database using your app's care plan store object. The care plan store provides methods that perform the following actions:

* Store or delete activities
* Set an activity's end date
* Read activities or events
* Update events

The Care Plan Store must be created on the main thread, but its methods can be called from any thread. All of the methods are asynchronous. They dispatch the actual work to a FIFO background queue. As soon as the work is complete, the method's completion handler is called on an anonymous background queue. You often need to dispatch these results back to the main queue before updating your app.

For more information on working with asynchronous APIs, see [Concurrency Programming Guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html).

## Activities and Events

The Care Plan Store manages two basic data types:

* `OCKCarePlanActivity` objects
* `OCKCarePlanEvent` objects

The activities represent the user's care plan, while the events represent the individual tasks that the user must perform to complete the plan. When you add an activity to the store, CareKit automatically generates the event objects associated with that activity. For example, if the activity indicates taking three doses of medication a day, CareKit generates three events for each day.

Each activity is uniquely identified by its `identifier` property. These identifiers are strings that you provide when you create the activity. You can use any string you wish, but every activity in the Care Plan Store must have a unique string.

If an activity already exists in the Care Plan Store, any attempt to add a second activity with the same identifier fails. The store returns an error object with an `OCKErrorDomain` domain and a `OCKErrorInvalidObject` error code.


Activities can also have a `groupIdentifier` property. Again, the group identifier is an arbitrary string you set when instantiating the activity; however, multiple activities can share the same group identifier. Use the group identifier to partition your activities into related groups, which lets you easily search for all the activities with a given group identifier.

## Responding to Changes in the Store

CareKit automatically updates both the Care Card and the Symptom and Measurement Tracker whenever the data in the Care Plan Store changes. If you want to update other views or controllers, you need to monitor the store yourself.

Use a delegate object to monitor changes to your app's Care Plan Store. This delegate must adopt the `OCKCarePlanStoreDelegate` protocol, which defines two optional methods:

* **`carePlanStoreActivityListDidChange()`.** This method is called whenever an activity is added or removed from the store.


* **`carePlanStore(didReceiveUpdateOfEvent:)`.** This method is called whenever an event is updated, such as when the user completes an event in their treatment plan.

As an example, if you want to update your Insights scene whenever the store data changes, implement the `carePlanStore(didReceiveUpdateOfEvent:)` method, and have it call a method that reads new data from the store and updates the Insight items, as shown below:

```swift
func carePlanStore(store: OCKCarePlanStore, didReceiveUpdateOfEvent event: OCKCarePlanEvent) {
  updateInsights()
}
```    

## Reading Data from the Store

The Care Plan Store provides methods for reading both activities and events. For activities, you can read the activity for a given identifier, all the activities for a group identifier, or even batch read all the activities in the entire treatment plan.

For example, the following sample code reads all the intervention activities currently saved in the store:

```swift
store.activitiesWithType(.Intervention) { (success, activities, errorOrNil) in
    guard success else {
        // perform proper error handling here
        fatalError(errorOrNil!.localizedDescription)
    }

    // now do something with the activities.
}
```
CareKit is somewhat more restrictive when it comes to reading events. In general, a care plan has relatively few activities, but these activities can generate an unlimited number of events. Therefore, to keep the memory footprint low, the Care Plan Store lets you read events from only a single day at a time.

For example, the following sample code reads all of today's events for the ibuprofen activity.

```swift
guard let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) else {
    fatalError("This should never fail.")
}

let today = calendar.components([.Day, .Month, .Year], fromDate: NSDate())
store.eventsForActivity(ibuprofen, date: today) { (events, errorOrNil) in

    if let error = errorOrNil {
        // Perform proper error handling here
        fatalError(error.localizedDescription)
    }

    // do something with the events.
}
```

CareKit defines dates using the `NSDateComponent` objects. Each date component object must use the Gregorian calendar and must define a valid day, month, and year component. From the user's perspective, individual days may be greater or less than 24 hours (for example, if the user is traveling). Using date components lets you uniquely specify a given date from the user's perspective, regardless of the user's current time zone or travel itinerary.

For more information on using calendars and dates, see [Date and Time Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/DatesAndTimes/DatesAndTimes.html)

To help gather data from a range of dates, the Care Plan Store provides two higher order methods that iterate over larger amounts of data.

The `dailyCompletionStatusWithType(startDate:, endDate:, handler:, completion:)` method calls its handler once for each date in the provided range of dates. However, instead of providing information about specific events, it provides a count of the number of events that the user has completed, and the total number of events for each date.

The `enumerateEventsOfActivity(startDate:, endDate:, handler:, completion:)` method calls its handler once for each event generated by the provided activity during the provided range of dates.

In both cases, the higher order method calls its completion block once all the events have been handled.

The following sample code demonstrates using these methods to collect data over a range of dates, and then combine that data.

```swift
// These variables will store the data generated by the Care Plan Store.
var completionData = [(dateComponent: NSDateComponents, value: Double)]()
var stressAssessmentData = [NSDateComponents: Double]()

dispatch_group_enter(gatherDataGroup)
store.dailyCompletionStatusWithType(
    .Intervention,
    startDate: startComponents,
    endDate: endComponents,
    handler: { (dateComponents, completed, total) in
        // This block is called once for each date.
        let percentComplete = Double(completed) / Double(total)
        completionData.append((dateComponents, percentComplete))

    },
    completion: { (success, errorOrNil) in
        // This block is called after the last date's handler returns.
        guard success else {
            // Add proper error handling here...
            fatalError(errorOrNil!.localizedDescription)
        }

        dispatch_group_leave(gatherDataGroup)
})

dispatch_group_enter(gatherDataGroup)
store.enumerateEventsOfActivity(
    stressQuestion,
    startDate: startComponents,
    endDate: endComponents,
    handler: { (eventOrNil, stop) in
        // This block is called once for each event
        if let event = eventOrNil,
            result = event.result,
            value = Double(result.valueString) {

            stressAssessmentData[event.date] = value

        }

    },
    completion: { (success, errorOrNil) in
        // This block is called after the last event's handler returns.
        guard success else {
            // Add proper error handling here...
            fatalError(errorOrNil!.localizedDescription)
        }

        dispatch_group_leave(gatherDataGroup)
})

// Wait until all the data is gathered, then process the results.
dispatch_group_notify(gatherDataGroup, mainQueue) {
    // Combine the data here.       
}
```

This sample uses dispatch groups to coordinate the two asynchronous calls, and move the results back to the main thread. For more information on dispatch groups, see [Grand Central Dispatch (GCD) Reference > Using Dispatch Groups](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/#//apple_ref/doc/uid/TP40008079-CH2-SW19)

## Clearing the Store

As you iteratively develop and test your app, you often need to change the design of your treatment plan. This usually means removing the old activities before you can add new ones.

Since the Care Plan Store automatically saves your activities in its database, you need a way to clear out the database before each new test. If you are testing the app on the simulator, you can reset the simulator by selecting the Simulator > Reset Content and Settings... menu item. This clears all data from the simulator. However, it only works on the simulator, and it is a rather heavy-handed approach.

Alternatively, you can create a function that deletes all the activities from the store. Call this method only during your testing and debugging sessions.

The sample code below demonstrates a straightforward synchronous method that deletes everything from the store.

```swift
private func _clearStore() {
    print("*** CLEANING STORE DEBUG ONLY ****")

    let deleteGroup = dispatch_group_create()
    let store = self.store

    dispatch_group_enter(deleteGroup)
    store.activitiesWithCompletion { (success, activities, errorOrNil) in

        guard success else {
            // Perform proper error handling here...
            fatalError(errorOrNil!.localizedDescription)
        }

        for activity in activities {

            dispatch_group_enter(deleteGroup)
            store.removeActivity(activity) { (success, error) -> Void in

                print("Removing \(activity)")
                guard success else {
                    fatalError("*** An error occurred: \(error!.localizedDescription)")
                }
                print("Removed: \(activity)")
                dispatch_group_leave(deleteGroup)
            }
        }

        dispatch_group_leave(deleteGroup)
    }

    // Wait until all the asynchronous calls are done.
    dispatch_group_wait(deleteGroup, DISPATCH_TIME_FOREVER)
}
```
This sample reads all the activities from the store, and then iterates over the list of activities, removing each one from the store.

 **Note:** this sample uses dispatch groups to convert a series of asynchronous calls into a synchronous method. The `_clearStore()` method does not return until all of its asynchronous calls return. While you wouldn't want to use this technique in production code, it can greatly simplify a complex series of asynchronous calls. This can be very useful when testing, debugging, or writing exploratory code.

## Sharing Data with HealthKit
Because CareKit and HealthKit both focus on health information, you may find it useful to share data between the two stores. Here's a code example that illustrates how this can be achieved:

```swift
func symptomTrackerViewController(viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {

    let identifier = assessmentEvent.activity.identifier

    if identifier == TemperatureAssessment {
        // 1. Present a survey to ask for temperature
        // ...

        // 2. Save the collected temperature into HealthKit
        let hkStore = HKHealthStore()
        let type = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)!
        hkStore.requestAuthorizationToShareTypes(
            Set<HKSampleType>(arrayLiteral: type),
            readTypes: Set<HKObjectType>(arrayLiteral: type),
            completion: { (success, error) in
                let sample = HKQuantitySample(
                    type: type,
                    quantity: HKQuantity(unit: HKUnit.degreeFahrenheitUnit(), doubleValue: 99.1),
                    startDate: NSDate(),
                    endDate: NSDate()
                )

                hkStore.saveObject(
                    sample,
                    withCompletion: { (success, error) in
                        // 3. When the collected temperature has been saved into HealthKit
                        // Use the saved HKSample object to create a result object and save it to CarePlanStore.
                        // Then each time, CarePlanStore will load the temperature data from HealthKit.
                        let result = OCKCarePlanEventResult(
                            quantitySample: sample,
                            quantityStringFormatter: nil,
                            unitStringKeys: [
                                HKUnit.degreeFahrenheitUnit() : "\u{00B0}F", // °F
                                HKUnit.degreeCelsiusUnit()    : "\u{00B0}C"  // °C
                            ],
                            userInfo: nil
                        )

                        self.storeManager.store.updateEvent(
                            assessmentEvent,
                            withResult: result,
                            state: .Completed,
                            completion: { (success, event, errorOrNil) in
                                guard success else {
                                    // Add proper error handling here...
                                    fatalError(errorOrNil!.localizedDescription)
                                }
                            }
                        )
                    }
                )
            }
        )
    }
}
```

In this example, a body temperature value is saved to a HealthKit store after being acquired from CareKit.

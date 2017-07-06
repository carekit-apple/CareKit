<br/>
<sub>These materials are for informational purposes only and do not constitute legal advice. You should contact an attorney to obtain advice with respect to the development of a CareKit app and any applicable laws.</sub>

# Storing Data in the Care Plan Store
Care plan data represents the activities, events, and other data that make up a treatment plan. The data is stored in the *care plan store*, a persistent database. 

**On This Page:**
<ul>
<li><a href="#creating">Creating the Care Plan Store</a><li>
<li><a href="#access">Accessing Care Plan Data</a><li>
<li><a href="#managing">Managing Activities and Events</a></li>
<li><a href="#changes">Responding to Changes in the Care Plan Store</a></li>
<li><a href="#reading">Reading Data from the Care Plan Store</a></li>
<li><a href="#clearing">Clearing the Care Plan Store During Development</a></li>
</ul> 

## Creating the Care Plan Store<a name="creating"></a>
Care plan data is stored in the care plan store, a database represented by the `OCKCarePlanStore` class. This database is persisted at the URL you provide when you instantiate your app's `OCKCarePlanStore` object.  You create one care plan store per app, on the main thread, and keep a reference to it for later use.

To instantiate a store object, you pass the constructor a URL for your store's data. This URL must point to a directory that indicates the location where the system loads and saves your store's files.

1. Generate a URL to a directory inside your app's documents directory.

    	let fileManager = NSFileManager.defaultManager()
    
    	guard let documentDirectory = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last else {
    		fatalError("*** Error: Unable to get the document directory! ***")
    	}
    
    	let storeURL = documentDirectory.URLByAppendingPathComponent("MyCareKitStore")


2. Verify that the directory exists. If it does not exist, create it.
	
    	if !fileManager.fileExistsAtPath(storeURL.path!) {
    	   try! fileManager.createDirectoryAtURL(storeURL, withIntermediateDirectories: true, attributes: nil)
    	}

3. Instantiate the care plan store, and assign it to an instance variable for later use. Assign the store's delegate, which lets you respond to any changes to the store.

    	store = OCKCarePlanStore(persistenceDirectoryURL: storeURL)
    	store.delegate = self
    	

Once the care plan store is created, you can add, read, or delete activities or events to it.  A care plan store automatically loads existing activities and automatically saves any changes you make to its activities. It also saves the user's progress on its events.

For more information on working with URLs and the iOS file system, see [File System Programming Guide](https://developer.apple.com/library/ios/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/Introduction/Introduction.html).

## Accessing Care Plan Data<a name="access"></a>

Care plan data is stored in the app's care plan store, a persistent database. CareKit's database is encrypted using `NSFileProtectionComplete`, the standard file system encryption. The database is stored in an encrypted format on disk and cannot be read from or written to while the device is locked or booting.

When working with CareKit data, you don't access this database directly. Instead, you interact with the database using your app's care plan store object. The care plan store provides methods that perform the following actions:

* Store or delete activities
* Set an activity's end date
* Read activities or events
* Update events

The care plan store must be created on the main thread, but its methods can be called from any thread. All of the methods are asynchronous. They dispatch the actual work to a FIFO background queue. As soon as the work is complete, the method's completion handler is called on an anonymous background queue. You often need to dispatch these results back to the main queue before updating your app.

For more information on working with asynchronous APIs, see [Concurrency Programming Guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html).

## Managing Activities and Events<a name="managing"></a>

The care plan store manages two basic data types:

* Activities -  `OCKCarePlanActivity` objects
* Events - `OCKCarePlanEvent` objects 

*Activities* represent the user's care plan, while *events* represent the individual tasks that the user must perform to complete the plan. When you add an activity to the care plan store, CareKit automatically generates the event objects for that activity. For example, if the activity indicates taking three doses of medication per day, CareKit generates three events for that activity for each day.

Activities are uniquely identified by an `identifier` property. Identifiers are strings that you provide when you create the activity. You can use any string you wish, but every activity in the care plan store must have a unique string. Attempting to reuse an existing identifier will fail, returning an error with an `OCKErrorDomain` domain and a `OCKErrorInvalidObject` error code.

Activities can also have a `groupIdentifier` property. The group identifier is an arbitrary string you set when you create the activity. Multiple activities can share the same group identifier. Use the group identifier to partition your activities into related groups, which lets you easily search the care plan store for the activities with a given group identifier. On the Care Contents scene, activities with the same group identifier may be grouped together.

## Responding to Changes in the Care Plan Store<a name="changes"></a>

CareKit automatically updates the Care Contents, Care Card and the Symptom and Measurement Tracker whenever the data in the care plan store changes.  To update other views or controllers when the data changes, you must create a delegate object to monitor the care plan store. The delegate must adopt the `OCKCarePlanStoreDelegate` protocol, which defines two optional methods:

* `carePlanStoreActivityListDidChange()`. This method is called whenever an activity is added or removed from the store.

* `carePlanStore(didReceiveUpdateOfEvent:)`. This method is called whenever an event is updated, such as when the user completes an event in their treatment plan.

For example, if you want to update your Insights scene whenever the care plan store data changes, implement the `carePlanStore(didReceiveUpdateOfEvent:)` method, and have it call a method that reads new data from the store and updates the Insight items, as shown below:


    func carePlanStore(store: OCKCarePlanStore, didReceiveUpdateOfEvent event: OCKCarePlanEvent) {
      updateInsights()
    }
    

## Reading Data from the Care Plan Store<a name="reading"></a>

The care plan store provides methods for reading activities and events. 

### Reading Activities 
For activities, you can read the activity for a given identifier, all the activities for a group identifier, or batch read all the activities in the entire treatment plan.

For example, the following sample code reads all the intervention activities currently saved in the store:

    store.activitiesWithType(.Intervention) { (success, activities, errorOrNil) in
        guard success else {
            // perform proper error handling here
            fatalError(errorOrNil!.localizedDescription)
        }
    
        // now do something with the activities.
    }

### Reading Events
CareKit is somewhat more restrictive when it comes to reading events. In general, a care plan has relatively few activities, but activities can generate an unlimited number of events. Therefore, to keep the memory footprint low, the care plan store reads events from a single day at a time. 

For example, the following sample code reads all of today's events for the ibuprofen activity.

        guard let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) else {
            fatalError("This should never fail.")
        }
        
       // Read the events for the ibuprofen activity for today
        let today = calendar.components([.Day, .Month, .Year], fromDate: NSDate())
        store.eventsForActivity(ibuprofen, date: today) { (events, errorOrNil) in
        
            if let error = errorOrNil {
                // Perform proper error handling here
                fatalError(error.localizedDescription)
            }
        
            // do something with the ibuprofen events.
        }

### Working with Dates
CareKit defines dates using the `NSDateComponent` objects. Each date component object must use the Gregorian calendar and must define a valid day, month, and year component. From the user's perspective, individual days may be greater or less than 24 hours (for example, if the user is traveling). Using date components lets you uniquely specify a given date from the user's perspective, regardless of the user's current time zone or travel itinerary.

For more information on using calendars and dates, see [Date and Time Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/DatesAndTimes/DatesAndTimes.html)

### Reading Events Over a Data Range
To help gather data from a range of dates, the care plan store provides two higher order methods that iterate over larger amounts of data.

* The `dailyCompletionStatusWithType(startDate:, endDate:, handler:, completion:)` method calls its handler once for each date in the provided range of dates. However, instead of providing information about specific events, it provides a count of the number of events that the user has completed, and the total number of events for each date.

* The `enumerateEventsOfActivity(startDate:, endDate:, handler:, completion:)` method calls its handler once for each event generated by the provided activity during the provided range of dates.

Both methods call their completion block once all the events have been handled.

The following sample code demonstrates using these methods to collect data over a range of dates, and then combining that data.

    // These variables will store the data generated by the care plan store.
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
   

This sample uses dispatch groups to coordinate the two asynchronous calls, and move the results back to the main thread. For more information on dispatch groups, see [Grand Central Dispatch (GCD) Reference > Using Dispatch Groups](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/#//apple_ref/doc/uid/TP40008079-CH2-SW19)

## Clearing the Care Plan Store During Development<a name="clearing"></a>

As you iteratively develop and test your app, you may need to change the design of your treatment plan. This usually means removing the old activities from the care plan store before you can add new ones.

Since the care plan store automatically saves activities in its database, you need a way to clear out the database before each new test. If you are testing the app on the simulator, you can reset the simulator by selecting the Simulator > Reset Content and Settings... menu item. This action clears all data from the simulator. However, it only works on the simulator, and it is a rather heavy-handed approach.

Alternatively, you can create a function that deletes all the activities from the care plan store. Call this method only during your testing and debugging sessions.

The sample code below demonstrates a synchronous method that deletes everything from the care plan store.


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

This code sample reads all the activities from the store, and then iterates over the list of activities, removing each one from the store.

 **Note:** this sample uses dispatch groups to convert a series of asynchronous calls into a synchronous method. The `_clearStore()` method does not return until all of its asynchronous calls return. While you wouldn't want to use this technique in production code, it can greatly simplify a complex series of asynchronous calls. This can be very useful when testing, debugging, or writing exploratory code.

## Sharing Data with HealthKit
Because CareKit and HealthKit both focus on health information, you may find it useful to share data between the two stores. 

Here's a code example that illustrates how this can be achieved. In this example, a body temperature value is saved to a HealthKit store after being acquired from CareKit.

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
   


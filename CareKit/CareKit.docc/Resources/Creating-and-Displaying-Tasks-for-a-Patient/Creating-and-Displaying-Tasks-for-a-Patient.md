# Creating and displaying tasks for a patient

Create tasks and schedules for patients and display them using a synchronized view controller.

## Overview

When creating an app using CareKit, you can create tasks, such as taking medication or performing an exercise, for the user to complete. To create tasks for users, first create a store. This provides a place for your task data to persist. Then create both simple and complex task schedules so your users know when to perform their tasks. You can then present the scheduled tasks to the user.

### Create a store

Create a store for your data. You instantiate your store with a name. There’s no specific validation of this name, but it’s good practice to make it distinctive. Use the reverse-url format bundle identifier of your app with a unique name appended:

```swift
import CareKit
import CareKitStore

let storeName = "com.mycompany.myapp.nausea"
let store = OCKStore(name: storeName) 
```

If you attempt to create a store with a name of an already-existing store, the `OCKStore` initializer returns the existing store.

### Create a schedule

When creating a task, provide a schedule so users know when they need to complete the task. For a task like taking a medication, the schedule specifies when the user should take that medication, such as 11:00 AM or after dinner.

You build schedules by defining times, offsets from known times, and ranges across times and dates that consists of at least one schedule element. A schedule element represents a defined moment or range of moments.

> Note: Calendar calculations are complex and depend on the user’s device settings for time zone and calendar. Use the provided Calendar API for the Date and DateComponents to simplify this.

Building a schedule takes a few simple steps. The code below shows how to create a schedule that occurs every day at 8:00 AM, starting on the current day. In the first line, Calendar returns the first moment of today’s date based on the user’s calendar. In the second line, add 8 hours to create a date object at 8:00 AM. Next, create a schedule element, using today’s date at 8:00 AM, then set it to occur daily. In the last line, create a schedule using the schedule element you created in the line before.

```swift
let startOfDay = Calendar.current.startOfDay(for: Date())
let atBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: startOfDay)!

let dailyAtBreakfast = OCKScheduleElement(start: atBreakfast, end: nil, interval: DateComponents(day: 1))

var schedule = OCKSchedule(composing: [dailyAtBreakfast])
```

Create your schedule using date objects initialized with the user’s calendar preference. There are a variety of calendars your user could be using, each with different properties and nuances. Creating dates with the user’s calendar preference ensures correct date calculations.

### Schedule multiple elements

If you need a schedule that’s more complex than listing once-a-day events, you can build it by working with multiple schedule elements. The code below expands on the previous code example by creating an additional schedule element that occurs every other day at 12:00 PM. Finally, it creates a schedule with the two schedule elements.

```swift
let startOfDay = Calendar.current.startOfDay(for: Date())
let atBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: startOfDay)!

let dailyAtBreakfast = OCKScheduleElement(start: atBreakfast, end: nil, interval: DateComponents(day: 1))

let atLunch = Calendar.current.date(byAdding: .hour, value: 12, to: startOfDay)!

let everyTwoDaysAtLunch = OCKScheduleElement(start: atLunch, end: nil, interval: DateComponents(day: 2))

var schedule = OCKSchedule(composing: [dailyAtBreakfast, everyTwoDaysAtLunch])
```

### Create and save tasks to the store

Once you’ve defined a schedule, use it to create a task. You create a task with an identifier, title, care plan, and schedule. You can also provide instructions for the task as shown in the second line:

```swift
var task = OCKTask(identifier: "doxylamine", title: "Take Doxylamine", carePlanID: nil, schedule: schedule)

task.instructions = "Take 25mg of doxylamine when you experience nausea."
```

Next, save your task to the store. You can specify a function to handle the completion of the operation. The code below shows how to save your task, and the format of the parameters passed into the completion handler.

```swift
let storedTask = try await store.addTask(task)
```

### Handle errors

If interacting with the store throws an error, you can catch the error to help troubleshoot the problem and decide how to handle it.

The thrown error is an instance of `OCKStoreError`, an enumeration that contains a value and a localized description. The enumeration value is one of the following:

- term `fetchFailed`: Occurs when a fetch fails.

- term `addFailed`: Occurs when adding an entity fails.

- term `updateFailed`: Occurs when an update to an existing entity fails.

- term `deleteFailed`: Occurs when deleting an existing entity fails.

- term `invalidValue`: Occurs when an invalid value is passed.

- term `timedOut`: Occurs when an asynchronous action takes too long. This is intended for use by remote databases.

Use this value to determine whether to retry the operation, inform the user, or handle the error some other way. To provide feedback to the user, present the localized description to the user.

For example, if you attempt to add an entity to the store that’s missing required information, you receive an error enumeration with the value of `OCKStoreError.invalidValue(reason:)`, and the localized description of “OCKCDScheduleElement must have at least 1 non-zero interval.

### Display Scheduled tasks

Once you have a store populated with tasks, you can display those tasks to the user. CareKit provides pre-built view controllers and a range of controls and views to build your own user interface layouts.

The simplest way to present data to the user is to use the pre-built view controllers. The code below builds on previous code listings, and shows how to present task data to the user using an ``OCKDailyTasksPageViewController``.

```swift
let careViewController = OCKDailyTasksPageViewController(store: store)
self.present(careViewController, animated: true, completion: nil)
```

The ``OCKDailyTasksPageViewController``  observes changes to the store and updates the view automatically. All you need to do is instantiate it with a store and then present it.

The ``OCKDailyTasksPageViewController`` displays a header, that contains a weekly calendar, and a body, that includes a list of tasks scheduled for the currently selected date. When a user selects a date in the calendar, the calendar shows all tasks scheduled for that date. When the user taps to complete a task, the controller saves it in the store.

You can use view controllers and views available in CareKit to customize the user interface appearance, or use your own.

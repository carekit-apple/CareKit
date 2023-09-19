# Creating schedules for tasks 

Create schedules for tasks using multiple schedule elements.

## Overview

When you define a schedule for performing a task, you also define one or more schedule elements. These elements allow you to build up complex behaviors composed from multiple steps.

Schedules are based around specific dates, times, and intervals. Reduce the potential for complexity in calculating these by using the Calendar API and the Date Components API wherever possible. These tools handle edge cases, such as daylight savings times, and leap years that can otherwise introduce inaccuracies when attempting to calculate using seconds-based time intervals.

### Compose schedule elements

The following code creates a series of reference objects as a starting point for a schedule, based on the returned value from initializing a `Date` object:

```swift
// A date that represents 00h 00m 00s today or midnight.
let startOfDay = Calendar.current.startOfDay(for: Date())

// A date that represents 08h 00m 00s today or 8am.
let breakfastTime = Calendar.current.date(byAdding: .hour, value: 8, to: startOfDay)!

// A date that represents 13h 00m 00s or 1pm.
let lunchTime = Calendar.current.date(byAdding: .hour, value: 5, to: breakfastTime)!

// A date that represents 19h 30m 00s or 7.30pm.
let dinnerTime = Calendar.current.date(byAdding: .minute, value: 270, to: lunchTime)!
```

Use these reference dates to build a schedule for a task that should be completed at 8:00 AM on day 1, 1:00 PM on day 2, and 7:30 PM on day 3:

```swift
// A date component for offsetting by 3 days.
let threeDays = DateComponents(day: 3)

var day1 = OCKScheduleElement(start: breakfastTime, end: nil, interval: threeDays)
var day2 = OCKScheduleElement(start: Calendar.current.date(byAdding: .day, value: 1, to: lunchTime)!, end: nil, interval: threeDays)
var day3 = OCKScheduleElement(start: Calendar.current.date(byAdding: .day, value: 2, to: dinnerTime)!, end: nil, interval: threeDays)

let multiDaySchedule = OCKSchedule(composing: [day1, day2, day3])
```

### Add context to schedule elements

Add context to each element of the schedule by setting the text property with details of the time the element represents, and specifying a duration that the task should take:

```swift
var element = OCKScheduleElement(start: breakfastTime, end: nil, interval: DateComponents(day: 1))
element.text = "Every day at 8am for 5 minutes"
element.duration = .seconds(300)
```

### Include outcome values

Each time a user completes a task event in your app, the data store saves the outcome. This outcome can contain a value or values that you configure in the schedule element. When your app presents the task for a given day, it uses the schedule defined by the elements to determine what values to associate with the outcome.

Create outcome values with an ``OCKOutcomeValue`` with a value that can be an `Int`, `Double`, `Bool`, `String`, `Data` or `Date`, and a unit which is a `String`. Because an instance of a task might have multiple dimensions (for example, 2 tablets each of 500mg), you can specify an array of them for each schedule element:

```swift
var tablet1 = OCKOutcomeValue(25.00, units: "mg")
var tablet2 = OCKOutcomeValue(25.00, units: "mg")
element.targetValues = [tablet1, tablet2]
```

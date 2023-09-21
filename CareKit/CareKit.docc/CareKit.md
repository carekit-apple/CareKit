# ``CareKit``

Create apps that help people better understand and manage their health.

## Overview

CareKit is an open source framework that you can use to build apps to manage and understand health data. Apps can highlight trends, celebrate goals, and create incentives for users. CareKit makes it easy to provide engaging, consistent interfaces with delightful animations, and full interaction with the accessibility features of iOS and iPadOS.

This open source framework is written entirely in Swift, and leverages some of the most powerful Swift language features.

Your CareKit apps can:

- Easily digitize a prescription.

- Provide meaningful health data and trends to users.

- Allow users to connect with their care providers.

The framework provides a powerful set of data models for persistence. Your app represents a user as a patient in CareKit's data; a patient completes a set of tasks, such as taking a medication or logging a symptom. Create tasks with a schedule to indicate when to perform each task, and build schedules with complex requirements by combining simple ones.

The combination of a patient’s tasks make up a care plan. A care plan helps a user improve part of their health; for example, recovering from an operation or managing diabetes. A patient can have multiple care plans, and each care plan can have contacts associated to them. Contacts are the patient’s care providers.

When a patient completes a task, CareKit stores results as outcomes. These outcomes and their associated values enable you to provide charts and graphs for a user to help them understand the health impact of their care plan.


## Topics

### Essentials

- <doc:Setting-up-Your-Project-to-Use-CareKit>
- <doc:Creating-and-Displaying-Tasks-for-a-Patient>

### Displaying synchronized care data in SwiftUI

- ``CareStoreFetchRequest``
- ``CareStoreFetchedResults``
- ``CareStoreFetchedResult``

### Displaying synchronized care data in UIKit

- ``ViewSynchronizing``
- ``SynchronizedViewController``
- ``OCKSynchronizationContext``

### Displaying care tasks in UIKit

- ``OCKTaskViewController``
- ``OCKSimpleTaskViewController``
- ``OCKInstructionsTaskViewController``
- ``OCKChecklistTaskViewController``
- ``OCKGridTaskViewController``
- ``OCKButtonLogTaskViewController``
- ``OCKTaskEvents``
- ``OCKSimpleTaskViewSynchronizer``
- ``OCKInstructionsTaskViewSynchronizer``
- ``OCKChecklistTaskViewSynchronizer``
- ``OCKGridTaskViewSynchronizer``
- ``OCKButtonLogTaskViewSynchronizer``
- ``OCKTaskViewSynchronizerProtocol``
- ``OCKAnyTaskViewSynchronizerProtocol``

### Displaying care task details

- ``OCKDetailViewController``

### Displaying contacts in UIKit

- ``OCKContactViewController``
- ``OCKSimpleContactViewController``
- ``OCKDetailedContactViewController``
- ``OCKContactsListViewController``
- ``OCKSimpleContactViewSynchronizer``
- ``OCKDetailedContactViewSynchronizer``
- ``OCKContactViewSynchronizerProtocol``
- ``OCKAnyContactViewSynchronizerProtocol``

### Displaying a chart in UIKit

- ``OCKChartViewController``
- ``OCKCartesianChartViewController``
- ``OCKDataSeriesConfiguration``
- ``OCKCartesianChartViewSynchronizer``
- ``OCKChartViewSynchronizerProtocol``

### Displaying a calendar in UIKit

- ``OCKCalendarViewController``
- ``OCKWeekCalendarViewController``
- ``OCKWeekCalendarViewSynchronizer``
- ``OCKCalendarViewSynchronizerProtocol``

### Displaying care data over time in UIKit

- ``OCKDailyTasksPageViewController``
- ``OCKDailyTasksPageViewControllerDelegate``
- ``OCKDailyPageViewController``
- ``OCKDailyPageViewControllerDataSource``
- ``OCKDailyPageViewControllerDelegate``
- ``OCKWeekCalendarPageViewController``
- ``OCKWeekCalendarPageViewControllerDelegate``
- ``OCKListViewController``

### Logging

- ``OCKLog``

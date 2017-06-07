# CareKit Release Notes

## CareKit 1.2 Release Notes

*CareKit 1.2* supports *iOS* and requires *Xcode 8.0* or later. The minimum supported *Base SDK* is *9.0*.
*CareKit 1.2* includes the following new features and enhancements *by [Apple Inc.](https://github.com/carekit-apple)*

- **Care Contents Card**

 The *Sample App* (OCKSample project in CareKit's workspace) now includes a Care Contents view controller, which allows for activities and interventions to be seen in the same place. You may still choose to use the *Care Card *and *Symptom Tracker* view controllers independently to separate out care “to-do’s” and measurement tracking if desired. 
 
- **Optional Activities**
 
 Intervention and assessment activity types can now be tagged as “optional”. Completion of optional activities do not contribute to a user’s daily completion goals, and are well suited for “take as needed” care activities – such as pain medications or optional physical activities. 

- **Read Only Activity Type**
 
 You can now create a new class of activity called “read only” by utilizing the ReadOnly initializer. Read only activities can be used to display information which do not require any action from the user. Examples can include day-of-surgery dietary instructions, or tricks and tips that might be interesting to share throughout a user’s care journey. 

- **Updated Header View and 28 Glyph Icons**

 The header view across *Care Card, Symptom Tracker and the New Care Contents* has been updated to display a daily ring view with customizable glyphs inside to represent completion of care activities. The Apple team has designed 28 icons that can be used within the ring view, and are compatible as Apple Watch complications. Once a user reaches 100%, the ring will fill in and a star badge will appear to easily identify days of full compliance. 

- **Updated Insights Tab with Thresholds**

 The *Insights* view controller has been updated to include the ability to display thresholds. You can now set thresholds in your assessment or intervention activities, and display alert UI and tint colors on the *Insights* view controller if thresholds are broken. 

- **Inbox Feature in Connect**

 We’ve updated the *Inbox* view controller to include UI for messaging between consumers and care teams, friends, and family members. Developers can choose to include this functionality in use cases where asynchronous messaging might play a crucial role in a consumer’s care journey.
 
- **Cloud Bridge API**

 We’re making data sharing between CareKit apps even easier with the new addition of our Cloud Bridge API. The bridge API is an Abstract cloud API that conforms to the CareKit schema and enables data syncing without any additional configuration. It’s designed to allow CareKit based apps to seamlessly integrate with backend cloud solutions, and is based upon the current CareKit data model and architecture
The bridge API provides all of the necessary hooks through delegate functions for cloud bridge’s to seamlessly hook into the CareKit framework, allowing developers or current cloud providers to conform to the CareKit schema with reduced effort and create backend solutions that fit directly into the current framework architecture.

   
## CareKit 1.1 Release Notes

*CareKit 1.1* supports *iOS* and requires *Xcode 8.0* or later. The minimum supported *Base SDK* is *9.0*.

*CareKit 1.1* includes the following new features and enhancements.

- **Care Card on Apple Watch**
 
 *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

 The *Sample App* (OCKSample project in CareKit's workspace) now includes a watch app. The app works out of the box. Included in the Watch group is the *Watch Connectivity Manager* which abstracts the logic of communicating the *Care Card* data between the phone and the watch. 

 The *Care Plan Store* has also been updated to support Apple Watch.

- **New Test App**

 *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

 The *New Test App* is written entirely in Swift and provides extensive coverage for all CareKit Modules.

- **Other Improvements**

 - **3D Touch Support**

  *Contributed by [Troy Tsubota](https://github.com/tktsubota).*

  The *Care Card* and *Connect* view controllers have been updated to support 3D Touch. In the *Care Card* view controller, a user can 3D Touch on an activity to peek and pop. In the *Connect* view controller, a user can peek, pop, and use perform actions right from the master screen.

  - **FaceTime in Connect**

   *Contributed by [Micah Hainline](https://github.com/micahhainline).*

   *FaceTime* calls can now be made from within the Connect module. Apart from *FaceTime* support, *Connect* now has the ability to create any custom method of communication (such as fax).


## CareKit 1.0 Release Notes

*CareKit 1.0* supports *iOS* and requires *Xcode 6.3* or later. The minimum supported *Base SDK* is *9.0*.

*CareKit 1.0* includes the following new features and enhancements.

- **Care Plan Store**

 *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

  CareKit stores activities in a database called the *Care Plan Store*. This database is located at the URL provided by
      the developer. The *Care Plan Store* is encrypted using standard file-system encryption. 

  The *Care Plan Store* can store intervention and assessment activities. Each activity has a schedule that the *Care Plan Store* uses
      to create event objects. The store can be dynamically updated and modified.

- **Care Card**

 *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

  *Care Card* is a view controller that displays the intervention activities for a selected date. It provides a way to track activity
      completion and user adherence. 

  A developer can modify the *Care Plan Store* by adding, removing, or modifying an activity and the *Care Card* responds by automatically
      updating the user interface.

  The mask image on the Care Card can be customized to provide a themed user experience.

- **Symptom and Measurement Tracker**

 *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

  *Symptom and Measurement Tracker* is a view controller that displays the assessment activities for a selected date. It provides a way to monitor
      subjective and objective measurements.

  A developer can modify the *Care Plan Store* by adding, removing, or modifying an activity and the *Symptom and Measurement Tracker* responds by 
      automatically updating the user interface.

- **Insights Dashboard**

  *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

  The *Insights Dashboard* is a view controller that displays message items, such as an alert or tip, and charts, such as the grouped
      bar chart.

  A developer can subclass the OCKInsightItem and OCKChart classes to create new message items and charts.  

- **Grouped Bar Chart**

   *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

   The *Grouped Bar Chart* displays a series of data grouped into categories. The chart can be used with the *Insights Dashboard* using the
      *OCKBarChart* object, or it can be used directly using *OCKGroupedBarChartView*.

- **Connect**

  *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

  *Connect* is a view controller that displays contact information for care team members, friends, and family. *Connect* supports 
      communicating with contacts through email, messaging, and phone. It also supports a user interface for sending reports that you
      can create using the Document Exporter module 

- **Document Exporter**

  *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

  The *Document Exporter* module supports creating an HTML or PDF document. Although you can provide any data you’d like, the intent is 
      to export data from the Care Plan Store. The exporter can display text, charts, images, and tables.

- **Sample App**

  *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

  The *Sample App* (OCKSample project in CareKit's workspace) serves as a template application that combines different modules
      from the CareKit framework. It also shows how to use ResearchKit surveys and active tasks with CareKit.

- **Test App**

  *Contributed by [Apple Inc.](https://github.com/carekit-apple).*

  The *Test App* (OCKTest project in CareKit's workspace) serves as an application to test different modules and features from
      the CareKit framework.


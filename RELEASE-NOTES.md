# CareKit Release Notes


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


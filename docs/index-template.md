The CareKit™ framework is an open source framework that developers and researchers can use to create apps that let iOS users manage their healthcare.

This is the API documentation for the CareKit framework. For an overview of the framework and a more general guide to using and extending the framework, see the [Overview](Overview).


CareKit Scenes
--------------------
There are four scenes available to apps that use CareKit:

**Care Card.** The Care Card scene presents and manages the tasks that the user is expected to perform as part of their treatment. For example, taking a medication, changing a wound dressing, or meditating.

**Symptom & Measurement Tracker.** This scene presents and manages tasks that evaluate the effectiveness of the user's care plan. These include the subjective assessment of symptoms (such as pain scales) and objective measurements (such as blood pressure).

**Insights.** The Insights scene displays charts that provide insight to the user by showing the relationship between treatment and progress. An insight can also include tips and alerts that help the user stay on track with their health goals. 

**Connect.** The Connect scene helps the user communicate their health status and Insights data with care team members, family, and friends.

The Care Plan Store
--------------------
The persistent database stores the data displayed by the Care Card and Symptom & Measurement Tracker. CareKit automatically loads the store’s data as soon as the store is created, and it automatically saves any changes you make to the store. 

Documents
--------------------
CareKit creates custom documents that incorporate graphs and other information from the Insights module. Use this feature to create PDFs or HTML files that you can share with the user’s contacts.



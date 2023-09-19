# ``CareKitStore``

Store and retrieve patient care data.

## Overview

CareKitStore provides a Core Data solution for storing and retrieving patient care data. It provides the ability to use a custom store, such as a third-party database.

## Topics

### Essentials

<doc:Creating-Schedules-for-Tasks>

### Stores

- ``OCKStore``
- ``OCKCoreDataStoreType``
- ``OCKHealthKitPassthroughStore``
- ``OCKStoreCoordinator``
- ``OCKStoreError``
- ``OCKAnyStoreProtocol``
- ``OCKStoreProtocol``
- ``OCKAnyResettableStore``
- ``OCKResultClosure``
- ``CareStoreQueryResults``

### Care tasks

- ``OCKTask``
- ``OCKAnyTask``
- ``OCKAnyVersionableTask``
- ``OCKHealthKitTask``
- ``OCKHealthKitLinkage``
- ``OCKTaskStore``
- ``OCKAnyTaskStore``
- ``OCKReadableTaskStore``
- ``OCKAnyReadOnlyTaskStore``
- ``OCKTaskQuery``

### Care task scheduling

- ``OCKSchedule``
- ``OCKScheduleElement``

### Events

- ``OCKEvent``
- ``OCKAnyEvent``
- ``OCKScheduleEvent``
- ``OCKEventStore``
- ``OCKAnyEventStore``
- ``OCKReadOnlyEventStore``
- ``OCKAnyReadOnlyEventStore``
- ``OCKEventQuery``

### Outcomes

- ``OCKOutcome``
- ``OCKAnyOutcome``
- ``OCKOutcomeValue``
- ``OCKOutcomeValueType``
- ``OCKOutcomeValueUnderlyingType``
- ``OCKHealthKitOutcome``
- ``OCKOutcomeStore``
- ``OCKAnyOutcomeStore``
- ``OCKReadableOutcomeStore``
- ``OCKAnyReadOnlyOutcomeStore``
- ``OCKOutcomeQuery``

### Contacts

- ``OCKContact``
- ``OCKAnyContact``
- ``OCKPostalAddress``
- ``OCKBiologicalSex``
- ``OCKContactCategory``
- ``OCKLabeledValue``
- ``OCKContactStore``
- ``OCKAnyContactStore``
- ``OCKAnyReadOnlyContactStore``
- ``OCKReadableContactStore``
- ``OCKContactQuery``

### Care plans

- ``OCKCarePlan``
- ``OCKAnyCarePlan``
- ``OCKCarePlanStore``
- ``OCKAnyReadOnlyCarePlanStore``
- ``OCKReadableCarePlanStore``
- ``OCKAnyCarePlanStore``
- ``OCKCarePlanQuery``

### Patients

- ``OCKPatient``
- ``OCKAnyPatient``
- ``OCKAnyPatientStore``
- ``OCKAnyReadOnlyPatientStore``
- ``OCKPatientStore``
- ``OCKReadablePatientStore``
- ``OCKPatientQuery``

### Notes

- ``OCKNote``

### Care task progress

- ``CareTaskProgress``
- ``CareTaskProgressStrategy``
- ``BinaryCareTaskProgress``
- ``LinearCareTaskProgress``
- ``AggregatedCareTaskProgress``
- ``OCKEventAggregator``
- ``OCKAdherenceQuery``
- ``OCKAdherence``
- ``OCKAdherenceAggregator``

### Synchronization

- ``OCKRemoteSynchronizable``
- ``OCKRemoteSynchronizationDelegate``
- ``OCKRevisionRecord``
- ``OCKEntity``
- ``OCKWatchConnectivityPeer``

### Schema versioning

- ``OCKSemanticVersion``

### Logging

- ``OCKLog``

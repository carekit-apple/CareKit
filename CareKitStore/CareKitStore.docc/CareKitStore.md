# ``CareKitStore``

CareKit is an open source framework that you can use to build apps to manage and understand health data. You apps can highlight trends, celebrate goals, and create incentives for users. CareKit makes it easy to provide engaging, consistent interfaces with delightful animations, and full interaction with the accessibility features of iOS and iPadOS.

## Overview

This open source framework is written entirely in Swift, and it leverages some of the most powerful Swift language features.

Your CareKit apps can:

- Easily digitize a prescription.

- Provide meaningful health data and trends to users.

- Allow users to connect with their care providers.

The framework provides a powerful set of data models for persistence. Your app’s user is represented in CareKit’s data as a patient. A patient needs to complete a set of tasks, like taking a medication or logging their symptoms. Tasks are created with a schedule, so a patient knows when to perform each task. Schedules are composable, so you can build a complex set of requirements by combining simple ones.

The combination of a patient’s tasks make up a care plan. A care plan is designed to help a user improve part of their health, for example, recovering from an operation or managing diabetes. A patient can have multiple care plans, and each care plan can have contacts associated to them. Contacts are the patient’s care providers.

When a patient completes a task, the results are stored as outcomes. These outcomes and their associated values enable you to provide charts and graphs for a user, that help them understand the health impact of their care plan.

# ``CareKitUI``

Manage and display patient care data on your app.

## Overview

CareKitUI provides the views that you use to display patient care data. The views are open and extensible subclasses of <doc://com.apple.documentation/documentation/uikit/uiview>. Properties within the views are public and give you full control over the content.

## Topics

### Single care tasks

- ``SimpleTaskView``
- ``OCKSimpleTaskView``
- ``InstructionsTaskView``
- ``OCKInstructionsTaskView``
- ``CircularCompletionView``
- ``OCKCheckmarkButton``
- ``RectangularCompletionView``

### Multiple care tasks

- ``OCKGridTaskView``
- ``OCKChecklistTaskView``
- ``OCKChecklistItemButton``
- ``OCKGridTaskCell``
- ``OCKLabeledCheckmarkButton``

### Log-based care tasks

- ``OCKButtonLogTaskView``
- ``OCKLogTaskView``
- ``OCKLogButtonCell``
- ``OCKLogItemButton``

### Read-only care tasks

- ``NumericProgressTaskView``
- ``LabeledValueTaskView``
- ``LabeledValueTaskViewStatus``

### Care task details

- ``OCKDetailView``

### Contacts

- ``OCKSimpleContactView``
- ``OCKDetailedContactView``
- ``OCKAddressButton``
- ``OCKContactButton``

### Charts

- ``OCKCartesianChartView``
- ``OCKCartesianGraphView``
- ``OCKDataSeries``

### Calendar

- ``OCKWeekCalendarView``
- ``OCKCompletionRingButton``
- ``OCKCompletionRingView``
- ``OCKCompletionState``

### Links

- ``LinkView``
- ``LinkItem``

### Featured content

- ``OCKFeaturedContentView``
- ``OCKFeaturedContentViewDelegate``

### Common view components

- ``CardView``
- ``OCKCardable``
- ``HeaderView``
- ``OCKHeaderView``
- ``OCKStackView``
- ``OCKSeparatorView``
- ``OCKLabel``
- ``OCKLabeledButton``
- ``OCKAnimatedButton``
- ``OCKView``
- ``OCKResponsiveLayout``

### Task-interaction broadcasting

- ``OCKTaskDisplayable``
- ``OCKTaskViewDelegate``

### Contact-interaction broadcasting

- ``OCKContactDisplayable``
- ``OCKContactViewDelegate``

### Chart-interaction broadcasting

- ``OCKChartDisplayable``
- ``OCKChartViewDelegate``

### Calendar-interaction broadcasting

- ``OCKCalendarDisplayable``
- ``OCKCalendarViewDelegate``

### Styles

- ``OCKStylable``
- ``OCKStyle``
- ``OCKAnimationStyle``
- ``OCKAppearanceStyle``
- ``OCKColorStyle``
- ``OCKDimensionStyle``
- ``OCKStyler``
- ``OCKAnimationStyler``
- ``OCKAppearanceStyler``
- ``OCKColorStyler``
- ``OCKDimensionStyler``

### Logging

- ``OCKLog``

### Localization

- ``OCKLocalization``
- ``loc(_:_:arguments:)``

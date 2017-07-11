<br/>
<sub>These materials are for informational purposes only and do not constitute legal advice. You should contact an attorney to obtain advice with respect to the development of a CareKit app and any applicable laws.</sub>

# Insights

The Insights scene can display widgets, threshold alerts, and objects subclassed from `OCKInsightItem`, such as messages and bar charts. 

**On This Page:**
<ul>
<li><a href="#insights">Creating the Insights Scene</a><li>
<li><a href="#messages">Creating Messages</a><li>
<li><a href="#charts">Creating Bar Charts</a></li>
<li><a href="#widgets">Creating Widgets</a></li>
<li><a href="#thresholds">Creating Thresholds</a></li>
<li><a href="#documents">Creating Documents</a></li> 
</ul> 


The Insights scene is often used to visualize the correlation between a treatment plan's intervention activities and its assessment activities such as in Figure 1, which shows a bar chart that compares a user's reported pain with their adherence to medication. However, Insights is not limited to presenting CareKit data. You can use the scene's charts and messages to display any arbitrary data.

<center><img src="PresentingInsightsImages/InsightsScene.png" style="border: solid #e0e0e0 1px;" width="310" alt="Insights scene"/>
<figcaption>Figure 1: The Insights scene from the OCKSample app.</figcaption></center>

## Creating the Insights Scene<a name="insights"></a>

To create your Insights scene, instantiate and present an `OCKInsightsViewController` view controller. The Insights view controller's `init` method takes an array of insight items (charts or messages), a title, and a subtitle. The title and subtitle are both optional.

The following sample code creates an Insights view controller with a message and a chart, like the one shown in Figure 1.

    let insightsViewController = OCKInsightsViewController(
        insightItems: [message, chart],
        headerTitle: "Weekly Charts",
        headerSubtitle: nil)


## Creating Messages<a name="messages"></a>

You can display simple text messages using the `OCKMessageItem` class. A message item specifies the message's title, body text, the type of message (alert or tip), and a  color. The message type and color affect only the symbol appended to the end of the message's title.

The following sample code creates the "Medication Adherence" message shown in Figure 1.
    
    // Calculate the percentage of completed events.
    let medicationAdherence = Float(completedEventCount) / Float(totalEventCount)
    
    // Create an `OCKMessageItem` describing medical adherence.
    let percentageFormatter = NSNumberFormatter()
    percentageFormatter.numberStyle = .PercentStyle
    let formattedAdherence = percentageFormatter.stringFromNumber(medicationAdherence)!
    
    let message = OCKMessageItem(
        title: "Medication Adherence",
        text: "Your medication adherence was \(formattedAdherence) last week.",
        tintColor: Colors.Pink.color,
        messageType: .Tip)


## Creating Bar Charts<a name="charts"></a>

CareKit's bar charts let you display one or more series of values. To create a chart, follow these steps:

1. Gather the data you wish to display.
2. Provide labels for the chart.
3. Scale or format your data as appropriate.
4. Create one or more bar chart series.
5. Create the bar chart itself.

Bar charts can be displayed in an Insights scene or added to a CareKit document.

### Gathering Data

Often the most difficult task of creating a chart is gathering the data. If you are using data from your Care Plan Store, collecting the data involves making one or more asynchronous calls, and then combining the data from all of the completion handlers.

For more information on reading data from the Care Plan Store, see [Accessing Care Plan Data](../AccessingCarePlanData/AccessingCarePlanData.html).

### Providing Chart Labels

A bar chart may optionally include one or more labels, including a title, text, axis labels, and axis sub-labels.

* The title and text appear in the upper left corner, above the chart. 
* The axis labels and sub-labels appear along the left edge of the chart. 

In Figure 1, the title is "Back Pain," and the chart has no text label. The axis labels are the letters indicating the day of the week. This chart has no axis sub-labels.

Each series in a graph must have a title. Figure 1 has two series with the titles "Pain" and "Medical Adherence."

Each data point in the series must also have a value label, which appears at the right edge of the respective bar. In Figure 1, for the pain series, the label represents the pain value entered by the user in an assessment activity. For the medical adherence series, the label represents the percentage of the medicine intervention activities completed for that day.


### Scaling and Formatting the Data

A chart consists of a number of series, each of which contains an array of values. The chart attempts to graph these values in a meaningful way, using the lowest and highest values from all the series in the chart (or 0.0 if it is lower or higher) to determine the range for the chart.

Because the chart's scale and origin are based on the data across all your series, you often need to scale or offset your data, so that all of your series use the same range. For example, if your medical adherence values range from 0.0 to 1.0, but your pain values range from 0.0 to 10.0, you need to either multiply your medical adherence values by 10.0, or divide your pain values by 10.0. Either approach works, because they both produce the same relative range of values.

### Creating Data Series

Each set of data in your chart should be represented by its own series. Instantiate a `OCKBarSeries` object to represent a each series for your chart.  The following sample code creates the two series for the chart in Figure 1.

    // Create a `OCKBarSeries` for each set of data.
    let painBarSeries = OCKBarSeries(
        title: "Pain",
        values: painValues,
        valueLabels: painLabels,
        tintColor: Colors.Blue.color)
    
    let medicationBarSeries = OCKBarSeries(
        title: "Medication Adherence",
        values: medicationValues,
        valueLabels: medicationLabels,
        tintColor: Colors.LightBlue.color)


### Creating Your Chart

Once the data series are created, you can create the chart. The following sample code shows how the chart from Figure 1 is created.

    // Add the series to a chart.
    let chart = OCKBarChart(
        title: "Back Pain",
        text: nil,
        tintColor: Colors.Blue.color,
        axisTitles: axisTitles,
        axisSubtitles: nil,
        dataSeries: [painBarSeries, medicationBarSeries])



### Updating Your Messages or Charts

CareKit's messages and charts are immutable objects, which means that you cannot change them after they are created. However, you can update your Insights scene by assigning a new array of insight items to the Insights view controller's `items` property, as shown below:

    insightsViewController.items = [message, chart]

CareKit automatically populates the scene with the new charts and messages.

### Putting It All Together

The following sample code shows the steps needed to update an Insights view controller with a message and the data gathered from the sample code in [Accessing Care Plan Data](../AccessingCarePlanData/AccessingCarePlanData.html).


    // Wait until all the data is gathered, then process the results.
    dispatch_group_notify(gatherDataGroup, mainQueue) {
    
        // Generate the labels and data
        let dateStrings = completionData.map({(entry) -> String in
    
            guard let date = calendar.dateFromComponents(entry.dateComponent) else {
                fatalError("Unable to create date")
            }
    
            return NSDateFormatter.localizedStringFromDate(date, dateStyle: .ShortStyle, timeStyle: .NoStyle)
        })
    
        let completionValues = completionData.map({ (entry) -> Double in
            return entry.value
        })
    
        let completionValueLabels = completionValues.map({ (value) -> String in
            return NSNumberFormatter.localizedStringFromNumber(value, numberStyle: .PercentStyle)
        })
    
        let rawStressValues = completionData.map({ (entry) -> Double? in
            return stressAssessmentData[entry.dateComponent]
        })
    
        let stressValues = rawStressValues.map({ (valueOrNil) -> Double in
            guard let value = valueOrNil else {
                return 0.0
            }
    
            // Scale to match the completion values
            return value / 10.0
        })
    
        let stressValueLabels = rawStressValues.map({ (valueOrNil) -> String in
            guard let value = valueOrNil else {
                return ""
            }
    
            return NSNumberFormatter.localizedStringFromNumber(value, numberStyle: .DecimalStyle)
        })
    
        // Create the series
    
        let completionSeries = OCKBarSeries(
            title: "Treatment Plan Completed",
            values: completionValues,
            valueLabels: completionValueLabels,
            tintColor: UIColor.blueColor())
    
        let stressAssessmentSeries = OCKBarSeries(
            title: "Stress Assessment",
            values: stressValues,
            valueLabels: stressValueLabels,
            tintColor: UIColor.redColor())
    
        // Create the chart
    
        let chart = OCKBarChart(
            title: "Treatment Plan",
            text: "Compliance and Stress",
            tintColor: UIColor.greenColor(),
            axisTitles: dateStrings,
            axisSubtitles: nil,
            dataSeries: [completionSeries, stressAssessmentSeries])
    
        // Create the message
    
        let averageCompliance = completionValues.reduce(0.0, combine: +) / Double(completionValues.count)
    
        let messageString = "Over the last week, you completed an average of \(NSNumberFormatter.localizedStringFromNumber(averageCompliance, numberStyle: .PercentStyle)) of your treatment plan per day."
    
        let message = OCKMessageItem(
            title: "Compliance Rate",
            text: messageString,
            tintColor: UIColor.blackColor(),
            messageType: .Alert)
    
        // Update the view controller
        insightViewController.items = [chart, message]
    }


## Creating Widgets<a name="widget"></a>

A widget is a key metric that is prominently displayed at the top of the Insights scene. A single widget consists of a title, short text or value, and color. A widget view controller can display up to three widgets. 

Widgets are typically linked to care plan activities, and are automatically updated. You can also base a widget on a custom value. For example, a widget view can display a value based on a user's activity, a value based on a user's assessment that has reached a threshold value, or a custom value like the outdoor air quality. 

The code samples below create two widgets, one for a stress assessment that is linked to an activity, and one for neck stretches.

### Creating a Widget that is Linked to an Activity

The code sample initializes an assessment activity, in this case one that tracks level of stress.

    // Initializing Stress Assessment
    let stressAssessment =
    OCKCarePlanActivity.assessment(withIdentifier: “stress”,
                                                      groupIdentifier: “Assessments”,
                                                      title: “Stress”,
                                                      text: “ResearchKit Survey”,
                                                      tintColor: .purple,
                                                      resultResettable: false,
                                                      schedule: schedule,
                                                      userInfo: nil,
                                                      optional: false)

A widget is created that is linked to the stress assessment by using the activity identifier `"stress"`. The widget is automatically updated based on most recent values from the stress activity and the thresholds you have set.  The `tintColor` is triggered by the threshold for the activity identifier `"stress"`.

    // Creating a Widget for Stress Assessments
    let stressWidget = OCKPatientWidget.defaultWidget(withActivityIdentifier:“stress”,
                                                      tintColor: .red) 
 
### Creating a Custom Widget
In this custom widget example, all the parameters are specified to describe "Neck Stretches", including the title, text, and color.

    // Creating a Widget for Neck Stretches
    let calculatedPercentage = “67%”
    let neckWidget = OCKPatientWidget.defaultWidget(withTitle: “Neck Stretches”,
                                                          text: calculatedPercentage,
                                                          tintColor: nil) 



### Displaying the Widgets in the Insights Scene
To display the stress assessment and neck stretches widgets you created, pass the widgets to the Insights view controller using the `patientWidgets` parameter.

    // Pass the Widgets When Creating the Insights View Controller
    let viewController = OCKInsightsViewController(insightsItems: insights,
                                                           patientWidgets: [stressWidget, neckWidget],
                                                           thresholds: nil,
                                                           store: store) 



## Creating Thresholds<a name="thresholds"></a>
The thresholds API lets you create two types of thresholds, adherence and numeric, that you can leverage in the Insights scene. 

* *Adherence* thresholds can be set for intervention activities.  
* *Numeric* thresholds can be set for both intervention and assessment activities. 

The care plan store notifies you each time a threshold is invoked. You can use a threshold notification to perform any type of logic, such as displaying a message or alert, or to changing a widget's color. For example, you can set a numeric threshold to display an alert if a user reports a Pain value of 7 or higher;  or set an adherence threshold to display an alert if the user reports taking medication only once in the day, when they should have taken it twice.

In Figure 2, the pain value has exceeded the threshold of 7. As a result, a threshold alert is displayed and the widget's color is set to red.
<center><img src="PresentingInsightsImages/InsightsThresholdAlert.png" style="border: solid #e0e0e0 1px;" width="310" alt="Insights scene with a threshold alert"/><figcaption>Figure 2: A Threshold Alert.</figcaption></center>


The code sample below demonstrates creating a numeric threshold.

    // Create Numeric Threshold for Assessment
    let stressThreshold =
    OCKCarePlanThreshold.numericThreshold(withValue: NSNumber(value: 7),
                type: .numericGreaterThan,
                upperValue: nil,
                title: “High stress level. Try to do some relaxation exercises to reduce stress.”) 


The code sample below shows creating an adherence threshold.

    // Create Adherence Threshold for Intervention
    let breathingExercisesThreshold =
    OCKCarePlanThreshold.adherenceThreshold(withValue: NSNumber(value: 2),
                title: “Remember to complete your breathing exercises.”) 



## Creating Documents<a name="documents"></a>

CareKit lets you create HTML and PDF reports that are suitable for export or to be sent to the care team, family, or friends. Documents consist of a title, a page header, and one or more elements, which can include:

* Subtitles
* Paragraphs
* Images
* Charts
* Tables

To create a document, follow these steps:

1. Create the document elements.
2. Create the document using these elements.
3. Access the document data in HTML or PDF formats.

### Creating the Document Elements

The following sample code creates a subtitle element, a chart element, and a paragraph element.


    let subheadElement = OCKDocumentElementSubtitle(subtitle: "Weekly Summary")
    
    let chartElement = OCKDocumentElementChart(chart: chart)
    
    let paragraphElement = OCKDocumentElementParagraph(content: "Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet.")


**Note:** The `OCKDocumentElementChart` class lets you use CareKit charts in your documents, which means that you can use the same chart in both your reports and your Insights scene.

### Creating the Document

With the document elements in hand, you can create the document and set its page headers, as shown below:

    let document = OCKDocument(title: "Weekly Update", elements: [subheadElement, chartElement, paragraphElement])
    
    document.pageHeader = "\(dateString) update for \(userName)"

### Accessing the Document Data

After you have created a valid document object, you can access the HTML or create PDF data from the document.  Access an HTML version of the document through the document's `HTMLContent` property. Create a PDF version of the document by calling the document's `createPDFDataWithCompletion:` method.

The code sample below creates a PDF version of the document.

    document.createPDFDataWithCompletion { (PDFData, errorOrNil) in
        if let error = errorOrNil {
            // perform proper error checking here...
            fatalError(error.localizedDescription)
        }
    
        // Do something with the PDF data here...
    }


**Note:** The callback block's `PDFData` parameter contains an `NSData` object. For more information on working with NSData objects, see [NSData Class Reference](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSData_Class/).


### Document Privacy
After generating a document, it can be printed or shared; however, CareKit does not provide this functionality. User privacy should be considered when exposing such features in apps that use CareKit. For more information, please see the [Secure Coding Guide.](https://developer.apple.com/library/ios/documentation/Security/Conceptual/SecureCodingGuide/Introduction.html)


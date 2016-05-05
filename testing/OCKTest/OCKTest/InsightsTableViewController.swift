/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


import CareKit


class InsightsTableViewController: UITableViewController {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Many Bar Charts"
            case 1:
                cell.textLabel?.text = "Many Bar Series"
            case 2:
                cell.textLabel?.text = "Many Axes Bar Chart"
            case 3:
                cell.textLabel?.text = "Messages"
            case 4:
                cell.textLabel?.text = "Messages & Charts with Edge Indicators"
            case 5:
                cell.textLabel?.text = "Custom Charts"
            case 6:
                cell.textLabel?.text = "Custom Scales"
            default:
                cell.textLabel?.text = nil
            }
            return cell
        } else {
            return UITableViewCell.init()
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        if indexPath.row == 0 {
            
            // Many Charts
            
            let chart1Series1 = OCKBarSeries.init(title: "Chart #1 Series #1", values: [20,04,60,40], valueLabels: ["20","04","60","40"], tintColor: UIColor.cyanColor())
            let chart1Series2 = OCKBarSeries.init(title: "Chart #1 Series #2", values: [5,15,35,16], valueLabels: ["5","15","35","16"], tintColor: UIColor.magentaColor())
            let chart1 = OCKBarChart.init(title: "Chart #1", text: "Chart #1 Description", tintColor: UIColor.grayColor(), axisTitles: ["ABC","DEF","GHI","JKL"], axisSubtitles: ["123","456","789","012"], dataSeries: [chart1Series1, chart1Series2])
            
            let chart2Series1 = OCKBarSeries.init(title: "", values: [2,4], valueLabels: ["2","4"], tintColor: nil)
            let chart2Series2 = OCKBarSeries.init(title: "", values: [3,1], valueLabels: ["3","1"], tintColor: UIColor.brownColor())
            let chart2Series3 = OCKBarSeries.init(title: "", values: [1,4], valueLabels: ["1","4"], tintColor: UIColor.grayColor())
            let chart2Series4 = OCKBarSeries.init(title: "", values: [9,0], valueLabels: ["9","0"], tintColor: UIColor.blackColor())
            let chart2 = OCKBarChart.init(title: "Chart #2", text: "Chart #2 has no bar series titles and no subtitles", tintColor: nil , axisTitles: ["X","Y"], axisSubtitles: nil, dataSeries: [chart2Series1,chart2Series2, chart2Series3, chart2Series4])
            
            let chart3Series1 = OCKBarSeries.init(title: "No text/title", values: [1000,2000,6000,4000], valueLabels: ["1000","2000","6000","4000"], tintColor: UIColor.purpleColor())
            let chart3Series2 = OCKBarSeries.init(title: "No Axes", values: [1500,1500,1500,1500], valueLabels: ["1500","1500","1500","1500"], tintColor: UIColor.orangeColor())
            let chart3 = OCKBarChart.init(title: nil, text: nil, tintColor: UIColor.clearColor(), axisTitles: nil, axisSubtitles: nil, dataSeries: [chart3Series1, chart3Series2])
            
            let chart4Series1 = OCKBarSeries.init(title: "Series #1", values: [1], valueLabels: ["1"], tintColor: UIColor.cyanColor())
            let chart4Series2 = OCKBarSeries.init(title: "Series #2", values: [2], valueLabels: ["2"], tintColor: UIColor.magentaColor())
            let chart4Series3 = OCKBarSeries.init(title: "Series #3", values: [3], valueLabels: ["3"], tintColor: UIColor.orangeColor())
            let chart4Series4 = OCKBarSeries.init(title: "Series #4", values: [4], valueLabels: ["4"], tintColor: nil)
            let chart4Series5 = OCKBarSeries.init(title: "Series #5", values: [5], valueLabels: ["5"], tintColor: UIColor.yellowColor())
            let chart4Series6 = OCKBarSeries.init(title: "Series #6", values: [6], valueLabels: ["6"], tintColor: UIColor.redColor())
            let chart4Series7 = OCKBarSeries.init(title: "Series #7", values: [7], valueLabels: ["7"], tintColor: UIColor.purpleColor())
            let chart4 = OCKBarChart.init(title: "Chart #4", text: "Chart #4 Description\n spans over two lines", tintColor: UIColor.cyanColor(), axisTitles: ["A"], axisSubtitles: ["a"],  dataSeries: [chart4Series1, chart4Series2, chart4Series3, chart4Series4, chart4Series5, chart4Series6, chart4Series7])
            

            let chart5Series1 = OCKBarSeries.init(title: "Zero", values: [0], valueLabels: ["0"], tintColor: UIColor.redColor())
            let chart5Series2 = OCKBarSeries.init(title: "Zero", values: [0], valueLabels: ["0"], tintColor: UIColor.greenColor())
            let chart5 = OCKBarChart.init(title: "Chart #5", text: "Chart #5 Description\n spans over two lines", tintColor: UIColor.greenColor(), axisTitles: ["A","B"], axisSubtitles: ["abcdefgh","pqrstuvwxyz"], dataSeries: [chart5Series1, chart5Series2])
            
            let insightsDashboardViewController = OCKInsightsViewController.init(insightItems: [chart1, chart2, chart3, chart4, chart5], headerTitle:  "Insights Dashboard\nThis line should be hidden", headerSubtitle: "Many Bar Charts Here\nSubtitle can have two lines\nBut not three")
            self.navigationController?.pushViewController(insightsDashboardViewController, animated: true)
        
        } else if indexPath.row == 1 {
            
            // Many Series in a Chart
            
            let chart1Series1 = OCKBarSeries.init(title: "Chart #1 Series #1", values: [1,5], valueLabels: ["1","5"], tintColor: UIColor.brownColor())
            let chart1Series2 = OCKBarSeries.init(title: "Chart #1 Series #2", values: [5,10], valueLabels: ["5","10"], tintColor: UIColor.blackColor())
            let chart1Series3 = OCKBarSeries.init(title: "Chart #1 Series #3", values: [0.4,00.10], valueLabels: ["0.4","00.10"], tintColor: nil)
            let chart1Series4 = OCKBarSeries.init(title: "Chart #1 Series #4", values: [15,2], valueLabels: ["15","2"], tintColor: UIColor.grayColor())
            let chart1Series5 = OCKBarSeries.init(title: "Chart #1 Series #5", values: [3,7], valueLabels: ["3","7"], tintColor: UIColor.greenColor())
            let chart1Series6 = OCKBarSeries.init(title: "Chart #1 Series #6", values: [20.0000,35.0000], valueLabels: ["Long Label: 20.0000","Another Long Label: 35.0000"], tintColor: nil)
            let chart1Series7 = OCKBarSeries.init(title: "Chart #1 Series #7", values: [25,8], valueLabels: ["25","8"], tintColor: UIColor.cyanColor())
            let chart1Series8 = OCKBarSeries.init(title: "Chart #1 Series #8", values: [0,0], valueLabels: ["0","0"], tintColor: UIColor.blackColor())
            let chart1Series9 = OCKBarSeries.init(title: "Negative Values", values: [-30,-40], valueLabels: ["-30","-40"], tintColor: nil)
            
            let chart1 = OCKBarChart.init(title: "Chart #1", text: "Chart #1 Description", tintColor: UIColor.grayColor(), axisTitles: ["Title #1","Title #2"], axisSubtitles: ["Subtitle #1","Subtitle #2"], dataSeries: [chart1Series1, chart1Series2, chart1Series3, chart1Series4, chart1Series5, chart1Series6, chart1Series7, chart1Series8, chart1Series9])
            
            let insightsDashboardViewController = OCKInsightsViewController.init(insightItems: [chart1])
            self.navigationController?.pushViewController(insightsDashboardViewController, animated: true)
            
        } else if indexPath.row == 2 {
            
            // Many Axes in a Chart 
            
            let barSeries1 = OCKBarSeries.init(title: "Me", values: [90000,98000,101000,80000,75000,100000,100100,120000,110000,115000,120000,125000,90000,98000,101000], valueLabels: ["90K","98K","101K","80K","75K","100K","100K","120K","110K","115K","120K","125K","90K","98K","101K"], tintColor: UIColor.purpleColor())
            let barSeries2 = OCKBarSeries.init(title: "US Average", values: [80000,90000,100000,120000,120000,130000,150000,120000,130000,135000,143000,145000], valueLabels: ["80K","90K","100K","120K","120K","130K","150K","120K","130K","135K","143K","145K"], tintColor: UIColor.brownColor())
            let barSeries3 = OCKBarSeries.init(title: "World Average", values: [120000,110000,130000,150000,120000,130000,135000,143000,145000,120000,130000,135000,143000,145000, 120000,130000,135000,143000,145000], valueLabels: ["120K","110K","130K","150K","120K","130K","135K","143K","145K","120K","130K","135K","143K","145K","120K","130K","135K","143K","145K"], tintColor: nil)
            let barSeries4 = OCKBarSeries.init(title: "Canada Average", values: [80000,90000,100000,120000,130000,135000,143000,145000,120000,120000,130000,150000,80000,90000,100000,120000,130000,135000,145000,120000,120000,130000,150000], valueLabels: ["80K","90K","100K","120K","130K","135K","143K","145K","120K","120K","130K","150K","80K","90K","100K","120K","130K","135K","145K","120K","120K","130K","150K"], tintColor: UIColor.yellowColor())
            let chart1 = OCKBarChart.init(title: "Walking", text: "Step Count", tintColor: UIColor.grayColor(), axisTitles: ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec","Jan'17","Feb'17","Mar'17","Apr'17","May'17","Jun'17","Jul'17","Aug'17","Sep'17","Oct'17","Nov'17","Dec'17"], axisSubtitles: nil,  dataSeries: [barSeries1, barSeries2,barSeries3,barSeries4])
            let insightsDashboardViewController = OCKInsightsViewController.init(insightItems: [chart1])
            insightsDashboardViewController.headerSubtitle = "This is a subtitle without a title"
            self.navigationController?.pushViewController(insightsDashboardViewController, animated: true)
       
        } else if indexPath.row == 3 {

            // Messages
            
            let messageItem1 = OCKMessageItem.init(title: "Alert", text: "This is an alert", tintColor: nil, messageType: OCKMessageItemType.Alert)
            let messageItem2 = OCKMessageItem.init(title: "Tip", text: "This is a helpful tip", tintColor: nil, messageType: OCKMessageItemType.Tip)
            let messageItem3 = OCKMessageItem.init(title: nil, text: nil, tintColor: nil, messageType: OCKMessageItemType.Alert)
            let messageItem4 = OCKMessageItem.init(title: nil, text: nil, tintColor: nil, messageType: OCKMessageItemType.Tip)
            let messageItem5 = OCKMessageItem.init(title: "Red Alert", text: "This is a red alert", tintColor: UIColor.redColor(), messageType: OCKMessageItemType.Alert)
            let messageItem6 = OCKMessageItem.init(title: "Green Tip", text: "This is a green tip", tintColor:  UIColor.greenColor(), messageType: OCKMessageItemType.Tip)
            let messageItem7 = OCKMessageItem.init(title: "This is an alert with a very long title", text: LoremIpsum, tintColor: UIColor.init(hue: 0.4, saturation: 0.5, brightness: 0.3, alpha: 1), messageType: OCKMessageItemType.Alert)
            let messageItem8 = OCKMessageItem.init(title: "This is a tip with an even longer title than the alert", text: "The text is long but not long enough. Blah Blah", tintColor:  UIColor.init(red: 2, green: 0.4, blue: 0, alpha: 1), messageType: OCKMessageItemType.Tip)
            let insightsDashboardViewController = OCKInsightsViewController.init(insightItems: [messageItem1, messageItem2, messageItem3, messageItem4, messageItem5, messageItem6, messageItem7, messageItem8])
            self.navigationController?.pushViewController(insightsDashboardViewController, animated: true)
        
        } else if indexPath.row == 4 {
            
            // Messages + Charts
            
            let messageItem1 = OCKMessageItem.init(title: "Alert", text: "This is an alert", tintColor: nil, messageType: OCKMessageItemType.Alert)
            let messageItem2 = OCKMessageItem.init(title: "Tip", text: "This is a tip", tintColor: nil, messageType: OCKMessageItemType.Tip)
            let series1 = OCKBarSeries.init(title: "Chart #1 Series #1", values: [20,04,60,40,50,60], valueLabels: ["20","04","60","40","50","60"], tintColor: UIColor.blackColor())
            let series2 = OCKBarSeries.init(title: "Chart #1 Series #2", values: [5,15,35,16,100,20], valueLabels: ["5","15","35","16","100","20"], tintColor: UIColor.orangeColor())
            let chart1 = OCKBarChart.init(title: "Chart #1", text: "Chart #1 Description", tintColor: UIColor.grayColor(), axisTitles: ["ABC","DEF","GHI","JKL","MNO"], axisSubtitles: ["123","456","789","012"], dataSeries: [series1, series2])
            let messageItem3 = OCKMessageItem.init(title: "Another Alert", text: nil, tintColor: UIColor.orangeColor(), messageType: OCKMessageItemType.Alert)
            let messageItem4 = OCKMessageItem.init(title: "Another Tip", text: nil, tintColor:  UIColor.greenColor(), messageType: OCKMessageItemType.Tip)
            let insightsDashboardViewController = OCKInsightsViewController.init(insightItems: [messageItem1, messageItem2,chart1, messageItem3, messageItem4])
            insightsDashboardViewController.headerTitle = "Dashboard with Messages and Bar Charts"
            insightsDashboardViewController.showEdgeIndicators = true
            self.navigationController?.pushViewController(insightsDashboardViewController, animated: true)
     
        } else if indexPath.row == 5 {
        
            // Custom Charts
            
            let chart1 = CustomChart.init(chartSize: 300, bubbleSize: 100)
            chart1.tintColor = UIColor.purpleColor()
            chart1.title = "1. Custom Chart"

            let chart2 = CustomChart.init(chartSize: 150, bubbleSize: 50)
            chart2.tintColor = UIColor.blueColor()
            chart2.title = "2. Custom Chart"

            let chart3 = CustomChart.init(chartSize: 250, bubbleSize: 20)
            chart3.tintColor = UIColor.orangeColor()
            chart3.title = "3. Custom Chart"
            
            let insightsDashboardViewController = OCKInsightsViewController.init(insightItems: [chart1, chart2, chart3])
            insightsDashboardViewController.headerTitle = "Dashboard with Custom Chart"
            insightsDashboardViewController.showEdgeIndicators = true
            self.navigationController?.pushViewController(insightsDashboardViewController, animated: true)
       
        } else if indexPath.row == 6 {
            
            // Custom Scales
            
            let chart1Series1 = OCKBarSeries.init(title: "👍", values: [0,20], valueLabels: ["0","20"], tintColor: UIColor.cyanColor())
            let chart1Series2 = OCKBarSeries.init(title: "👫", values: [5,15], valueLabels: ["5","15"], tintColor: UIColor.magentaColor())
            let chart1 = OCKBarChart.init(title: "Only Min Scale", text: "Minimum Scale = -10", tintColor: UIColor.cyanColor(), axisTitles: ["α","β"], axisSubtitles: ["😀","🤗"], dataSeries: [chart1Series1, chart1Series2], minimumScaleRangeValue: -10, maximumScaleRangeValue: nil)
            
            let chart2Series1 = OCKBarSeries.init(title: "比", values: [20,50], valueLabels: ["20","50"], tintColor: nil)
            let chart2Series2 = OCKBarSeries.init(title: "诶", values: [-10,2], valueLabels: ["-10","2"], tintColor: UIColor.purpleColor())
            let chart2 = OCKBarChart.init(title: "Only Max Scale", text: "Maximum Scale = 100", tintColor: UIColor.clearColor(), axisTitles: ["艾尺","艾"], axisSubtitles: ["艾丝","提"], dataSeries: [chart2Series1, chart2Series2], minimumScaleRangeValue: nil, maximumScaleRangeValue: 100)
            
            let chart3Series1 = OCKBarSeries.init(title: "غ", values: [1000.2,1002], valueLabels: ["1000.2","1002"], tintColor: UIColor.brownColor())
            let chart3Series2 = OCKBarSeries.init(title: "ظ", values: [1003,1005], valueLabels: ["1003","1005"], tintColor: UIColor.redColor())
            let chart3 = OCKBarChart.init(title: "Min & Max Scale", text: "Min = 1000, Max = 1005", tintColor: UIColor.orangeColor(), axisTitles: ["ت","ش"], axisSubtitles: ["ض","ذ"], dataSeries: [chart3Series1, chart3Series2], minimumScaleRangeValue: 1000, maximumScaleRangeValue: 1005)
            
            let chart4Series1 = OCKBarSeries.init(title: "ц", values: [50, 100, 150, 200, 250 ], valueLabels: ["50","100","150","200","250"], tintColor: UIColor.darkGrayColor())
            let chart4 = OCKBarChart.init(title: "Min > Max", text: "Min = 200, Max = 100", tintColor: UIColor.darkGrayColor(), axisTitles: ["ѯ","ѱ","ѣ","ѭ","ѩ"], axisSubtitles: nil, dataSeries: [chart4Series1], minimumScaleRangeValue: 200, maximumScaleRangeValue: 100)

            let chart5Series1 = OCKBarSeries.init(title: "अं", values: [-10000, -100000, -150000, -200000], valueLabels: ["-10000","-100000","-150000","-200000"], tintColor: nil)
            let chart5 = OCKBarChart.init(title: "Min & Max Negative", text: "Min = -200000, Max = -10000", tintColor: nil, axisTitles: ["क","ख","ग","घ"], axisSubtitles: nil, dataSeries: [chart5Series1], minimumScaleRangeValue: -200000, maximumScaleRangeValue: -10000)

            let chart6Series1 = OCKBarSeries.init(title: "A", values: [NSNumber(longLong:Int64.min), NSNumber(longLong:Int64.max)], valueLabels: ["Int64.min","Int64.max"], tintColor: UIColor.greenColor())
            let chart6 = OCKBarChart.init(title: "Min & Max Int values", text: "Min = Int64.min, Max = Int64.max", tintColor: UIColor.greenColor(), axisTitles: nil, axisSubtitles: ["Min","Max"], dataSeries: [chart6Series1], minimumScaleRangeValue: NSNumber(longLong:Int64.min), maximumScaleRangeValue: NSNumber(longLong:Int64.max))
            
            let insightsDashboardViewController = OCKInsightsViewController.init(insightItems: [chart1, chart2, chart3, chart4, chart5, chart6])
            insightsDashboardViewController.headerTitle = "Minimum/Maximum Scales"
            insightsDashboardViewController.headerSubtitle = "With Edge Indicators"
            insightsDashboardViewController.showEdgeIndicators = true
            self.navigationController?.pushViewController(insightsDashboardViewController, animated: true)
       
        }
        
    }
    

}

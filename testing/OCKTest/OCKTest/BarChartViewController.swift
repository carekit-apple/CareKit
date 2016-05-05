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


class BarChartViewController: UIViewController, OCKGroupedBarChartViewDataSource {

    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chartWidth = UIScreen.mainScreen().bounds.width - 20
        
        scrollView.contentSize = CGSize(width: self.view.frame.width, height: 2000)
        let multiColorChartView = OCKGroupedBarChartView.init(frame: CGRectMake(5, 0, chartWidth, 600))
        multiColorChartView.accessibilityLabel = "multiColorChartView"
        multiColorChartView.animateWithDuration(4)
        multiColorChartView.backgroundColor = UIColor.init(hue: 0.85, saturation: 0.1, brightness: 0.8, alpha: 0.3)
        multiColorChartView.dataSource = self
        scrollView.addSubview(multiColorChartView)
        
        let emptyChartView = OCKGroupedBarChartView.init(frame: CGRectMake(5, 610, chartWidth, 20))
        emptyChartView.accessibilityLabel = "emptyChartView"
        emptyChartView.backgroundColor = UIColor.init(hue: 0.1, saturation: 0.8, brightness: 0.5, alpha: 0.8)
        scrollView.addSubview(emptyChartView)
        
        let twoSeriesChartView = OCKGroupedBarChartView.init(frame: CGRectMake(5, 640, chartWidth, 500))
        twoSeriesChartView.accessibilityLabel = "twoSeriesChartView"
        twoSeriesChartView.backgroundColor = UIColor.init(hue: 0.05, saturation: 0.1, brightness: 0.9, alpha: 0.3)
        twoSeriesChartView.dataSource = self
        twoSeriesChartView.animateWithDuration(1)
        scrollView.addSubview(twoSeriesChartView)

        let negativeValuesChartView = OCKGroupedBarChartView.init(frame: CGRectMake(5, 1200, chartWidth, 600))
        negativeValuesChartView.backgroundColor = UIColor.init(hue: 0.66, saturation: 0.2, brightness: 0.9, alpha: 0.2)
        negativeValuesChartView.accessibilityLabel = "negativeValuesChartView"
        negativeValuesChartView.dataSource = self
        scrollView.addSubview(negativeValuesChartView)
        
    }

    func numberOfDataSeriesInChartView(chartView: OCKGroupedBarChartView) -> Int {
        let chartName = chartView.accessibilityLabel
        if chartName == "multiColorChartView" { return 30 } else if chartName == "negativeValuesChartView" { return 4 } else { return 2 }
    }
    
    func numberOfCategoriesPerDataSeriesInChartView(chartView: OCKGroupedBarChartView) -> Int {
        let chartName = chartView.accessibilityLabel
        if chartName == "multiColorChartView" { return 1 } else if chartName == "negativeValuesChartView" { return 5 } else { return 8 }
    }
    
    func maximumScaleRangeValueOfChartView(chartView: OCKGroupedBarChartView) -> NSNumber? {
        if chartView.accessibilityLabel == "multiColorChartView" { return NSNumber(int: 1500) }
        return nil
    }
    
    func minimumScaleRangeValueOfChartView(chartView: OCKGroupedBarChartView) -> NSNumber? {
        if chartView.accessibilityLabel == "negativeValuesChartView" { return NSNumber(int: -40) }
        return nil
    }

    func chartView(chartView: OCKGroupedBarChartView, valueForCategoryAtIndex categoryIndex: UInt, inDataSeriesAtIndex dataSeriesIndex: UInt) -> NSNumber {
        let chartName = chartView.accessibilityLabel
        if chartName == "multiColorChartView" {
            return (categoryIndex + 1) * (dataSeriesIndex*dataSeriesIndex + 1)
        } else if chartName == "negativeValuesChartView" {
            var value:Int = (Int)((categoryIndex + 1) * (dataSeriesIndex + 1))
            value = value * -1
            return value
        } else {
            return NSNumber(float: Float(categoryIndex) * 0.04)
        }
    }
    
    func chartView(chartView: OCKGroupedBarChartView, titleForCategoryAtIndex categoryIndex: UInt) -> String? {
          return "Title" + String(categoryIndex)
    }

    func chartView(chartView: OCKGroupedBarChartView, subtitleForCategoryAtIndex categoryIndex: UInt) -> String? {
        return String(categoryIndex) + " SubTitle"
    }
    
    func chartView(chartView: OCKGroupedBarChartView, colorForDataSeriesAtIndex dataSeriesIndex: UInt) -> UIColor {
        let hue = ((CGFloat)(dataSeriesIndex + 1)) * 3 / 100.0
        return UIColor.init(hue: hue, saturation: 0.7, brightness: 0.8, alpha: 1)
    }
    
    func chartView(chartView: OCKGroupedBarChartView, nameForDataSeriesAtIndex dataSeriesIndex: UInt) -> String {
        return String(dataSeriesIndex) + " Series"
    }
    
    func chartView(chartView: OCKGroupedBarChartView, valueStringForCategoryAtIndex categoryIndex: UInt, inDataSeriesAtIndex dataSeriesIndex: UInt) -> String? {
        return "Val: " + String(chartView.dataSource!.chartView(chartView, valueForCategoryAtIndex: categoryIndex, inDataSeriesAtIndex: dataSeriesIndex))
    }
}

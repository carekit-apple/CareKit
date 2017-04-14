/*
 Copyright (c) 2016, Troy Tsubota. All rights reserved.
 
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

class StoryboardInsightsViewController: OCKInsightsViewController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let messageItem1 = OCKMessageItem(title: "Alert", text: "This is a storyboard alert", tintColor: nil, messageType: .alert)
        let messageItem2 = OCKMessageItem(title: "Tip", text: "This is a storyboard tip", tintColor: nil, messageType: .tip)
        let series1 = OCKBarSeries(title: "Storyboard Series #1", values: [20,04,60,40,50,60], valueLabels: ["20","04","60","40","50","60"], tintColor: .black)
        let series2 = OCKBarSeries(title: "Storyboard Series #2", values: [5,15,35,16,100,20], valueLabels: ["5","15","35","16","100","20"], tintColor: .orange)
        let chart1 = OCKBarChart(title: "Storyboard Chart #1", text: "Chart #1 Description", tintColor: .gray, axisTitles: ["ABC","DEF","GHI","JKL","MNO"], axisSubtitles: ["123","456","789","012"], dataSeries: [series1, series2])
        let messageItem3 = OCKMessageItem(title: "Another Storyboard Alert", text: nil, tintColor: .orange, messageType: .alert)
        let messageItem4 = OCKMessageItem(title: "Another Storyboard Tip", text: nil, tintColor:  .green, messageType: .tip)
        
        items = [messageItem1, messageItem2,chart1, messageItem3, messageItem4]
    }
    
}

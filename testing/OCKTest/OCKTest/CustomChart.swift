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


class CustomChart: OCKChart {

    var chartSize: CGFloat
    var bubbleSize: CGFloat
    
    override func chartView() -> UIView {
        
        let chart = UIView.init()
        chart.backgroundColor = self.tintColor
        chart.layer.cornerRadius = self.chartSize / 2.0
        chart.layer.borderWidth = 5
        chart.layer.borderColor = UIColor.black.cgColor
        chart.translatesAutoresizingMaskIntoConstraints = false
        chart.heightAnchor.constraint(equalToConstant: self.chartSize).isActive = true
        
        let topLeftbubble = UIView.init()
        topLeftbubble.backgroundColor = UIColor.white
        topLeftbubble.layer.cornerRadius = self.bubbleSize / 2.0
        topLeftbubble.translatesAutoresizingMaskIntoConstraints = false
        chart.addSubview(topLeftbubble)
        topLeftbubble.heightAnchor.constraint(equalToConstant: self.bubbleSize).isActive = true
        topLeftbubble.widthAnchor.constraint(equalToConstant: self.bubbleSize).isActive = true
        topLeftbubble.topAnchor.constraint(equalTo: chart.topAnchor, constant: 50).isActive = true
        topLeftbubble.leftAnchor.constraint(equalTo: chart.leftAnchor, constant: 50).isActive = true

        let bottomRightBubble = UIView.init()
        bottomRightBubble.backgroundColor = UIColor.white
        bottomRightBubble.layer.cornerRadius = self.bubbleSize / 2.0
        bottomRightBubble.translatesAutoresizingMaskIntoConstraints = false
        chart.addSubview(bottomRightBubble)
        bottomRightBubble.heightAnchor.constraint(equalToConstant: self.bubbleSize).isActive = true
        bottomRightBubble.widthAnchor.constraint(equalToConstant: self.bubbleSize).isActive = true
        bottomRightBubble.bottomAnchor.constraint(equalTo: chart.bottomAnchor, constant: -50).isActive = true
        bottomRightBubble.rightAnchor.constraint(equalTo: chart.rightAnchor, constant: -50).isActive = true
        
        return chart
        
    }
    
    override class func animate(_ view: UIView, withDuration duration: TimeInterval)
    {
        UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions.autoreverse, animations: {
            view.alpha = 0
            }) { (success) in
                view.alpha = 1
        }
    }

    init(chartSize:CGFloat, bubbleSize: CGFloat) {
        self.chartSize = chartSize
        self.bubbleSize = bubbleSize
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // Default Values for Custom Chart
        self.chartSize = 300
        self.bubbleSize = 20
        super.init(coder: aDecoder)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let chart:CustomChart = super.copy(with: zone) as! CustomChart
        chart.chartSize = self.chartSize
        chart.bubbleSize = self.bubbleSize
        return chart
    }
}

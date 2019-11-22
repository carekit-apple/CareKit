/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
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

import UIKit

/// Interactable line graph. The difference between this and `OCKLineGraphLayer` is that this has the
/// ability to respond to touches
class OCKLinePlotView: OCKGradientPlotView<OCKLineLayer> {

    override func resetLayers() {
        let graphRect = graphBounds()
        let offsets = computeLineOffsets()
        resolveNumberOfLayers()
        dataSeries.enumerated().forEach { index, series in
            let layer = seriesLayers[index]
            layer.dataPoints = series.dataPoints
            layer.offset = offsets[index]
            layer.startColor = series.gradientStartColor ?? tintColor
            layer.endColor = series.gradientEndColor ?? tintColor
            layer.lineWidth = series.size
            layer.setPlotBounds(rect: graphRect)
            layer.frame = bounds
        }
    }

    // Adjust the x coordinates of the data series so that two identical lines are slightly offset, so as to be distinguishable.
    private func computeLineOffsets() -> [CGSize] {
        guard !dataSeries.isEmpty else { return [] }
        let spacing: CGFloat = 1.0
        let totalWidth = spacing * CGFloat(dataSeries.count - 1)
        let startOffset = -totalWidth / 2
        var offsets = [CGSize]()
        for index in 0..<dataSeries.count {
            offsets.append(CGSize(width: startOffset + spacing * CGFloat(index), height: 0))
        }
        return offsets
    }

    private func resolveNumberOfLayers() {
        while seriesLayers.count < dataSeries.count {
            let newLayer = OCKLineLayer()
            seriesLayers.append(newLayer)
            layer.addSublayer(newLayer)
        }
        while seriesLayers.count > dataSeries.count {
            let oldLayer = seriesLayers.removeLast()
            oldLayer.removeFromSuperlayer()
        }
    }
}

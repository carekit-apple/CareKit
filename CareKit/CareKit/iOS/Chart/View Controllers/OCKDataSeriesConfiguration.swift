/*
 Copyright (c) 2016-2025, Apple Inc. All rights reserved.
 
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
#if canImport(UIKit)

import CareKitStore
import UIKit

/// A configuration object that specifies which data to query and how the graph displays it.
public struct OCKDataSeriesConfiguration {
    /// A user-provided unique id for a task.
    public var taskID: String

    /// The title that will be used to represent this data series in the legend.
    public var legendTitle: String

    /// The first of two colors that will be used in the gradient when plotting the data.
    public var gradientStartColor: UIColor

    /// The second of two colors that will be used in the gradient when plotting the data.
    public var gradientEndColor: UIColor

    /// The marker size determines the size of the line, bar, or scatter plot elements. The precise behavior is different for each type of plot.
    /// - For line plots, it will be the width of the line.
    /// - For scatter plots, it will be the radius of the markers.
    /// - For bar plots, it will be the width of the bar.
    public var markerSize: CGFloat

    /// A closure that accepts as an argument a day's worth of events and returns a y-axis value for that day.
    @available(*, unavailable, message: "The aggregator is no longer available and will be removed in a future version of CareKit.")
    public var aggregator: OCKAdherenceAggregator! {
        fatalError("Property is unavailable")
    }

    let computeProgress: (OCKAnyEvent) -> LinearCareTaskProgress

    /// Initialize a new `OCKDataSeriesConfiguration`.
    ///
    /// - Parameters:
    ///   - taskID: A user-provided unique id for a task.
    ///   - legendTitle: The title that will be used to represent this data series in the legend.
    ///   - gradientStartColor: The first of two colors that will be used in the gradient when plotting the data.
    ///   - gradientEndColor: The second of two colors that will be used in the gradient when plotting the data.
    ///   - markerSize: The marker size determines the size of the line, bar, or scatter plot elements. The precise behavior varies by plot type.
    ///   - aggregator: A an aggregator that accepts as an argument a day's worth of events and returns a y-axis value for that day.
    @available(*, unavailable, renamed: "init(taskID:legendTitle:gradientStartColor:gradientEndColor:markerSize:computeProgress:)")
    public init(
        taskID: String,
        legendTitle: String,
        gradientStartColor: UIColor,
        gradientEndColor: UIColor,
        markerSize: CGFloat,
        aggregator: OCKAdherenceAggregator
    ) {
        fatalError("Unavailable")
    }

    /// Initialize a new `OCKDataSeriesConfiguration`.
    ///
    /// - Parameters:
    ///   - taskID: A user-provided unique id for a task.
    ///   - legendTitle: The title that will be used to represent this data series in the legend.
    ///   - gradientStartColor: The first of two colors that will be used in the gradient when plotting the data.
    ///   - gradientEndColor: The second of two colors that will be used in the gradient when plotting the data.
    ///   - markerSize: The marker size determines the size of the line, bar, or scatter plot elements. The precise behavior varies by plot type.
    ///   - computeProgress: Used to compute progress for an event.
    public init(
        taskID: String,
        legendTitle: String,
        gradientStartColor: UIColor,
        gradientEndColor: UIColor,
        markerSize: CGFloat,
        computeProgress: @escaping (OCKAnyEvent) -> LinearCareTaskProgress = { event in
            event.computeProgress(by: .summingOutcomeValues)
        }
    ) {
        self.taskID = taskID
        self.legendTitle = legendTitle
        self.gradientStartColor = gradientStartColor
        self.gradientEndColor = gradientEndColor
        self.markerSize = markerSize
        self.computeProgress = computeProgress
    }
}
#endif

//
//  SliderTaskViewConfiguration.swift
//  
//
//  Created by Dylan Li on 5/26/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//
//#if !os(watchOS)
//
//import Foundation
//import SwiftUI
//
///// Default data used to map data from an `OCKSliderTaskController` to a `CareKitUI.InstructionsTaskView`.
//public struct SliderTaskViewConfiguration {
//
//    /// The title text to display in the header.
//    public let title: String
//
//    /// The detail text to display in the header.
//    public let detail: String?
//
//    /// The instructions text to display under the header.
//    public let instructions: String?
//
//    /// The action to perform when the button is tapped.
//    public let action: (() -> Void)?
//
//    /// True if the labeled button is complete.
//    public let isComplete: Bool
//    
//    /// Image to display to the left of the slider.
//    public let minimumImage: Image? = nil
//    
//    /// Image to display to the right of the slider.
//    public let maximumImage: Image? = nil
//    
//    /// Value that the slider begins on.
//    public let initialValue: CGFloat = 5
//
//    /// The range that includes all possible values.
//    public let range: ClosedRange<CGFloat> = 0...10
//    
//    /// Value of the increment that the slider takes.
//    public let step: CGFloat = 1
//    
//    public let useDefaultSlider: Bool = true
//    
//    /// The source of truth for the current value of the slider
//    @State public var value: CGFloat = 5
//    
//    init(controller: OCKTaskControllerProtocol){
//        self.title = controller.title
//        self.detail = controller.event.map { OCKScheduleUtility.scheduleLabel(for: $0) } ?? ""
//        self.instructions = controller.instructions
//        self.isComplete = controller.isFirstEventComplete
//        self.action = controller.toggleActionForFirstEvent
//    }
//}
//#endif

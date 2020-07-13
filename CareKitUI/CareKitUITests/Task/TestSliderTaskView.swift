//
//  TestSliderTaskView.swift
//  
//
//  Created by Dylan Li on 7/9/20.
//

import CareKitUI
import SwiftUI
import XCTest

class TestNumericProgressTaskView: XCTestCase {

    func testDefaultInitializers() {
        _ = NumericProgressTaskView(title: Text(""), detail: Text(""), progress: Text(""), goal: Text(""), instructions: Text(""), isComplete: false)
        _ = NumericProgressTaskView( title: Text(""), detail: nil, progress: Text(""), goal: Text(""), instructions: nil, isComplete: false)
    }

    func testCustomInitializers() {
        _ = NumericProgressTaskView(instructions: nil, header: { EmptyView() }, content: { EmptyView() })
        _ = NumericProgressTaskView(progress: Text(""), goal: Text(""), instructions: nil, isComplete: false, header: { EmptyView() })
        _ = NumericProgressTaskView(title: Text(""), detail: nil, instructions: nil, content: { EmptyView() })
    }
}

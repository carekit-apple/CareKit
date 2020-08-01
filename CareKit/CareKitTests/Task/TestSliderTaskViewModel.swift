//
//  TestSliderTaskViewModel.swift
//
//
//  Created by Dylan Li on 7/27/20.
//  Copyright © 2020 NetReconLab. All rights reserved.
//

@testable import CareKit
@testable import CareKitStore
import CareKitUI
import Combine
import Foundation
import SwiftUI
import XCTest

class TestSliderTaskViewModel: XCTestCase {

    var controller: OCKSliderTaskController!
    var cancellable: AnyCancellable?

    override func setUp() {
        super.setUp()
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        controller = .init(storeManager: .init(wrapping: store))
    }

    func testViewModelCreation() {
        let taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        let event = taskEvents.first?.first
        controller.taskEvents = taskEvents
        let updated = expectation(description: "view model updated")

        cancellable = controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertEqual(event?.task.title, viewModel.title)
                XCTAssertEqual(OCKScheduleUtility.scheduleLabel(for: event), viewModel.detail)
                XCTAssertEqual(event?.task.instructions, viewModel.instructions)
                XCTAssertEqual(event?.outcome != nil, viewModel.isComplete)
                updated.fulfill()
            }

        wait(for: [updated], timeout: 1)
    }
}


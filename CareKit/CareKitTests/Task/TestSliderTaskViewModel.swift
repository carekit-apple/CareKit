
@testable import CareKit
@testable import CareKitStore
import CareKitUI
import Combine
import Foundation
import SwiftUI
import XCTest

class TestSliderTaskViewModel: XCTestCase {

    var controller: OCKSliderTaskController!
    var cancellables: Set<AnyCancellable> = []
    @State var value: CGFloat = 3

    override func setUp() {
        super.setUp()
        let store = OCKStore(name: "carekit-store", type: .inMemory)
        controller = .init(storeManager: .init(wrapping: store))
    }

    func testViewModelCreation() {
        let taskEvents = OCKTaskEvents.mock(eventsHaveOutcomes: false, occurrences: 1)
        controller.taskEvents = taskEvents
        let updated = expectation(description: "updated view model")

        controller.$viewModel
            .compactMap { $0 }
            .sink { viewModel in
                XCTAssertEqual("Doxylamine", viewModel.title)
                XCTAssertEqual("Take the tablet with a glass of water.", viewModel.instructions)
                XCTAssertEqual("1", viewModel.detail)
                XCTAssertEqual(false, viewModel.isComplete)
                updated.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [updated], timeout: 1)
    }
}


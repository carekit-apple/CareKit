/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
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

import XCTest

class UITestCatalogHomePage: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["test"]
        app.launch()
    }

    func testHomePageDisplaysCorrectly() {
        let catalogHomeScreen = OCKCatalogHomeScreen(app)

        // Verify the presence (on-screen) of the "CareKit Catalog" header
        XCTAssert(catalogHomeScreen.headerText.isHittable, "Can't find the header text")

        // Verify the presence (on-screen) of the task list table
        XCTAssert(catalogHomeScreen.taskTable.isHittable, "Can't find the task table")

        // Verify the expected number of tasks in the list upon launch
        // Task items only appear in cells, so we can count the number of cells as opposed to staticTexts
        // (which would include the section header text elements)
        let expectedTasksCount = 16
        XCTAssertEqual(catalogHomeScreen.taskTable.cells.count, expectedTasksCount)

    }

    // Navigate into every task in the catalog task list, then back to the home screen
    func testNavigateToAllTasks() {
        let catalogHomeScreen = OCKCatalogHomeScreen(app)
        let taskScreen = OCKCatalogTaskScreen(app)

        // Iterate over every task in the list view, tap the task, then return to the list
        let tasks = catalogHomeScreen.taskItems
        for task in tasks {
            task.tap()
            taskScreen.dismissScreen()
        }

    }
}

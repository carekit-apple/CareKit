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

/// Events pertaining to an OCKCalendarWeekViewDelegate
public protocol OCKCalendarWeekViewDelegate: class {
    
    /// Called when a button corresponding to a specific date was selected.
    ///
    /// - Parameters:
    ///   - calendar: The view that holds the button.
    ///   - date: The corresponding date that was selected.
    func calendarWeekView(_ calendar: OCKCalendarWeekView, didSelectDate date: Date, at index: Int)
}

/// A horizontal row of seven selectable completion rings and corresponding labels.
///
///     +--------------------------------------+
///     |  [title] [title] [title]     [title] |
///     |                                      |
///     |    o o     o o     o o         o o   |
///     |   o   o   o   o   o   o  ...  o   o  |
///     |    o o     o o     o o         o o   |
///     +--------------------------------------+
///
open class OCKCalendarWeekView: UIView {
    
    /// The week number displayed in the view.
    private var week: Int
    
    /// The year number displayed in the view.
    private var year: Int
    
    /// The index of the selected button in the view.
    public private (set) var selectedIndex: Int
    
    /// Holds the completion ring buttons in the view.
    private let stackView = UIStackView()
    
    /// Listens for events pertaining to the calendar view.
    public weak var delegate: OCKCalendarWeekViewDelegate?
    
    /// The completion ring buttons in the view. There will always be seven buttons corresponding
    /// to seven days in the displayed week.
    public private (set) lazy var completionRingButtons: [OCKCompletionRingButton] = {
        var rings = [OCKCompletionRingButton]()
        for i in 0..<7 {
            let ringButton = OCKCompletionRingButton()
            ringButton.handlesSelectionStateAutomatically = false
            ringButton.setState(.dimmed, animated: false)
            ringButton.addTarget(self, action: #selector(handleSelection(sender:)), for: .touchUpInside)
            rings.append(ringButton)
        }
        return rings
    }()
    
    /// The range of dates displayed in the completion ring buttons.
    public var dateRange: DateInterval {
        let start = Calendar.current.date(from: DateComponents(year: year, weekday: 1, weekOfYear: week))!
        let end = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }
    
    /// A view that displays seven interactable completion rings, each corresponding to a day in the week.
    /// The week is computed based on the provided date parameter.
    ///
    /// - Parameters:
    ///   - date: Will display the week of the provided dtae.
    public init(weekOf date: Date) {
        let currentDate = Calendar.current.dateComponents([.weekOfYear, .year], from: date)
        guard let week = currentDate.weekOfYear, let year = currentDate.year else {
            fatalError("Date parameter must have a set week and year.")
        }
        self.week = week
        self.year = year
        self.selectedIndex = 0
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        let currentDate = Calendar.current.dateComponents(Set([.weekOfYear, .year]), from: Date())
        self.week = currentDate.weekOfYear!
        self.year = currentDate.year!
        self.selectedIndex = 0
        super.init(coder: aDecoder)
        setup()
    }
    
    /// Set the completion state for each of the completion rings. A total of seven states must be passed in.
    ///
    /// - Parameters:
    ///   - states: States for each completion ring. A total of seven values should be passed in.
    ///   - animated: Flag indicating whether or not to animate the ring filling.
    public func setCompletionRingStates(_ states: [OCKCompletionRingButton.CompletionState], animated: Bool) {
        assert(states.count == 7, "You must pass exactly 7 values to set the ring values. Received \(states.count). [\(states)]")
        for (index, value) in states.enumerated() {
            completionRingButtons[index].setState(value, animated: animated)
        }
    }
    
    private func setup() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        preservesSuperviewLayoutMargins = true
        
        let spacing = directionalLayoutMargins.trailing * 1.5
        stackView.spacing = spacing
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: spacing),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -spacing),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        completionRingButtons.forEach { stackView.addArrangedSubview($0) }
        completionRingButtons.first?.sendActions(for: .touchUpInside)
        updateRingLabels()
    }
    
    @objc
    private func handleSelection(sender: OCKCompletionRingButton) {
        for ring in completionRingButtons where ring != sender {
            ring.isSelected = false
        }
        sender.isSelected = true
        guard let ringIndex = completionRingButtons.firstIndex(of: sender) else { fatalError("Unexpected button") }
        selectedIndex = ringIndex
        delegate?.calendarWeekView(self, didSelectDate: dateAt(index: ringIndex), at: ringIndex)
    }
    
    /// Select the completion ring that corresponds to the given date.
    ///
    /// - Parameter date: The date of the ring to select.
    public func selectDate(_ date: Date) {
        completionRingButtons[selectedIndex].isSelected = false
        if let ring = completionRingFor(date: date) {
            ring.isSelected = true
            selectedIndex = completionRingButtons.firstIndex(of: ring)!
        } else {
            displayWeek(of: date)
            selectDate(date)
        }
    }
    
    private func dateAt(index: Int) -> Date {
        let now = Date()
        var startComponents = DateComponents(year: year, weekday: 1, weekOfYear: week)
        startComponents.hour = Calendar.current.component(.hour, from: now)
        startComponents.minute = Calendar.current.component(.minute, from: now)
        startComponents.second = Calendar.current.component(.second, from: now)
        let startDate = Calendar.current.date(from: startComponents)!
        return Calendar.current.date(byAdding: .day, value: index, to: startDate)!
    }
    
    /// Get the completion ring that corresponds to a particular date.
    ///
    /// - Parameter date: The date that corresponds to the desired completion ring.
    /// - Returns: The completion ring that matches the given date.
    public func completionRingFor(date: Date) -> OCKCompletionRingButton? {
        for i in 0..<7 {
            if Calendar.current.isDate(dateAt(index: i), inSameDayAs: date) {
                return completionRingButtons[i]
            }
        }
        return nil
    }
    
    /// Display a given week. Each ring will correspond to one day in the week.
    ///
    /// - Parameter date: The date to display.
    public func displayWeek(of date: Date) {
        let dateComponents = Calendar.current.dateComponents([.weekOfYear, .year], from: date)
        guard let week = dateComponents.weekOfYear, let year = dateComponents.year else {
            fatalError("Date parameter must have a week and year.")
        }
        self.week = week
        self.year = year
        updateRingLabels()
    }
    
    private func updateRingLabels() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd"
        let start = Calendar.current.date(from: DateComponents(year: year, weekday: 1, weekOfYear: week))!
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: start)!
            completionRingButtons[i].setTitle(dateFormatter.string(from: date), for: .normal)
            completionRingButtons[i].setTitle(dateFormatter.string(from: date), for: .selected)
        }
    }
}

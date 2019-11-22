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
open class OCKWeekCalendarView: OCKView, OCKCalendarDisplayable {

    // MARK: Properties

    /// The currently selected date in the calendar.
    public private (set) var selectedDate = Date()

    /// Handles events related to an `OCKCalendarDisplayable` object.
    public weak var delegate: OCKCalendarViewDelegate?

    /// The date interval of the week currently being displayed.
    public private (set) var dateInterval = Calendar.current.dateIntervalOfWeek(for: Date())

    /// The completion ring buttons in the view. There will be one ring for each day in the `dateInterval`.
    public private (set) lazy var completionRingButtons: [OCKCompletionRingButton] = {
        var rings = [OCKCompletionRingButton]()
        let numberOfDays = Calendar.current.dateComponents([.day], from: dateInterval.start, to: dateInterval.end).day!
        for _ in 0...numberOfDays {
            let ringButton = OCKCompletionRingButton()
            ringButton.handlesSelection = false
            ringButton.setState(.dimmed, animated: false)
            ringButton.addTarget(self, action: #selector(handleSelection(sender:)), for: .touchUpInside)
            rings.append(ringButton)
        }
        return rings
    }()

    /// Holds the completion ring buttons in the view.
    private let stackView: OCKStackView = {
        let stackView = OCKStackView.horizontal()
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()

    // MARK: - Life Cycle

    /// A view that displays interactable completion rings for each day in a week. The week is computed based on the provided date parameter.
    /// - Parameters:
    ///   - date: Will display the week of the provided date.
    public init(weekOfDate date: Date) {
        self.dateInterval = Calendar.current.dateIntervalOfWeek(for: date)
        selectedDate = date
        super.init()
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Methods

    override func setup() {
        super.setup()
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            stackView.constraints(equalTo: layoutMarginsGuide, directions: [.horizontal]) +
            stackView.constraints(equalTo: self, directions: [.vertical])
        )

        completionRingButtons.forEach { stackView.addArrangedSubview($0) }
        completionRingButtons.first?.sendActions(for: .touchUpInside)
        updateRingLabels()
    }

    private func updateRingLabels() {
        let numberOfDays = Calendar.current.dateComponents([.day], from: dateInterval.start, to: dateInterval.end).day!
        for index in 0...numberOfDays {
            let date = Calendar.current.date(byAdding: .day, value: index, to: dateInterval.start)!
            completionRingButtons[index].label.text = dateFormatter.string(from: date)
        }
    }

    private func dateAt(index: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: index, to: dateInterval.start)!
    }

    @objc
    private func handleSelection(sender: UIControl) {
        for ring in completionRingButtons where ring != sender {
            ring.isSelected = false
        }
        sender.isSelected = true
        guard let ringIndex = (completionRingButtons as [UIControl]).firstIndex(of: sender) else { fatalError("Unexpected button") }
        selectedDate = dateAt(index: ringIndex)
        delegate?.calendarView(self, didSelectDate: selectedDate, at: ringIndex, sender: sender)
    }

    /// Select the completion ring that corresponds to the given date.
    /// - Parameter date: The date of the ring to select.
    public func selectDate(_ date: Date) {
        completionRingButtons.first(where: { $0.isSelected })?.isSelected = false
        if let ring = completionRingFor(date: date) {
            ring.isSelected = true
            selectedDate = date
        } else {
            showDate(date)
            selectDate(date)
        }
    }

    /// Get the completion ring that corresponds to a particular date.
    /// - Parameter date: The date that corresponds to the desired completion ring.
    /// - Returns: The completion ring that matches the given date.
    public func completionRingFor(date: Date) -> OCKCompletionRingButton? {
        let offset = abs(Calendar.current.dateComponents([.day], from: dateInterval.start, to: date).day!)
        guard offset < completionRingButtons.count else { return nil }
        return completionRingButtons[offset]
    }

    /// Display the week for the given date. Each ring will correspond to one day in the week.
    /// - Parameter date: The date to display.
    public func showDate(_ date: Date) {
        dateInterval = Calendar.current.dateIntervalOfWeek(for: date)
        updateRingLabels()
    }

    override open func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
        stackView.spacing = cachedStyle.dimension.directionalInsets1.leading
    }
}

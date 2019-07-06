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
import CareKitUI
import CareKitStore

internal class OCKBindableGridTaskView<Task: Equatable & OCKTaskConvertible, Outcome: Equatable & OCKOutcomeConvertible>:
OCKTaskGridView, OCKBindable, UICollectionViewDataSource {
    
    private var model: Model?
    
    private let scheduleFormatter = OCKScheduleFormatter<Task, Outcome>()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    public override init() {
        super.init()
        collectionView.dataSource = self
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        collectionView.dataSource = self
    }
    
    public func updateView(with model: [OCKEvent<Task, Outcome>]?, animated: Bool) {
        self.model = model
        updateViewWithTask(model?.first?.task)
        updateViewWithEvents(model)
    }
    
    private func updateViewWithTask(_ task: Task?) {
        guard let task = task?.convert() else {
            headerView.titleLabel.text = nil
            instructionsLabel.text = nil
            headerView.detailLabel.text = nil
            return
        }
        
        headerView.titleLabel.text = task.title
        instructionsLabel.text = task.instructions
    }
    
    private func updateViewWithEvents(_ events: [OCKEvent<Task, Outcome>]?) {
        headerView.detailLabel.text = scheduleFormatter.scheduleLabel(for: events ?? [])
        collectionView.reloadData()
    }
    
    // MARK: UICollectionViewDataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: defaultCellIdentifier, for: indexPath) as? DefaultCellType else {
            fatalError("Unsupported cell type.")
        }
        
        let event = model?[indexPath.row]
        
        // set label for completed state
        let completeDate = event?.outcome?.convert().createdAt
        let completeString = completeDate != nil ? timeFormatter.string(from: completeDate!) : nil
        cell.completionButton.setTitle(completeString, for: .selected)
    
        // set label for normal state to be the time of the event
        let incompleteString = event != nil ? scheduleFormatter.timeLabel(for: event!) : indexPath.row.description
        cell.completionButton.setTitle(incompleteString, for: .normal)

        cell.completionButton.isSelected = event?.outcome != nil
        return cell
    }
}

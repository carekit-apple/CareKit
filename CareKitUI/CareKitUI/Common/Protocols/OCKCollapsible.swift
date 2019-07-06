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

internal enum OCKCollapsibleState {
    case expanded, collapsed, complete
}

/// Can be completed. Implementer defines how to display the completed state.
internal protocol OCKCollapsible {
    func setCollapsedState(_ state: OCKCollapsibleState, animated: Bool)
}

internal protocol OCKCollapsibleView: class {
    var collapsedState: OCKCollapsibleState { get set }
    var collapsedViews: Set<UIView> { get }
    var expandedViews: Set<UIView> { get }
    var completeViews: Set<UIView> { get }
    var contentStackView: OCKStackView { get }
    var cardView: UIView { get }
    var collapserButton: OCKButton { get }
}

internal extension OCKCollapsibleView {
    
    func setViewCollapsedState(_ state: OCKCollapsibleState, animated: Bool) {
        guard state != collapsedState else { return }
        
        (collapserButton as? OCKCollapserButton)?.setDirectionFromState(state, animated: animated && collapsedState != .expanded)
        
        // hide / show views in content stack
        let allViews = completeViews.union(collapsedViews).union(expandedViews)
        var toShow: [UIView]
        var toHide: [UIView]
        switch state {
        case .expanded:
            toShow = Array(expandedViews)
            toHide = Array(allViews.subtracting(expandedViews))
        case .collapsed:
            toShow = Array(collapsedViews)
            toHide = Array(allViews.subtracting(collapsedViews))
        case .complete:
            toShow = Array(completeViews)
            toHide = Array(allViews.subtracting(completeViews))
        }
        
        toShow = toShow.filter { $0.isHidden }
        toHide = toHide.filter { !$0.isHidden }
        
        let toggleViewsBlock: () -> Void = { [weak self] in
            toHide.forEach {
                $0.isHidden = true
                $0.alpha = 0
            }
            
            toShow.forEach {
                $0.isHidden = false
                $0.alpha = 1
            }
            
            self?.cardView.alpha = state == .expanded ? 1 : OCKStyle.appearance.opacity1
        }
        
        animated ? UIView.animate(withDuration: OCKStyle.animation.stateChangeDuration, animations: toggleViewsBlock) : toggleViewsBlock()
        
        collapsedState = state
    }
}

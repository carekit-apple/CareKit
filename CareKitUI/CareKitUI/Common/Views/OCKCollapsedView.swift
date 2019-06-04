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

internal class OCKCollapsedView: UIView {
    
    private enum Const {
        static let bundle = Bundle(for: OCKCollapserButton.self)
    }
    
    public let headerView = OCKHeaderView()
    
    public let detailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: OCKStyle.assets.check, in: Const.bundle, compatibleWith: nil)?
            .withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .gray
        return imageView
    }()
    
    public init() {
        super.init(frame: .zero)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        styleSubviews()
        addSubviews()
        constrainSubviews()
    }
    
    private func styleSubviews() {
        preservesSuperviewLayoutMargins = true
    }
    
    private func addSubviews() {
        [headerView, detailImageView].forEach { addSubview($0) }
    }
    
    private func constrainSubviews() {
        [headerView, detailImageView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            detailImageView.widthAnchor.constraint(equalToConstant: OCKStyle.dimension.iconHeight1),
            detailImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            detailImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            detailImageView.leadingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: directionalLayoutMargins.trailing * 2)
        ])
    }
}

/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
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


#import "OCKCareCardDetailViewController.h"
#import "OCKCareCardDetailHeaderView.h"
#import "OCKCareCardInstructionsTableViewCell.h"
#import "OCKCareCardAdditionalInfoTableViewCell.h"
#import "OCKDefines_Private.h"


static const CGFloat HeaderViewHeight = 100.0;

@implementation OCKCareCardDetailViewController {
    OCKCareCardDetailHeaderView *_headerView;
    NSMutableArray<NSString *> *_sectionTitles;
    NSString *_instructionsSectionTitle;
    NSString *_additionalInfoSectionTitle;
}

- (instancetype)initWithIntervention:(OCKCarePlanActivity *)intervention {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _intervention = intervention;
        self.showEdgeIndicator = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareView];
    
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [UIView new];
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKCareCardDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    _headerView.showEdgeIndicator = _showEdgeIndicator;
    _headerView.intervention = _intervention;
    
    self.tableView.tableHeaderView = _headerView;
    
    [self createTableViewDataArray];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat height = [_headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    CGRect headerViewFrame = _headerView.frame;
    
    if (height != headerViewFrame.size.height) {
        headerViewFrame.size.height = height;
        _headerView.frame = headerViewFrame;
        self.tableView.tableHeaderView = _headerView;
    }
}

- (void)setShowEdgeIndicator:(BOOL)showEdgeIndicator {
    _showEdgeIndicator = showEdgeIndicator;
    _headerView.showEdgeIndicator = _showEdgeIndicator;
}


#pragma mark - Helpers

- (void)createTableViewDataArray {
    _sectionTitles = [NSMutableArray new];
    
    if (_intervention.instructions) {
        _instructionsSectionTitle = OCKLocalizedString(@"CARE_CARD_INSTRUCTIONS_SECTION_TITLE", nil);
        [_sectionTitles addObject:_instructionsSectionTitle];
    }
    
    if (_intervention.imageURL) {
        _additionalInfoSectionTitle = OCKLocalizedString(@"CARE_CARD_ADDITIONAL_INFO_SECTION_TITLE", nil);
        [_sectionTitles addObject:_additionalInfoSectionTitle];
    }
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sectionTitles.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sectionTitles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionTitle = _sectionTitles[indexPath.section];
    
    if ([sectionTitle isEqualToString:_instructionsSectionTitle]) {
        static NSString *InstructionsCellIdentifier = @"InstructionsCell";
        OCKCareCardInstructionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InstructionsCellIdentifier];
        if (!cell) {
            cell = [[OCKCareCardInstructionsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                               reuseIdentifier:InstructionsCellIdentifier];
        }
        cell.intervention = _intervention;
        return cell;
    } else if ([sectionTitle isEqualToString:_additionalInfoSectionTitle]) {
        static NSString *AdditionalInfoCellIdentifier = @"AdditionalInfoCell";
        OCKCareCardAdditionalInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AdditionalInfoCellIdentifier];
        if (!cell) {
            cell = [[OCKCareCardAdditionalInfoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                 reuseIdentifier:AdditionalInfoCellIdentifier];
        }
        cell.intervention = _intervention;
        return cell;
    }
    return nil;
}

@end

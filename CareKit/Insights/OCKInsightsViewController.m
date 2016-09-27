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


#import "OCKInsightsViewController.h"
#import "OCKInsightsTableViewHeaderView.h"
#import "OCKInsightsChartTableViewCell.h"
#import "OCKInsightsMessageTableViewCell.h"
#import "OCKChart.h"
#import "OCKHelpers.h"


static const CGFloat HeaderViewHeight = 60.0;

@interface OCKInsightsViewController() <UITableViewDelegate, UITableViewDataSource>

@end


@implementation OCKInsightsViewController {
    UITableView *_tableView;
    OCKInsightsTableViewHeaderView *_headerView;
    NSMutableArray *_constraints;
    BOOL _hasAnimated;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithInsightItems:(NSArray<OCKInsightItem *> *)items
                         headerTitle:(NSString *)headerTitle
                      headerSubtitle:(NSString *)headerSubtitle {
    self = [super init];
    if (self) {
        _items = OCKArrayCopyObjects(items);
        _headerTitle = [headerTitle copy];
        _headerSubtitle = [headerSubtitle copy];
        _hasAnimated = NO;
        _showEdgeIndicators = NO;
    }
    return self;
}

- (instancetype)initWithInsightItems:(NSArray<OCKInsightItem *> *)items {
    return [[OCKInsightsViewController alloc] initWithInsightItems:items
                                                       headerTitle:nil
                                                    headerSubtitle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    [self setUpConstraints];
    
    if (!_headerView) {
        _headerView = [[OCKInsightsTableViewHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
        _headerView.backgroundColor = _tableView.backgroundColor;
    }
    [self updateHeaderView];
    
    _tableView.estimatedRowHeight = 90.0;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    
    _tableView.sectionHeaderHeight = 0.0;
    _tableView.sectionFooterHeight = 5.0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_hasAnimated) {
        _hasAnimated = YES;
        
        for (UITableViewCell *cell in _tableView.visibleCells) {
            if ([cell isKindOfClass:[OCKInsightsChartTableViewCell class]]) {
                OCKInsightsChartTableViewCell *chartCell = (OCKInsightsChartTableViewCell *)cell;
                [chartCell animateWithDuration:1.0];
            }
        }
    }
}

- (void)setItems:(NSArray<OCKInsightItem *> *)items {
    _items = OCKArrayCopyObjects(items);
    [_tableView reloadData];
}

- (void)setHeaderTitle:(NSString *)headerTitle {
    _headerTitle = [headerTitle copy];
    [self updateHeaderView];
}

- (void)setHeaderSubtitle:(NSString *)headerSubtitle {
    _headerSubtitle = [headerSubtitle copy];
    [self updateHeaderView];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)updateHeaderView {
    _headerView.title = self.headerTitle;
    _headerView.subtitle = self.headerSubtitle;
    if (_headerView.title || _headerView.subtitle) {
        _tableView.tableHeaderView = _headerView;
    } else {
        _tableView.tableHeaderView = nil;
    }
    [_tableView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    
    CGFloat height = [_headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    CGRect headerViewFrame = _headerView.frame;
    
    if (height != headerViewFrame.size.height) {
        headerViewFrame.size.height = height;
        _headerView.frame = headerViewFrame;
        _tableView.tableHeaderView = _headerView;
    }
}

- (void)setShowEdgeIndicators:(BOOL)showEdgeIndicators {
    _showEdgeIndicators = showEdgeIndicators;
    [_tableView reloadData];
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OCKInsightItem *item = self.items[indexPath.section];
    
    if ([item isKindOfClass:[OCKChart class]]) {
        static NSString *ChartCellIdentifier = @"ChartCell";
        OCKInsightsChartTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ChartCellIdentifier];
        if (!cell) {
            cell = [[OCKInsightsChartTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:ChartCellIdentifier];
        }
        cell.chart = (OCKChart *)item;
        cell.showEdgeIndicator = _showEdgeIndicators;
        return cell;
    } else if ([item isKindOfClass:[OCKMessageItem class]]) {
        static NSString *MessageCellIdentifier = @"MessageCell";
        OCKInsightsMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageCellIdentifier];
        if (!cell) {
            cell = [[OCKInsightsMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:MessageCellIdentifier];
        }
        cell.messageItem = (OCKMessageItem *)item;
        cell.showEdgeIndicator = self.showEdgeIndicators;
        return cell;
    }
    
    return nil;
}

@end

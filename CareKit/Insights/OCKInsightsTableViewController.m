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


#import "OCKInsightsTableViewController.h"
#import "OCKInsightsTableViewHeaderView.h"
#import "OCKInsightsChartTableViewCell.h"
#import "OCKInsightsMessageTableViewCell.h"
#import "OCKHelpers.h"


static const CGFloat HeaderViewHeight = 60.0;

@implementation OCKInsightsTableViewController {
    OCKInsightsTableViewHeaderView *_headerView;
    BOOL _hasAnimated;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithInsightItems:(NSArray<OCKInsightItem *> *)items {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _items = [items copy];
        _hasAnimated = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!_headerView) {
        _headerView = [[OCKInsightsTableViewHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    _headerView.title = _headerTitle;
    _headerView.subtitle = _headerSubtitle;
    self.tableView.tableHeaderView = _headerView;

    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.sectionHeaderHeight = 5.0;
    self.tableView.sectionFooterHeight = 0.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!_hasAnimated) {
        NSArray *visibleCells = self.tableView.visibleCells;
        for (id cell in visibleCells) {
            if ([cell isKindOfClass:[OCKInsightsChartTableViewCell class]]) {
                [cell animateWithDuration:1.0];
            }
        }
        _hasAnimated = YES;
    }
}

- (void)setItems:(NSArray<OCKInsightItem *> *)items {
    _items = items;
    [self.tableView reloadData];
}

- (void)setHeaderTitle:(NSString *)headerTitle {
    _headerTitle = headerTitle;
    _headerView.title = _headerTitle;
    self.tableView.tableHeaderView = _headerView;
}

- (void)setHeaderSubtitle:(NSString *)headerSubtitle {
    _headerSubtitle = headerSubtitle;
    _headerView.subtitle = _headerSubtitle;
    self.tableView.tableHeaderView = _headerView;
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OCKInsightItem *item = _items[indexPath.section];
    
    if ([item isKindOfClass:[OCKChart class]]) {
        static NSString *ChartCellIdentifier = @"ChartCell";
        OCKInsightsChartTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ChartCellIdentifier];
        if (!cell) {
            cell = [[OCKInsightsChartTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:ChartCellIdentifier];
        }
        cell.chart = (OCKChart *)item;
        return cell;
    } else if ([item isKindOfClass:[OCKMessageItem class]]) {
        static NSString *MessageCellIdentifier = @"MessageCell";
        OCKInsightsMessageTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:MessageCellIdentifier];
        if (!cell) {
            cell = [[OCKInsightsMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:MessageCellIdentifier];
        }
        cell.messageItem = (OCKMessageItem *)item;
        return cell;
    }

    return nil;
}

@end

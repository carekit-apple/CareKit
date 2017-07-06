/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 Copyright (c) 2017, Troy Tsubota. All rights reserved.
 Copyright (c) 2017, Erik Hornberger. All rights reserved.
 
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


#import "OCKConnectViewController.h"
#import "OCKContact.h"
#import "OCKConnectDetailViewController.h"
#import "OCKHelpers.h"
#import "OCKDefines_Private.h"
#import "OCKLabel.h"
#import "OCKConnectMessagesViewController.h"
#import "OCKConnectHeaderView.h"


@interface OCKConnectViewController() <UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation OCKConnectViewController {
    UITableView *_tableView;
    NSMutableArray *_constraints;
    NSMutableArray<NSArray<OCKContact *>*> *_sectionedContacts;
    NSMutableArray<NSString *> *_sectionTitles;
    OCKLabel *_noContactsLabel;
    OCKConnectHeaderView *_headerView;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts
                         patient:(OCKPatient *)patient {
    self = [super init];
    if (self) {
        _contacts = OCKArrayCopyObjects(contacts);
        _patient = patient;
    }
    return self;
}

- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts {
    return [self initWithContacts:contacts
                          patient:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    [self prepareHeaderView];
    
    _tableView.estimatedRowHeight = 44.0;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.estimatedSectionHeaderHeight = 0;
    _tableView.estimatedSectionFooterHeight = 0;
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:245.0/255.0 green:244.0/255.0 blue:246.0/255.0 alpha:1.0]];
    
    [self createSectionedContacts];
    
    if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
        [self registerForPreviewingWithDelegate:self sourceView:_tableView];
    }
    
    _headerView = [OCKConnectHeaderView new];
    _headerView.patient = _patient;
    [self.view addSubview:_headerView];
    
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileHeaderTapped:)];
    [_headerView addGestureRecognizer:singleFingerTap];
    
    [self updateHeaderView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSAssert(self.navigationController, @"OCKConnectViewController must be embedded in a navigation controller.");
}

- (void)setContacts:(NSArray<OCKContact *> *)contacts {
    _contacts = OCKArrayCopyObjects(contacts);
    [self prepareHeaderView];
    [self createSectionedContacts];
    [_tableView reloadData];
}

- (void)setDataSource:(id<OCKConnectViewControllerDataSource>)dataSource {
    _dataSource = dataSource;
    [_tableView reloadData];
    [self createSectionedContacts];
    
    [self updateHeaderView];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_headerView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.topLayoutGuide
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_headerView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_tableView
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
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_headerView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_headerView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    if (self.contacts.count == 0) {
        _noContactsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:_noContactsLabel
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1.0
                                                                          constant:0.0],
                                            [NSLayoutConstraint constraintWithItem:_noContactsLabel
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0]
                                            ]];
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)createSectionedContacts {
    _sectionedContacts = [NSMutableArray new];
    _sectionTitles = [NSMutableArray new];
    
    if ([self shouldInboxBeVisible]) {
        NSArray *connections = [self.dataSource connectViewControllerCareTeamConnections:self];
        [_sectionedContacts addObject:connections];
        [_sectionTitles addObject:OCKLocalizedString(@"CONNECT_INBOX_TITLE", nil)];
    }
    
    NSMutableArray *careTeamContacts = [NSMutableArray new];
    NSMutableArray *personalContacts = [NSMutableArray new];
    
    for (OCKContact *contact in self.contacts) {
        switch (contact.type) {
            case OCKContactTypeCareTeam:
                [careTeamContacts addObject:contact];
                break;
            case OCKContactTypePersonal:
                [personalContacts addObject:contact];
                break;
        }
    }
    
    if (careTeamContacts.count > 0) {
        [_sectionedContacts addObject:[careTeamContacts copy]];
        [_sectionTitles addObject:OCKLocalizedString(@"CARE_TEAM_SECTION_TITLE", nil)];
    }
    
    if (personalContacts.count > 0) {
        [_sectionedContacts addObject:[personalContacts copy]];
        [_sectionTitles addObject:OCKLocalizedString(@"PERSONAL_SECTION_TITLE", nil)];
    }
}

- (void)prepareHeaderView {
    if (self.contacts.count == 0) {
        if (!_noContactsLabel) {
            _noContactsLabel = [OCKLabel new];
            _noContactsLabel.textStyle = UIFontTextStyleTitle2;
            _noContactsLabel.text = OCKLocalizedString(@"CONNECT_NO_CONTACTS_TITLE", nil);
            _noContactsLabel.textColor = [UIColor lightGrayColor];
        }
        [self.view addSubview:_noContactsLabel];
    } else {
        [_noContactsLabel removeFromSuperview];
    }
}

- (void)updateHeaderView {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(connectViewController:didSelectProfileForPatient:)]) {
        // Show disclosure indicator on profile tab.
        _headerView.hideChevron = NO;
    } else {
        // Hide disclosure indicator on profile tab.
        _headerView.hideChevron = YES;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self setUpConstraints];
}

- (void)profileHeaderTapped:(id)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(connectViewController:didSelectProfileForPatient:)]) {
        [self.delegate connectViewController:self didSelectProfileForPatient:self.patient];
    }
}


#pragma mark - Helpers

- (BOOL)shouldInboxBeVisible {
    return self.dataSource &&
    [self.dataSource respondsToSelector:@selector(connectViewControllerNumberOfConnectMessageItems:careTeamContact:)] &&
    [self.dataSource respondsToSelector:@selector(connectViewController:connectMessageItemAtIndex:careTeamContact:)] &&
    [self.dataSource respondsToSelector:@selector(connectViewControllerCareTeamConnections:)];
}

- (OCKContact *)contactForIndexPath:(NSIndexPath *)indexPath {
    return _sectionedContacts[indexPath.section][indexPath.row];
}

- (OCKConnectDetailViewController *)detailViewControllerForContact:(OCKContact *)contact {
    OCKConnectDetailViewController *detailViewController = [[OCKConnectDetailViewController alloc] initWithContact:contact];
    detailViewController.delegate = self.delegate;
    detailViewController.masterViewController = self;
    return detailViewController;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self shouldInboxBeVisible] && indexPath.section == 0) {
        OCKConnectMessagesViewController *viewController = [OCKConnectMessagesViewController new];
        viewController.dataSource = self.dataSource;
        viewController.delegate = self.delegate;
        viewController.masterViewController = self;
        viewController.contact = [self.dataSource connectViewControllerCareTeamConnections:self][indexPath.row];
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        OCKContact *contact = [self contactForIndexPath:indexPath];
        [self.navigationController pushViewController:[self detailViewControllerForContact:contact] animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sectionedContacts.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sectionTitles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self shouldInboxBeVisible] && section == 0) {
        return [self.dataSource connectViewControllerCareTeamConnections:self].count;
    }
    return _sectionedContacts[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self shouldInboxBeVisible] && indexPath.section == 0) {
        static NSString *ConnectMessageCellIdentifier = @"ConnectMessageCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ConnectMessageCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:ConnectMessageCellIdentifier];
        }
        cell.imageView.image = [[UIImage imageNamed:@"message" inBundle:OCKBundle() compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.imageView.tintColor = [UIColor lightGrayColor];
        cell.tintColor = self.view.tintColor;
        cell.textLabel.text = _sectionedContacts[indexPath.section][indexPath.row].name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
        
    } else {
        static NSString *CellIdentifier = @"ConnectCell";
        OCKConnectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[OCKConnectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:CellIdentifier];
        }
        cell.contact = _sectionedContacts[indexPath.section][indexPath.row];
        return cell;
    }
    return nil;
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MessageComposeResultFailed) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:OCKLocalizedString(@"ERROR_TITLE", nil)
                                                                                 message:OCKLocalizedString(@"MESSAGE_SEND_ERROR", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MFMailComposeResultFailed) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:OCKLocalizedString(@"ERROR_TITLE", nil)
                                                                                 message:OCKLocalizedString(@"EMAIL_SEND_ERROR", nil)
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:location];
    
    if ([self shouldInboxBeVisible] && indexPath.section == 0) {
        OCKConnectMessagesViewController *viewController = [OCKConnectMessagesViewController new];
        viewController.dataSource = self.dataSource;
        viewController.delegate = self.delegate;
        viewController.masterViewController = self;
        viewController.contact = [self.dataSource connectViewControllerCareTeamConnections:self][indexPath.row];
        return viewController;
    } else {
        OCKContact *contact = [self contactForIndexPath:indexPath];
        return [self detailViewControllerForContact:contact];
    }
    
    return nil;
}

- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

@end

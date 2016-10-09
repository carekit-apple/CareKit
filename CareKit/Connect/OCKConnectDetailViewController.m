/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 Copyright (c) 2016, WWT Asynchrony Labs. All rights reserved.
 
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


#import "OCKConnectDetailViewController.h"
#import "OCKConnectTableViewHeader.h"
#import "OCKDefines_Private.h"
#import "OCKHelpers.h"


static const CGFloat HeaderViewHeight = 225.0;

@implementation OCKConnectDetailViewController {
    OCKConnectTableViewHeader *_headerView;
    NSMutableArray<NSArray *> *_tableViewData;
    NSMutableArray<NSString *> *_sectionTitles;
    NSString *_contactInfoSectionTitle;
    NSString *_sharingSectionTitle;
}

- (instancetype)initWithContact:(OCKContact *)contact {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _contact = contact;
        [self createTableViewDataArray];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self prepareView];
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    [self createTableViewDataArray];
    [self prepareView];
    [self.tableView reloadData];
}

- (void)setDelegate:(id<OCKConnectViewControllerDelegate>)delegate {
    _delegate = delegate;
    [self createTableViewDataArray];
    [self.tableView reloadData];
}

- (void)setShowEdgeIndicator:(BOOL)showEdgeIndicator {
    _showEdgeIndicator = showEdgeIndicator;
    _headerView.showEdgeIndicator = _showEdgeIndicator;
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKConnectTableViewHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    _headerView.showEdgeIndicator = self.showEdgeIndicator;
    _headerView.contact = self.contact;
    
    self.tableView.tableHeaderView = _headerView;
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


#pragma mark - Helpers

- (void)createTableViewDataArray {
    _tableViewData = [NSMutableArray new];
    _sectionTitles = [NSMutableArray new];
    
    NSMutableArray<OCKContactInfo *> *contactInfoSection = [NSMutableArray new];
    NSMutableArray<NSString *> *sharingSection = [NSMutableArray new];
    
	[contactInfoSection addObjectsFromArray:self.contact.contactInfoItems];
    
    if (self.delegate) {
		NSString *sharingTitle = [self sharingTitle];
		[sharingSection addObject:sharingTitle];
    }
    
    if (contactInfoSection.count > 0) {
        [_tableViewData addObject:[contactInfoSection copy]];
        _contactInfoSectionTitle = OCKLocalizedString(@"CONTACT_INFO_SECTION_TITLE", nil);
        [_sectionTitles addObject:_contactInfoSectionTitle];
    }
    if (sharingSection.count > 0) {
        [_tableViewData addObject:[sharingSection copy]];
        _sharingSectionTitle = OCKLocalizedString(@"CONTACT_SHARING_SECTION_TITLE", nil);
        [_sectionTitles addObject:_sharingSectionTitle];
    }
}

- (NSString *)sharingTitle {
	NSString *sharingTitle = OCKLocalizedString(@"SHARING_CELL_TITLE", nil);
	if ([self.delegate respondsToSelector:@selector(connectViewController:titleForSharingCellForContact:)]) {
		NSString *delegateTitle = [self.delegate connectViewController:self.masterViewController titleForSharingCellForContact:self.contact];
		if (delegateTitle.length > 0) {
			sharingTitle = delegateTitle;
		}
	}
	return sharingTitle;
}

- (void)makeCallToNumber:(NSString *)number {
    NSString *stringURL = [NSString stringWithFormat:@"tel:%@", OCKStripNonNumericCharacters(number)];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringURL]];
}

- (void)sendMessageToNumber:(NSString *)number delegate:(id<MFMessageComposeViewControllerDelegate>)messageDelegate presentingViewController:(UIViewController *)presentingViewController {
    MFMessageComposeViewController *messageViewController = [MFMessageComposeViewController new];
    if ([MFMessageComposeViewController canSendText]) {
        messageViewController.messageComposeDelegate = messageDelegate;
        messageViewController.recipients = @[number];
        [presentingViewController presentViewController:messageViewController animated:YES completion:nil];
    }
}

- (void)sendEmailToAddress:(NSString *)address delegate:(id<MFMailComposeViewControllerDelegate>)emailDelegate presentingViewController:(UIViewController *)presentingViewController {
    MFMailComposeViewController *emailViewController = [MFMailComposeViewController new];
    if ([MFMailComposeViewController canSendMail]) {
        emailViewController.mailComposeDelegate = emailDelegate;
        [emailViewController setToRecipients:@[address]];
        [presentingViewController presentViewController:emailViewController animated:YES completion:nil];
    }
}

- (void)makeVideoCallToNumber:(NSString *)number {
	NSString *stringURL = [NSString stringWithFormat:@"facetime://%@", number];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringURL]];
}

- (void)contactInfoOptionSelected:(OCKContactInfo *)contactInfo defaultActionHandler:(UIViewController<MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> *)defaultActionHandler {
	BOOL handled = NO;
	if (self.delegate && [self.delegate respondsToSelector:@selector(connectViewController:handleContactInfoSelected:)]) {
		handled = [self.delegate connectViewController:self.masterViewController handleContactInfoSelected:contactInfo];
	}
	
	if (!handled) {
		if (contactInfo.actionURL) {
			[[UIApplication sharedApplication] openURL:contactInfo.actionURL];
		} else {
			switch (contactInfo.type) {
				case OCKContactInfoTypePhone:
					[self makeCallToNumber:contactInfo.displayString];
					break;
					
				case OCKContactInfoTypeMessage:
					[self sendMessageToNumber:contactInfo.displayString delegate:defaultActionHandler presentingViewController:defaultActionHandler];
					break;
					
				case OCKContactInfoTypeEmail:
					[self sendEmailToAddress:contactInfo.displayString delegate:defaultActionHandler presentingViewController:defaultActionHandler];
					break;
					
				case OCKContactInfoTypeVideo:
					[self makeVideoCallToNumber:contactInfo.displayString];
					break; 
			}
		}
	}
}

- (void)sharingOptionSelectedWithSourceView:(UIView *)presentationSourceView {
	if (self.delegate &&
		[self.delegate respondsToSelector:@selector(connectViewController:didSelectShareButtonForContact:presentationSourceView:)]) {
		[self.delegate connectViewController:self.masterViewController didSelectShareButtonForContact:self.contact presentationSourceView:presentationSourceView];
	}
}

#pragma mark - OCKContactInfoTableViewCellDelegate

- (void)contactInfoTableViewCellDidSelectConnection:(OCKContactInfoTableViewCell *)cell {
	[self contactInfoOptionSelected:cell.contactInfo defaultActionHandler:self];
}


#pragma mark - OCKContactSharingTableViewCellDelegate

- (void)sharingTableViewCellDidSelectShareButton:(OCKContactSharingTableViewCell *)cell {
	[self sharingOptionSelectedWithSourceView:cell.shareButton];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _tableViewData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sectionTitles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tableViewData[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionTitle = _sectionTitles[indexPath.section];
    
    if ([sectionTitle isEqualToString:_contactInfoSectionTitle]) {
        static NSString *ContactCellIdentifier = @"ContactInfoCell";
        OCKContactInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactCellIdentifier];
        if (!cell) {
            cell = [[OCKContactInfoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                      reuseIdentifier:ContactCellIdentifier];
			cell.tintColor = self.contact.tintColor;
        }
        cell.contactInfo = _tableViewData[indexPath.section][indexPath.row];
        cell.delegate = self;
        return cell;
    } else if ([sectionTitle isEqualToString:_sharingSectionTitle]) {
        static NSString *SharingCellIdentifier = @"SharingCell";
        OCKContactSharingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SharingCellIdentifier];
        if (!cell) {
            cell = [[OCKContactSharingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                         reuseIdentifier:SharingCellIdentifier];
        }
        cell.title = _tableViewData[indexPath.section][indexPath.row];
        cell.contact = self.contact;
        cell.delegate = self;
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sectionTitle = _sectionTitles[indexPath.section];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if ([sectionTitle isEqualToString:_contactInfoSectionTitle]) {
        [self contactInfoTableViewCellDidSelectConnection:(OCKContactInfoTableViewCell*)cell];
    } else if ([sectionTitle isEqualToString:_sharingSectionTitle]) {
        [self sharingTableViewCellDidSelectShareButton:(OCKContactSharingTableViewCell *)cell];
    }
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


#pragma mark - Preview Action Items

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    NSMutableArray<id<UIPreviewActionItem>> *actions = [[NSMutableArray alloc] init];
	for (OCKContactInfo *contactInfo in self.contact.contactInfoItems) {
		NSString *capitalizedTitle = [contactInfo.label capitalizedStringWithLocale:[NSLocale currentLocale]];
		UIPreviewAction *previewAction = [UIPreviewAction actionWithTitle:capitalizedTitle style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
			[self contactInfoOptionSelected:contactInfo defaultActionHandler:self.masterViewController];
		}];
		[actions addObject:previewAction];
	}
    if (self.delegate) {
		NSString *sharingTitle = [self sharingTitle];
		UIPreviewAction *shareAction = [UIPreviewAction actionWithTitle:sharingTitle style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
			[self sharingOptionSelectedWithSourceView:nil];
        }];
        [actions addObject:shareAction];
    }
    return actions;
}

@end

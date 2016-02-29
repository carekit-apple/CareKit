//
//  OCKConnectDetailTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKConnectDetailViewController.h"
#import "OCKContact.h"
#import "OCKConnectTableViewHeader.h"


static const CGFloat CellHeight = 70.0;
static const CGFloat HeaderViewHeight = 225.0;

@implementation OCKConnectDetailViewController {
    OCKConnectTableViewHeader *_headerView;
}

- (instancetype)initWithContact:(OCKContact *)contact {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _contact = contact;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = CellHeight;
    [self prepareView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    [self prepareView];
    [self.tableView reloadData];
}

- (void)prepareView {
    if (!_headerView) {
        _headerView = [[OCKConnectTableViewHeader alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HeaderViewHeight)];
    }
    _headerView.contact = _contact;
    
    self.tableView.tableHeaderView = _headerView;
}


#pragma mark - Helpers

- (void)makeCallToNumber:(NSString *)number {
    NSString *stringURL = [NSString stringWithFormat:@"tel:%@", number];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringURL]];
}

- (void)sendMessageToNumber:(NSString *)number {
    MFMessageComposeViewController *messageViewController = [MFMessageComposeViewController new];
    if ([MFMessageComposeViewController canSendText]) {
        messageViewController.messageComposeDelegate = self;
        messageViewController.recipients = @[number];
        [self presentViewController:messageViewController animated:YES completion:nil];
    }
}

- (void)sendEmailToAddress:(NSString *)address {
    MFMailComposeViewController *emailViewController = [MFMailComposeViewController new];
    if ([MFMailComposeViewController canSendMail]) {
        emailViewController.mailComposeDelegate = self;
        [emailViewController setToRecipients:@[address]];
        [self presentViewController:emailViewController animated:YES completion:nil];
    }
}


#pragma mark - OCKContactInfoTableViewCellDelegate

- (void)contactInfoTableViewCellDidSelectConnection:(OCKContactInfoTableViewCell *)cell {
    switch (cell.connectType) {
        case OCKConnectTypePhone:
            [self makeCallToNumber:cell.contact.phoneNumber];
            break;
        
        case OCKConnectTypeMessage:
            [self sendMessageToNumber:cell.contact.messageNumber];
            break;
            
        case OCKConnectTypeEmail:
            [self sendEmailToAddress:cell.contact.emailAddress];
            break;
    }
}


#pragma mark - OCKReportsTableViewCellDelegate

- (void)reportsTableViewCellDidSelectShareButton:(OCKReportsTableViewCell *)cell {
    // TODO: Show share sheet with PDF export embedded.
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case 0:
            sectionTitle = @"Contact Info";
            break;
            
        case 1:
            sectionTitle = @"Reports";
            break;
    }
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (section == 0) {
        if (_contact.phoneNumber) {
            numberOfRows = numberOfRows + 1;
        }
        if (_contact.emailAddress) {
            numberOfRows = numberOfRows + 1;
        }
        if (_contact.messageNumber) {
            numberOfRows = numberOfRows + 1;
        }
    } else if (section == 1) {
        numberOfRows = 1;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *ContactCellIdentifier = @"ContactInfoCell";
        
        OCKContactInfoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ContactCellIdentifier];
        if (!cell) {
            cell = [[OCKContactInfoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                      reuseIdentifier:ContactCellIdentifier];
        }
        cell.contact = _contact;
        cell.delegate = self;
        
        OCKConnectType type;
        if (indexPath.row == 0) {
            if (_contact.phoneNumber) {
                type = OCKConnectTypePhone;
            } else if (_contact.messageNumber) {
                type = OCKConnectTypeMessage;
            } else if (_contact.emailAddress) {
                type = OCKConnectTypeEmail;
            }
        } else if (indexPath.row == 1) {
            if (_contact.messageNumber) {
                type = OCKConnectTypeMessage;
            } else if (_contact.emailAddress) {
                type = OCKConnectTypeEmail;
            }
        } else if (indexPath.row == 2) {
            type = OCKConnectTypeEmail;
        }
        cell.connectType = type;
        
        return cell;
    
    } else if (indexPath.section == 1) {
        static NSString *ReportsCellIdentifier = @"ReportsCell";

        OCKReportsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReportsCellIdentifier];
        if (!cell) {
            cell = [[OCKReportsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:ReportsCellIdentifier];
        }
        cell.title = @"Send reports";
        cell.contact = _contact;
        cell.delegate = self;
        
        return cell;
    }
    
    return nil;
}


#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MessageComposeResultFailed) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                 message:@"Message send failed."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MFMailComposeResultFailed) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                 message:@"Email send failed."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:nil];
        
        NSLog(@"%@", error);
    }
}

@end

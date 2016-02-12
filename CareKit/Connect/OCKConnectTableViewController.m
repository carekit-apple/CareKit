//
//  OCKConnectTableViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKConnectTableViewController.h"
#import "OCKConnectTableViewCell.h"
#import "OCKContact.h"
#import "OCKHelpers.h"


@implementation OCKConnectTableViewController {
    NSArray<NSArray<OCKConnectTableViewCell*>*> *_connectTableViewCells;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Connect";
        _contacts = [contacts copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _connectTableViewCells = nil;
    self.tableView.sectionHeaderHeight = 20.0;
    self.tableView.rowHeight = 90.0;
    
    NSMutableArray<OCKConnectTableViewCell *> *clinicians = [NSMutableArray new];
    NSMutableArray<OCKConnectTableViewCell *> *emergencyContacts = [NSMutableArray new];
    for (id contact in self.contacts) {
        static NSString *CellIdentifier = @"ConnectCell";
        OCKConnectTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[OCKConnectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:CellIdentifier];
            cell.delegate = self;
        }
        cell.contact = contact;
        
        OCKContactType contactType = ((OCKContact *)contact).type;
        if (contactType == OCKContactTypeClinician) {
            [clinicians addObject:cell];
        } else {
            [emergencyContacts addObject:cell];
        }
    }
    _connectTableViewCells = @[clinicians, emergencyContacts];
}

- (void)setContacts:(NSArray<OCKContact *> *)contacts {
    _contacts = contacts;
    [self.tableView reloadData];
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


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _connectTableViewCells.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case 0:
            sectionTitle = @"Clinicians";
            break;
            
        case 1:
            sectionTitle = @"Emergency Contacts";
            break;
    }
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _connectTableViewCells[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _connectTableViewCells[indexPath.section][indexPath.row];
}


#pragma mark - OCKConnectTableViewCellDelegate

- (void)connectTableViewCell:(OCKConnectTableViewCell *)cell didSelectConnectType:(OCKConnectType)connectType {
    switch (connectType) {
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

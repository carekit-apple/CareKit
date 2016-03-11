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
    NSArray<NSArray<OCKContact *> *> *_sectionedContacts;
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
        _contacts = [contacts copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 90.0;
    
    [self createSectionedContacts];
}

- (void)setContacts:(NSArray<OCKContact *> *)contacts {
    _contacts = contacts;
    [self createSectionedContacts];
    [self.tableView reloadData];
}

- (void)createSectionedContacts {
    _sectionedContacts = [NSArray new];
    
    NSMutableArray *careTeamContacts = [NSMutableArray new];
    NSMutableArray *personalContacts = [NSMutableArray new];

    for (OCKContact *contact in _contacts) {
        switch (contact.type) {
            case OCKContactTypeClinician:
                [careTeamContacts addObject:contact];
                break;
            case OCKContactTypeEmergencyContact:
                [personalContacts addObject:contact];
                break;
        }
    }
    
    _sectionedContacts = @[[careTeamContacts copy], [personalContacts copy]];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate &&
        [_delegate respondsToSelector:@selector(tableView:didSelectRowWithContact:)]) {
        [_delegate tableView:tableView didSelectRowWithContact:_sectionedContacts[indexPath.section][indexPath.row]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sectionedContacts.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    switch (section) {
        case 0:
            sectionTitle = @"Care Team";
            break;
            
        case 1:
            sectionTitle = @"Friends & Family";
            break;
    }
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _sectionedContacts[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ConnectCell";
    OCKConnectTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[OCKConnectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:CellIdentifier];
    }
    cell.contact = _sectionedContacts[indexPath.section][indexPath.row];
    return cell;
}

@end

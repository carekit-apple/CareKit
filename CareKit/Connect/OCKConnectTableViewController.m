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
    self.tableView.rowHeight = 90.0;
    
    NSMutableArray<OCKConnectTableViewCell *> *clinicians = [NSMutableArray new];
    NSMutableArray<OCKConnectTableViewCell *> *emergencyContacts = [NSMutableArray new];
    for (id contact in self.contacts) {
        static NSString *CellIdentifier = @"ConnectCell";
        OCKConnectTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[OCKConnectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:CellIdentifier];
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


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate &&
        [_delegate respondsToSelector:@selector(tableViewDidSelectRowWithContact:)]) {
        [_delegate tableViewDidSelectRowWithContact:_connectTableViewCells[indexPath.section][indexPath.row].contact];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _connectTableViewCells.count;
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
    return _connectTableViewCells[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _connectTableViewCells[indexPath.section][indexPath.row];
}

@end

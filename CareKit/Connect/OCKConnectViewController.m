//
//  OCKConnectViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKConnectViewController.h"
#import "OCKConnectViewController_Internal.h"
#import "OCKContact.h"
#import "OCKConnectTableViewController.h"
#import "OCKConnectDetailViewController.h"
#import "OCKHelpers.h"


@implementation OCKConnectViewController {
    OCKConnectTableViewController *_tableViewController;
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
    self = [super init];
    if (self) {
        _contacts = [contacts copy];
        
        _tableViewController = [[OCKConnectTableViewController alloc] initWithContacts:[contacts copy]];
        _tableViewController.delegate = self;
        [self addChildViewController:_tableViewController];
        [self.view addSubview:_tableViewController.view];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSAssert(self.navigationController, @"OCKConnectViewController must be embedded in a navigation controller.");
}

- (void)setContacts:(NSArray<OCKContact *> *)contacts {
    _contacts = [contacts copy];
    _tableViewController.contacts = contacts;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    _tableViewController.title = self.title;
}


#pragma mark - OCKConnectTableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowWithContact:(OCKContact *)contact {
    OCKConnectDetailViewController *detailViewController = [[OCKConnectDetailViewController alloc] initWithContact:contact];
    detailViewController.delegate = _delegate;
    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end

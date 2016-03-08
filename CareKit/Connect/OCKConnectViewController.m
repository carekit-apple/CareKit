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

+ (instancetype)connectViewControllerWithContacts:(NSArray<OCKContact *> *)contacts
                                  sharingDelegate:(id<OCKConnectSharingDelegate>)sharingDelegate {
    return [[OCKConnectViewController alloc] initWithContacts:contacts
                                              sharingDelegate:sharingDelegate];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts
                 sharingDelegate:(id<OCKConnectSharingDelegate>)sharingDelegate {
    _tableViewController = [[OCKConnectTableViewController alloc] initWithContacts:[contacts copy]];
    
    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _contacts = [contacts copy];
        _sharingDelegate = sharingDelegate;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewController.delegate = self;
    self.navigationBar.tintColor = self.view.tintColor;
}

- (void)setContacts:(NSArray<OCKContact *> *)contacts {
    _contacts = [contacts copy];
    _tableViewController.contacts = contacts;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}


#pragma mark - OCKConnectTableViewDelegate

- (void)tableViewDidSelectRowWithContact:(OCKContact *)contact {
    OCKConnectDetailViewController *detailViewController = [[OCKConnectDetailViewController alloc] initWithContact:contact];
    detailViewController.sharingDelegate = _sharingDelegate;
    [self pushViewController:detailViewController animated:YES];
}

@end

//
//  OCKConnectViewController.m
//  CareKit
//
//  Created by Umer Khan on 1/30/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKConnectViewController.h"
#import "OCKContact.h"
#import "OCKConnectTableViewController.h"
#import "OCKHelpers.h"


@implementation OCKConnectViewController {
    OCKConnectTableViewController *_tableViewController;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)connectViewControllerWithContacts:(NSArray<OCKContact *> *)contacts {
    return [[OCKConnectViewController alloc] initWithContacts:contacts];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithContacts:(NSArray<OCKContact *> *)contacts {
    _tableViewController = [[OCKConnectTableViewController alloc] initWithContacts:[contacts copy]];
    
    self = [super initWithRootViewController:_tableViewController];
    if (self) {
        _contacts = [contacts copy];
    }
    return self;
}

- (void)setContacts:(NSArray<OCKContact *> *)contacts {
    _contacts = [contacts copy];
    _tableViewController.contacts = contacts;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topViewController.title = self.title;
}

@end

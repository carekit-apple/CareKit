/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import "OCKConnectMessagesViewController.h"
#import "OCKTextView.h"
#import "OCKConnectMessageTableViewCell.h"
#import "OCKDefines_Private.h"


static const CGFloat VerticalMargin = 7.0;
static const CGFloat HorizontalMargin = 13.0;
static const CGFloat TextViewHeight = 75.0;
static const CGFloat SeparatorViewHeight = 1.0;

static NSString *EmptyString = @"";

@interface OCKConnectMessagesViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@end


@implementation OCKConnectMessagesViewController {
    UITableView *_tableView;
    OCKTextView *_textView;
    UIView *_separatorView;
    UIButton *_sendButton;
    NSMutableArray *_constraints;
    BOOL _isKeyboardVisible;
    NSString *_placeholderString;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        
        [self prepareView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationChanged:)
                                                     name:@"UIDeviceOrientationDidChangeNotification"
                                                   object:nil];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        [self.view addGestureRecognizer:tap];
        [self registerForKeyboardNotifications];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _isKeyboardVisible = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:245.0/255.0 green:244.0/255.0 blue:246.0/255.0 alpha:1.0]];
}

- (void)prepareView {
    _placeholderString = OCKLocalizedString(@"CONNECT_MESSAGE_PLACEHOLDER", nil);
    self.title = OCKLocalizedString(@"CONNECT_INBOX_TITLE", nil);
    
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = 90.0;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        [self.view addSubview:_tableView];
    }
    
    if (!_separatorView) {
        _separatorView = [UIView new];
        _separatorView.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self.view addSubview:_separatorView];
    }
    
    if (!_textView) {
        _textView = [OCKTextView new];
        _textView.delegate = self;
        _textView.text = _placeholderString;
        [self.view addSubview:_textView];
    }
    
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_sendButton setTitle:OCKLocalizedString(@"CONNECT_SEND_BUTTON_TITLE", nil) forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(saveMessage:) forControlEvents:UIControlEventTouchUpInside];
        _sendButton.hidden = YES;
        [self.view addSubview:_sendButton];
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    
    _constraints = [NSMutableArray new];
    
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (_sendButton.hidden) {
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:_textView
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeTrailing
                                                                        multiplier:1.0
                                                                          constant:-HorizontalMargin]
                                            ]];
    } else {
        [_constraints addObjectsFromArray:@[
                                            [NSLayoutConstraint constraintWithItem:_sendButton
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_textView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:0.0],
                                            [NSLayoutConstraint constraintWithItem:_sendButton
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_textView
                                                                         attribute:NSLayoutAttributeTrailing
                                                                        multiplier:1.0
                                                                          constant:7.0],
                                            [NSLayoutConstraint constraintWithItem:self.view
                                                                         attribute:NSLayoutAttributeTrailing
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_sendButton
                                                                         attribute:NSLayoutAttributeTrailing
                                                                        multiplier:1.0
                                                                          constant:HorizontalMargin]
                                            ]];
    }
    
    [_constraints addObjectsFromArray:@[
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.topLayoutGuide
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_tableView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_separatorView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_textView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_separatorView
                                                                     attribute:NSLayoutAttributeBottom
                                                                    multiplier:1.0
                                                                      constant:2*VerticalMargin],
                                        [NSLayoutConstraint constraintWithItem:_sendButton
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_textView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_textView
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.bottomLayoutGuide
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:-2*VerticalMargin],
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
                                        [NSLayoutConstraint constraintWithItem:_separatorView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_separatorView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_textView
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:HorizontalMargin],
                                        [NSLayoutConstraint constraintWithItem:_separatorView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:SeparatorViewHeight],
                                        [NSLayoutConstraint constraintWithItem:_textView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:TextViewHeight]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setUpConstraints];
}

- (void)orientationChanged:(NSNotification *)notification {
    [self setUpConstraints];
    [_tableView reloadData];
}

- (void)setContact:(OCKContact *)contact {
    _contact = contact;
    self.title = _contact.name;
}


#pragma mark - Helpers

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)handleTap {
    [self.view endEditing:YES];
}

- (void)loadConnectMessages {
    if (self.dataSource &&
        [self.dataSource respondsToSelector:@selector(connectViewControllerNumberOfConnectMessageItems:careTeamContact:)]) {
        NSInteger numberOfMessages = [self.dataSource connectViewControllerNumberOfConnectMessageItems:self.masterViewController careTeamContact:self.contact];
        [_tableView reloadData];
        
        NSIndexPath *lastRowIndexPath = [NSIndexPath indexPathForRow:numberOfMessages - 1 inSection:0];
        [_tableView scrollToRowAtIndexPath:lastRowIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}


#pragma mark - Actions

- (void)saveMessage:(id)sender {
    if (![_textView.text isEqualToString:EmptyString]) {
        // Send a call back to the CTP delegate with the new message.
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(connectViewController:didSendConnectMessage:careTeamContact:)]) {
            [self.delegate connectViewController:self.masterViewController didSendConnectMessage:[_textView.text copy] careTeamContact:self.contact];
        }
    }
    
    [_textView endEditing:YES];
    _textView.text = _placeholderString;
    _textView.textColor = [UIColor lightGrayColor];
    
    [self loadConnectMessages];
}


#pragma mark - Keyboard notifications

- (void)keyboardWillShow:(NSNotification*)aNotification {
    if (!_isKeyboardVisible) {
        NSDictionary *info = [aNotification userInfo];
        NSNumber *duration = info[UIKeyboardAnimationDurationUserInfoKey];
        
        CGRect reportedKeyboardFrameRaw = [[[aNotification userInfo] valueForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGRect reportedKeyboardFrame = [self.view.window convertRect: reportedKeyboardFrameRaw fromWindow:nil];
        CGRect visibleKeyboardFrame = CGRectIntersection(reportedKeyboardFrame, self.view.window.frame);
        
        if (reportedKeyboardFrame.size.height == visibleKeyboardFrame.size.height) {
            [UIView animateWithDuration:duration.doubleValue animations:^{
                CGRect newFrame = self.view.frame;
                newFrame.origin.y -= (visibleKeyboardFrame.size.height - 7*VerticalMargin);
                self.view.frame = newFrame;
            } completion:^(BOOL finished) {}];
            
            _isKeyboardVisible = YES;
        }
    }
}

- (void)keyboardWillHide:(NSNotification*)aNotification {
    if (_isKeyboardVisible) {
        NSDictionary *info = [aNotification userInfo];
        NSNumber *duration = info[UIKeyboardAnimationDurationUserInfoKey];
        
        CGRect reportedKeyboardFrameRaw = [[[aNotification userInfo] valueForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGRect reportedKeyboardFrame = [self.view.window convertRect: reportedKeyboardFrameRaw fromWindow:nil];
        
        [UIView animateWithDuration:duration.doubleValue animations:^{
            CGRect newFrame = self.view.frame;
            newFrame.origin.y += (reportedKeyboardFrame.size.height - 7*VerticalMargin);
            self.view.frame = newFrame;
        } completion:^(BOOL finished) {}];
        
        _isKeyboardVisible = NO;
    }
}


#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([_textView.text isEqualToString:_placeholderString]) {
        _textView.text = EmptyString;
        _textView.textColor = [UIColor darkGrayColor];
        
    }
    _sendButton.hidden = NO;
    [self setUpConstraints];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([_textView.text isEqualToString:EmptyString]) {
        _textView.text = _placeholderString;
        _textView.textColor = [UIColor lightGrayColor];
    }
    _sendButton.hidden = YES;
    [self setUpConstraints];
}

- (void)textViewDidChange:(UITextView *)textView {
    _sendButton.enabled = ![_textView.text isEqualToString:EmptyString];
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (self.dataSource &&
        [self.dataSource respondsToSelector:@selector(connectViewControllerNumberOfConnectMessageItems:careTeamContact:)]) {
        numberOfRows = [self.dataSource connectViewControllerNumberOfConnectMessageItems:self.masterViewController careTeamContact:self.contact];
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.dataSource &&
        [self.dataSource respondsToSelector:@selector(connectViewController:connectMessageItemAtIndex:careTeamContact:)]) {
        
        static NSString *ConnectMessageReceivedCellIdentifier = @"ConnectMessageReceivedCell";
        static NSString *ConnectMessageSentCellIdentifier = @"ConnectMessageSentCell";
        
        OCKConnectMessageItem *item = [self.dataSource connectViewController:self.masterViewController connectMessageItemAtIndex:indexPath.row careTeamContact:self.contact];
        
        NSString *cellIdentifier = (item.type == OCKConnectMessageTypeReceived) ? ConnectMessageReceivedCellIdentifier : ConnectMessageSentCellIdentifier;
        OCKConnectMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[OCKConnectMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                         reuseIdentifier:cellIdentifier];
        }
        cell.tintColor = self.view.tintColor;
        cell.messageItem = item;
        cell.usePadding = NO;
        return cell;
    }
    
    return nil;
}

@end

//
//  OCKEvaluationTableViewHeader.m
//  CareKit
//
//  Created by Umer Khan on 2/4/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationTableViewHeader.h"


static const CGFloat VerticalMargin = 10.0;

@implementation OCKEvaluationTableViewHeader {
    UILabel *_dateLabel;
    UIProgressView *_progressView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangePreferredContentSize)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)prepareView {
    if (!_dateLabel) {
        _dateLabel = [UILabel new];
        _dateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _dateLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_dateLabel];
    }
    _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _dateLabel.text = _date;
    
    if (!_progressView) {
        _progressView = [UIProgressView new];
        [self addSubview:_progressView];
    }
    _progressView.progress = _progress;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:self
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_dateLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:VerticalMargin],
                                       [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_progressView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:VerticalMargin]
                                       ]];
    
    [NSLayoutConstraint activateConstraints:constraints];
    
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self prepareView];
}

- (void)setDate:(NSString *)date {
    _date = date;
    [self prepareView];
}

- (void)didChangePreferredContentSize {
    [self prepareView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

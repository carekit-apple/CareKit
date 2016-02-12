//
//  OCKCareCardView.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardView.h"
#import "OCKCareCard.h"


static const CGFloat LeadingMargin = 40.0;
static const CGFloat TrailingMargin = 40.0;
static const CGFloat TopMargin = 15.0;
static const CGFloat BottomMargin = 15.0;
static const CGFloat VerticalMargin = 5.0;
static const CGFloat HorizontalMargin = 5.0;

static const CGFloat HeartViewSize = 150.0;

@implementation OCKCareCardView {
    UILabel *_dateLabel;
    
    UIView *_heartView;
    UILabel *_adherenceLabel;
    UILabel *_adherencePercentageLabel;
    
    UILabel *_topEdge;
    UILabel *_bottomEdge;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.alpha = 0.99;
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
        _dateLabel.numberOfLines = 1;
        _dateLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_dateLabel];
    }
    _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _dateLabel.text = _careCard.date;
    
    if (!_heartView) {
        _heartView = [UIView new];
        _heartView.backgroundColor = [UIColor redColor];
        [self addSubview:_heartView];
    }
    _heartView.alpha = (_careCard.adherence == 0) ? 0.05 : _careCard.adherence;
    
    if (!_adherenceLabel) {
        _adherenceLabel = [UILabel new];
        _adherenceLabel.numberOfLines = 1;
        _adherenceLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _adherenceLabel.text = @"Adherence";
        [self addSubview:_adherenceLabel];
    }
    _adherenceLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    if (!_adherencePercentageLabel) {
        _adherencePercentageLabel = [UILabel new];
        _adherencePercentageLabel.numberOfLines = 1;
        _adherencePercentageLabel.lineBreakMode = NSLineBreakByCharWrapping;
        _adherencePercentageLabel.textColor = [UIColor redColor];
        [self addSubview:_adherencePercentageLabel];
    }
    _adherencePercentageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
    _adherencePercentageLabel.text = _careCard.adherencePercentageString;
    
    if (!_bottomEdge) {
        _bottomEdge = [UILabel new];
        _bottomEdge.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:_bottomEdge];
    }
    
    if (!_topEdge) {
        _topEdge = [UILabel new];
        _topEdge.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:_topEdge];
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    NSDictionary *views = NSDictionaryOfVariableBindings(_dateLabel);
    NSDictionary *metrics = @{@"leadingMargin" : @(LeadingMargin),
                              @"trailingMargin" : @(TrailingMargin)};
    
    _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _heartView.translatesAutoresizingMaskIntoConstraints = NO;
    _adherenceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _adherencePercentageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    _topEdge.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leadingMargin-[_dateLabel]-trailingMargin-|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:metrics
                                                                               views:views]];
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
                                       [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_heartView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_dateLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:VerticalMargin],
                                       [NSLayoutConstraint constraintWithItem:_heartView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_dateLabel
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:-HeartViewSize/3],
                                       [NSLayoutConstraint constraintWithItem:_heartView
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:HeartViewSize],
                                       [NSLayoutConstraint constraintWithItem:_heartView
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:HeartViewSize],
                                       [NSLayoutConstraint constraintWithItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_heartView
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:HorizontalMargin],
                                       [NSLayoutConstraint constraintWithItem:_heartView
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_adherencePercentageLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:BottomMargin],
                                       [NSLayoutConstraint constraintWithItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_dateLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_adherencePercentageLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_adherencePercentageLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_adherencePercentageLabel
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeWidth
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_bottomEdge
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_bottomEdge
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:1.0],
                                       [NSLayoutConstraint constraintWithItem:_bottomEdge
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeWidth
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_topEdge
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_topEdge
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:1.0],
                                       [NSLayoutConstraint constraintWithItem:_topEdge
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeWidth
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)setCareCard:(OCKCareCard *)careCard {
    _careCard = careCard;
    [self prepareView];
}

- (void)didChangePreferredContentSize {
    [self prepareView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

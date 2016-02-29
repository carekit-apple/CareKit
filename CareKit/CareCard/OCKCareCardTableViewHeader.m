//
//  OCKCareCardView.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardTableViewHeader.h"
#import "OCKHeartView.h"
#import "OCKColors.h"


static const CGFloat TopMargin = 15.0;
static const CGFloat VerticalMargin = 5.0;

static const CGFloat HeartViewSize = 150.0;

@implementation OCKCareCardTableViewHeader {
    UILabel *_dateLabel;
    
    OCKHeartView *_heartView;
    UILabel *_adherenceLabel;
    UILabel *_adherencePercentageLabel;
    
    UILabel *_topEdge;
    UILabel *_bottomEdge;
    
    NSNumberFormatter *_numberFormatter;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_dateLabel) {
        _dateLabel = [UILabel new];
        _dateLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_dateLabel];
    }
    _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _dateLabel.text = _date;
    
    if (!_heartView) {
        _heartView = [[OCKHeartView alloc] initWithFrame:CGRectMake(0, 0, HeartViewSize, HeartViewSize)];
        [self addSubview:_heartView];
    }
    _heartView.adherence = _adherence;
    
    if (!_adherencePercentageLabel) {
        _adherencePercentageLabel = [UILabel new];
        _adherencePercentageLabel.lineBreakMode = NSLineBreakByCharWrapping;
        _adherencePercentageLabel.textColor = OCKRedColor();
        [self addSubview:_adherencePercentageLabel];
    }
    _adherencePercentageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
    _adherencePercentageLabel.text = self.adherencePercentageString;
    
    if (!_adherenceLabel) {
        _adherenceLabel = [UILabel new];
        _adherenceLabel.text = @"Care completion";
        [self addSubview:_adherenceLabel];
    }
    _adherenceLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    
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
    
    _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _heartView.translatesAutoresizingMaskIntoConstraints = NO;
    _adherenceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _adherencePercentageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _topEdge.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomEdge.translatesAutoresizingMaskIntoConstraints = NO;

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
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:-HeartViewSize/2.25],
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
                                       [NSLayoutConstraint constraintWithItem:_adherencePercentageLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_adherencePercentageLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_heartView
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:5.0],
                                       [NSLayoutConstraint constraintWithItem:_adherenceLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_heartView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:15.0],
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

- (void)setAdherence:(CGFloat)adherence {
    _adherence = adherence;
    [self prepareView];
}

- (void)setDate:(NSString *)date {
    _date = date;
    [self prepareView];
}


#pragma mark - Helpers

- (NSString *)adherencePercentageString {
    if (!_numberFormatter) {
        _numberFormatter = [NSNumberFormatter new];
        _numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
        _numberFormatter.maximumFractionDigits = 0;
    }
    return [_numberFormatter stringFromNumber:@(_adherence)];
}

@end

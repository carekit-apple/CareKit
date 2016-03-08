//
//  OCKEvaluationTableViewHeader.m
//  CareKit
//
//  Created by Umer Khan on 2/4/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluationTableViewHeader.h"
#import "OCKRingView.h"
#import "OCKColors.h"


static const CGFloat TopMargin = 15.0;
static const CGFloat HorizontalMargin = 10.0;

static const CGFloat RingViewSize = 120.0;

@implementation OCKEvaluationTableViewHeader {
    OCKRingView *_ringView;
    UILabel *_titleLabel;
    UILabel *_dateLabel;
    
    UIView *_topEdge;
    UIView *_bottomEdge;
    
    NSMutableArray *_constraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
            self.backgroundColor = [UIColor clearColor];
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurEffectView.frame = self.bounds;
            blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            [self addSubview:blurEffectView];
        }
        else {
            self.backgroundColor = [UIColor whiteColor];
        }
        
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    if (!_ringView) {
        _ringView = [[OCKRingView alloc] initWithFrame:CGRectMake(0, 0, RingViewSize, RingViewSize)];
        [self addSubview:_ringView];
    }
    _ringView.value = _progress;
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.text = @"Activity completion";
        [self addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    
    if (!_dateLabel) {
        _dateLabel = [UILabel new];
        _dateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _dateLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_dateLabel];
    }
    _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _dateLabel.text = _date;
    
    if (!_topEdge) {
        _topEdge = [UIView new];
        _topEdge.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:_topEdge];
    }
    
    if (!_bottomEdge) {
        _bottomEdge = [UILabel new];
        _bottomEdge.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [self addSubview:_bottomEdge];
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    _constraints = [NSMutableArray new];
    
    _ringView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _topEdge.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_constraints addObjectsFromArray:@[
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
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:TopMargin],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:-RingViewSize/1.4],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:RingViewSize],
                                        [NSLayoutConstraint constraintWithItem:_ringView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:RingViewSize],
                                        [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_ringView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:TopMargin],
                                        [NSLayoutConstraint constraintWithItem:_dateLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_ringView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:HorizontalMargin],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeBottom
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_dateLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0.0],
                                        [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_dateLabel
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.0
                                                                      constant:0.0]
                                        ]];
    
    [NSLayoutConstraint activateConstraints:_constraints];
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    _ringView.value = _progress;
}

- (void)setDate:(NSString *)date {
    _date = date;
    [self prepareView];
}

@end

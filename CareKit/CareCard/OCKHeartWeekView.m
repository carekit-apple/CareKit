//
//  OCKHeartWeekView.m
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKHeartWeekView.h"
#import "OCKCareCard.h"
#import "OCKWeekView.h"


const static CGFloat HeartButtonSize = 20.0;

@implementation OCKHeartWeekView {
    OCKWeekView *_weekView;
    NSMutableArray <UIButton *> *_heartButtons;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareView];
    }
    return self;
}

- (void)prepareView {
    
    if (!_weekView) {
        _weekView = [[OCKWeekView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 25.0)];
        [self addSubview:_weekView];
    }

    _heartButtons = [NSMutableArray new];
    for (id careCard in _careCards) {
        OCKCareCard *card = (OCKCareCard *)careCard;
        UIButton *heart = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, HeartButtonSize, HeartButtonSize)];
        [heart setTitle:card.adherencePercentageString forState:UIControlStateNormal];
        [heart setTitleColor:[UIColor groupTableViewBackgroundColor] forState:UIControlStateNormal];
        heart.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        heart.backgroundColor = [UIColor redColor];
        heart.alpha = (card.adherence == 0) ? 0.05 : card.adherence;
        [heart addTarget:self
                  action:@selector(updateDayOfWeek:)
        forControlEvents:UIControlEventTouchDown];
        heart.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:heart];
        [_heartButtons addObject:heart];
    }
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _weekView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_weekView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_weekView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    for (int i = 0; i < _heartButtons.count; i++) {
        UILabel *dayLabel = (UILabel *)_weekView.weekLabels[i];
        [constraints addObjectsFromArray:@[
                                           [NSLayoutConstraint constraintWithItem:dayLabel
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_heartButtons[i]
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0
                                                                         constant:0.0],
                                           [NSLayoutConstraint constraintWithItem:dayLabel
                                                                        attribute:NSLayoutAttributeCenterX
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_heartButtons[i]
                                                                        attribute:NSLayoutAttributeCenterX
                                                                       multiplier:1.0
                                                                         constant:0.0]
                                           ]];
    }
    
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)setCareCards:(NSArray<OCKCareCard *> *)careCards {
    _careCards = careCards;
    [self prepareView];
}

- (void)updateDayOfWeek:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger day = [_heartButtons indexOfObject:button];
    _selectedDay = day;
    [_weekView highlightDay:day];
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(heartWeekViewSelectionDidChange:)]) {
        [_delegate heartWeekViewSelectionDidChange:self];
    }
}

@end

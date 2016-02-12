//
//  OCKTreatmentTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKTreatmentTableViewCell.h"
#import "OCKTreatment.h"
#import "OCKTreatment_Internal.h"


static const CGFloat HorizontalMargin = 15.0;
static const CGFloat TopMargin = 10.0;

@implementation OCKTreatmentTableViewCell {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    
    NSArray <UIButton *> *_frequencyButtons;
    
    UILabel *_leadingEdge;
}

- (void)setTreatment:(OCKTreatment *)treatment {
    _treatment = treatment;
    [self prepareView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)prepareView {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.text = _treatment.title;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.numberOfLines = 1;
        _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_textLabel];
    }
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _textLabel.text = _treatment.text;
    
    if (!_frequencyButtons) {
        _frequencyButtons = [NSArray new];
//        _treatment.completed = 0;
//        NSMutableArray *buttons = [NSMutableArray new];
//        for (NSInteger i = 0; i < _treatment.frequency; i++) {
//            UIButton *frequencyButton = [UIButton new];
//            frequencyButton.backgroundColor = _treatment.tintColor;
//            frequencyButton.translatesAutoresizingMaskIntoConstraints = NO;
//            [frequencyButton addTarget:self
//                                action:@selector(toggleFrequencyButton:)
//                      forControlEvents:UIControlEventTouchUpInside];
//            [buttons addObject:frequencyButton];
//            [self.contentView addSubview:frequencyButton];
//        }
//        _frequencyButtons = [buttons copy];
    }
    
    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self addSubview:_leadingEdge];
    }
//    _leadingEdge.backgroundColor = _treatment.tintColor;
    
    [self setUpContraints];
}

- (void)setUpContraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeBaseline
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_textLabel
                                                                    attribute:NSLayoutAttributeBaseline
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:HorizontalMargin],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_titleLabel
                                                                    attribute:NSLayoutAttributeTrailing
                                                                   multiplier:1.0
                                                                     constant:5.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:3.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    for (int i = 0; i < _frequencyButtons.count; i++) {
        if (i == 0) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.contentView
                                                                attribute:NSLayoutAttributeLeading
                                                               multiplier:1.0
                                                                 constant:HorizontalMargin]];
        } else {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_frequencyButtons[i-1]
                                                                attribute:NSLayoutAttributeTrailing
                                                               multiplier:1.0
                                                                 constant:5.0]];
        }
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_frequencyButtons[i]
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_titleLabel
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0
                                                             constant:5.0]];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)didChangePreferredContentSize {
    [self prepareView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)toggleFrequencyButton:(id)sender {
//    UIButton *button = (UIButton *)sender;
//    if (button.backgroundColor == _treatment.tintColor) {
//        _treatment.completed++;
//        button.backgroundColor = [UIColor lightGrayColor];
//    } else {
//        _treatment.completed--;
//        button.backgroundColor = _treatment.tintColor;
//    }
    
    if (_delegate &&
        [_delegate respondsToSelector:@selector(treatmentCellDidUpdateFrequency:)]) {
        [_delegate treatmentCellDidUpdateFrequency:self];
    }
    
}

@end

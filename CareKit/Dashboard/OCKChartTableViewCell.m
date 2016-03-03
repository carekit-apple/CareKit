//
//  OCKChartTableViewCell.m
//  CareKit
//
//  Created by Umer Khan on 1/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChartTableViewCell.h"
#import "OCKChart.h"
#import "OCKChart_Internal.h"
#import "OCKLineChart_Internal.h"
#import "OCKDiscreteChart_Internal.h"
#import "OCKPieChart_Internal.h"


static const CGFloat HorizontalMargin = 40.0;
static const CGFloat VerticalMargin = 20.0;
static const CGFloat TopMargin = 15.0;
static const CGFloat BottomMargin = 15.0;

@implementation OCKChartTableViewCell {
    UILabel *_titleLabel;
    UILabel *_textLabel;

    UIView *_chartView;
    UILabel *_xAxisLabel;
    UILabel *_yAxisLabel;
    
    UILabel *_leadingEdge;
}

- (void)setChart:(OCKChart *)chart {
    _chart = chart;
    _chartView = nil;
    [self prepareView];
}

- (void)prepareView {
    
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_titleLabel];
    }
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.text = _chart.title;
    _titleLabel.textColor = _chart.tintColor;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.textColor = [UIColor lightGrayColor];
        _textLabel.numberOfLines = 2;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_textLabel];
    }
    _textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _textLabel.text = _chart.text;
    
    _chartView = [_chart chartView];
    
    [self.contentView addSubview:_chartView];
    
    if (!_xAxisLabel) {
        _xAxisLabel = [UILabel new];
        _xAxisLabel.numberOfLines = 1;
        _xAxisLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_xAxisLabel];
    }
    _xAxisLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    if (!_yAxisLabel) {
        _yAxisLabel = [UILabel new];
        _yAxisLabel.numberOfLines = 1;
        _yAxisLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _yAxisLabel.transform = CGAffineTransformMakeRotation(M_PI/2);
        [self.contentView addSubview:_yAxisLabel];
    }
    _yAxisLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    if ([_chart conformsToProtocol:@protocol(OCKChartAxisProtocol)]) {
        OCKChart <OCKChartAxisProtocol> *protocolChart = (OCKChart <OCKChartAxisProtocol> *)_chart;
        _xAxisLabel.text = protocolChart.xAxisTitle;
        _yAxisLabel.text = protocolChart.yAxisTitle;
    }
    
    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _chart.tintColor;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _textLabel, _chartView, _xAxisLabel, _yAxisLabel, _leadingEdge);
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _chartView.translatesAutoresizingMaskIntoConstraints = NO;
    _xAxisLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _yAxisLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (_yAxisLabel.text) {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-horizontalMargin-[_chartView][_yAxisLabel]-|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:@{@"horizontalMargin" : @(HorizontalMargin)}
                                                                                   views:views]];
    } else {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-horizontalMargin-[_chartView]-horizontalMargin-|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:@{@"horizontalMargin" : @(HorizontalMargin)}
                                                                                   views:views]];
    }
    
    if (_xAxisLabel.text) {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topMargin-[_titleLabel]-verticalMargin-[_chartView][_xAxisLabel]-verticalMargin-[_textLabel]-bottomMargin-|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:@{@"verticalMargin" : @(VerticalMargin),
                                                                                           @"topMargin" : @(TopMargin),
                                                                                           @"bottomMargin" : @(BottomMargin)}
                                                                                   views:views]];
    } else {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topMargin-[_titleLabel]-verticalMargin-[_chartView][_textLabel]-|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:@{@"verticalMargin" : @(VerticalMargin),
                                                                                           @"topMargin" : @(TopMargin),
                                                                                           @"bottomMargin" : @(BottomMargin)}
                                                                                   views:views]];
    }
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_titleLabel]-|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_textLabel]-|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_chartView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_chartView
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:_chart.height],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_xAxisLabel
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_yAxisLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.contentView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self
                                                                    attribute:NSLayoutAttributeCenterY
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
    
    [NSLayoutConstraint activateConstraints:constraints];
    
}

- (UITableViewCellSelectionStyle)selectionStyle {
    return UITableViewCellSelectionStyleNone;
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

@end

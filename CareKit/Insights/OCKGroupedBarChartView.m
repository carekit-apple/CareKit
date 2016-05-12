/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
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


#import "OCKGroupedBarChartView.h"
#import "OCKLabel.h"
#import "OCKHelpers.h"


// #define LAYOUT_DEBUG 1

static const CGFloat BarPointSize = 12.0;
static const CGFloat BarEndFontSize = 11.0;
static const CGFloat MarginBetweenBars = 2.0;
static const CGFloat MarginBetweenGroups = 16.0;
static const CGFloat MarginBetweenBarAndLabel = 6.0;

@interface OCKGroupedBarChartBar : NSObject

@property (nonatomic, copy) NSNumber *value;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) UIColor *color;
@property (nonatomic) double valueLabelMaxWidth;

@end


@implementation OCKGroupedBarChartBar

@end


@interface OCKGroupedBarChartBarGroup : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSArray<OCKGroupedBarChartBar *> *bars;

@end


@implementation OCKGroupedBarChartBarGroup

@end


@interface OCKGroupedBarChartBarType : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) UIColor *color;

@end


@implementation OCKGroupedBarChartBarType

@end


@interface OCKChartBarView : UIView

- (instancetype)initWithBar:(OCKGroupedBarChartBar *)bar maxValue:(double)maxValue;

@property (nonatomic, strong) OCKGroupedBarChartBar *bar;

- (void)animationWithDuration:(NSTimeInterval)duration;

@end


@implementation OCKChartBarView {
    double _maxValue;
    UIView *_barView;
    CAShapeLayer *_barLayer;
    UILabel *_valueLabel;
}

- (instancetype)initWithBar:(OCKGroupedBarChartBar *)bar maxValue:(double)maxValue {
    self = [super init];
    if (self) {
        _maxValue = (maxValue == 0)? 1.0 : maxValue ;
        _bar = bar;
        [self prepareView];
    }
    return self;
}

- (void)animationWithDuration:(NSTimeInterval)duration {
    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = @0;
        animation.toValue = @1;
        animation.duration = duration * _bar.value.doubleValue/_maxValue;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.fillMode = kCAFillModeBoth;
        animation.removedOnCompletion = YES;
        
        [_barLayer addAnimation:animation forKey:animation.keyPath];
    }
    
    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        animation.fromValue = @(MarginBetweenBarAndLabel + CGRectGetWidth(_valueLabel.frame)/2.0);
        animation.toValue = @(_valueLabel.layer.position.x);
        animation.duration = duration * _bar.value.doubleValue/_maxValue;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.fillMode = kCAFillModeBoth;
        animation.removedOnCompletion = YES;
        
        [_valueLabel.layer addAnimation:animation forKey:animation.keyPath];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat barWidth = _barView.bounds.size.width;
    CGFloat barHeight = _barView.bounds.size.height;
    if (_barLayer == nil || _barLayer.bounds.size.width != barWidth) {
        
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path moveToPoint:CGPointMake(0, barHeight/2)];
        [path addLineToPoint:CGPointMake(barWidth, barHeight/2)];
        path.lineWidth = barHeight;
        
        _barLayer.path = path.CGPath;
        _barLayer.strokeColor = _bar.color.CGColor;
        _barLayer.lineWidth = barHeight;
    }
}

- (void)prepareView {
    self.backgroundColor = [UIColor whiteColor];
    
    _barView = [UIView new];
    _barLayer = [[CAShapeLayer alloc] init];
    [_barView.layer addSublayer:_barLayer];
#if LAYOUT_DEBUG
    _barView.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.2];
#endif
    _barView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _valueLabel = [UILabel new];
    _valueLabel.backgroundColor = self.backgroundColor;
    _valueLabel.text = _bar.text;
    _valueLabel.textColor = _bar.color;
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _valueLabel.font = [UIFont boldSystemFontOfSize:BarEndFontSize];
    
    [self addSubview:_barView];
    [self addSubview:_valueLabel];
    
    NSDictionary *views = @{@"barView":_barView, @"valueLabel":_valueLabel};
    
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSString *visualFormat = [NSString stringWithFormat:@"H:|[barView]-%f-[valueLabel]", MarginBetweenBarAndLabel];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:visualFormat   
                                                          options:NSLayoutFormatDirectionLeadingToTrailing
                                                          metrics:nil
                                                            views:views]];
    
    double percentage = _bar.value.doubleValue/_maxValue;
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_barView
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeWidth
                                                       multiplier:percentage
                                                         constant:-(_bar.valueLabelMaxWidth+6.0)*percentage]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_barView
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:BarPointSize]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_valueLabel
                                                        attribute:NSLayoutAttributeBaseline
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant:10.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_valueLabel
                                                        attribute:NSLayoutAttributeTrailing
                                                        relatedBy:NSLayoutRelationLessThanOrEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeTrailing
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [_valueLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[barView]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:views]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

@end


@interface OCKGroupedBarChartBarGroupView : UIView

@property (nonatomic, strong) OCKGroupedBarChartBarGroup *group;

@property (nonatomic, strong) UIView *labelBox;

- (instancetype)initWithGroup:(OCKGroupedBarChartBarGroup *)group maxValue:(double)maxValue;

- (void)animationWithDuration:(NSTimeInterval)duration;

@end


@implementation OCKGroupedBarChartBarGroupView {
    OCKLabel *_titleLabel;
    OCKLabel *_textLabel;
    UIView *_barBox;
    double _maxValue;
}

- (instancetype)initWithGroup:(OCKGroupedBarChartBarGroup *)group maxValue:(double)maxValue {
    NSParameterAssert(group);
    self = [super init];
    if (self) {
        _group = group;
        _maxValue = maxValue;
        [self prepareView];
    }
    return self;
}

- (void)animationWithDuration:(NSTimeInterval)duration {
    for (OCKChartBarView *barView in _barBox.subviews) {
        [barView animationWithDuration:duration];
    }
}

- (void)prepareView {
    self.backgroundColor = [UIColor whiteColor];
    
    _labelBox = [UIView new];
    _labelBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_labelBox];
    
    _titleLabel = [OCKLabel new];
    _titleLabel.backgroundColor = self.backgroundColor;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.text = _group.title;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.textStyle = UIFontTextStyleCaption1;
    _titleLabel.textColor = OCKSystemGrayColor();
    [_labelBox addSubview:_titleLabel];
    
    _textLabel = [OCKLabel new];
    _textLabel.backgroundColor = self.backgroundColor;
    _textLabel.text = _group.text;
    _textLabel.adjustsFontSizeToFitWidth = YES;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.textStyle = UIFontTextStyleCaption1;
    _textLabel.textColor = OCKSystemGrayColor();
    [_labelBox addSubview:_textLabel];
    
    
    NSMutableArray *constraints = [NSMutableArray new];
    NSDictionary *labels = @{@"_titleLabel":_titleLabel, @"_textLabel":_textLabel};
    
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_titleLabel
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_labelBox
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_textLabel
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_titleLabel
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_labelBox
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_textLabel
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0 constant:0.0]];
    
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleLabel]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:labels]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_textLabel]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:labels]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_titleLabel
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_textLabel
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0 constant:0.0]];
    
    _barBox = [UIView new];
    _barBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_barBox];
    
    NSDictionary *boxes = @{@"_barBox":_barBox, @"_labelBox":_labelBox};
    
#if LAYOUT_DEBUG
    _barBox.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.1];
    _labelBox.backgroundColor = [[UIColor purpleColor] colorWithAlphaComponent:0.1];
#endif
    
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_labelBox]-16.0-[_barBox]|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:boxes]];
    
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:_barBox
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:_labelBox
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:_barBox
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0 constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                           toItem:_labelBox
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0 constant:0.0]];
    
    [_barBox setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [_labelBox setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    for (OCKGroupedBarChartBar *bar in _group.bars) {
        OCKChartBarView *barView = [[OCKChartBarView alloc] initWithBar:bar maxValue:_maxValue];
        barView.translatesAutoresizingMaskIntoConstraints = NO;
        UIView *viewAbove = _barBox.subviews.lastObject;
        [_barBox addSubview:barView];

#if LAYOUT_DEBUG
        barView.backgroundColor = [UIColor lightGrayColor];
#endif
        
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[barView]|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:nil
                                                                                   views:@{@"barView": barView}]];
        
        
        if (viewAbove) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:barView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:viewAbove
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0 constant:MarginBetweenBars]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:barView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:viewAbove
                                                                attribute:NSLayoutAttributeHeight
                                                               multiplier:1.0 constant:0.0]];
        } else {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:barView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_barBox
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0 constant:0.0]];
            
           
        }
    }
    
    if (_barBox.subviews.lastObject) {
        OCKChartBarView *barView = _barBox.subviews.lastObject;
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_barBox
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:barView
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0 constant:0.0]];
        
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

@end


@interface OCKGroupedBarChartView ()

@end


@interface OCKChartLegendCell : UIView

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, copy) NSString *text;

@end

@implementation OCKChartLegendCell {
    UIView *_colorBox;
    UILabel *_label;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _colorBox = [UIView new];
        _colorBox.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_colorBox];
        _label = [OCKLabel new];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.font = [UIFont systemFontOfSize:12.0];
        [self addSubview:_label];
        [self setUpConstraints];
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    _colorBox.backgroundColor = color;
}

- (void)setText:(NSString *)text {
    _label.text = text;
}

- (void)setUpConstraints {
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_colorBox]-6.0-[_label]-32.0-|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:@{@"_colorBox":_colorBox, @"_label": _label}]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_colorBox]-1.0-|"
                                                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                                                             metrics:nil
                                                                               views:@{@"_colorBox":_colorBox, @"_label": _label}]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_label
                                                        attribute:NSLayoutAttributeBaseline
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_colorBox
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant:10.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_colorBox
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_colorBox
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_colorBox
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.0
                                                         constant:12.0]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

@end


@interface OCKChartLegendView : UILabel

- (instancetype)initWithTitles:(NSArray<NSString *> *)titles colors:(NSArray<UIColor *> *)colors;

@end


@implementation OCKChartLegendView

- (instancetype)initWithTitles:(NSArray<NSString *> *)titles colors:(NSArray<UIColor *> *)colors {
    
    self = [super init];
    if (self) {
        NSMutableAttributedString *string = [NSMutableAttributedString new];
        
        UITableViewCell *tc = [UITableViewCell new];
        
        for (NSInteger i = 0; i < titles.count; i++) {
            NSString *title = titles[i];
            UIColor *color = colors[i];
            
            OCKChartLegendCell *cell = [OCKChartLegendCell new];
            cell.text = title;
            cell.color = color;
            
            CGSize size = [cell systemLayoutSizeFittingSize:CGSizeMake(1, 1) withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
            cell.frame = CGRectMake(0, 0, size.width, size.height);
            [tc.contentView addSubview:cell];
            
            UIGraphicsBeginImageContextWithOptions(cell.frame.size, YES, 0.0);
            [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            NSTextAttachment *attachment = [NSTextAttachment new];
            attachment.image = image;
            
            NSAttributedString *attrStr = [NSAttributedString attributedStringWithAttachment:attachment];
            [string appendAttributedString:attrStr];
        }
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 2.0;
        [string addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, string.length)];

        self.numberOfLines = 0;
        self.lineBreakMode = NSLineBreakByWordWrapping;
        self.attributedText = string;
        self.textAlignment = NSTextAlignmentCenter;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

@end


@implementation OCKGroupedBarChartView {
    NSMutableArray<OCKGroupedBarChartBarGroup *> *_barGroups;
    NSMutableArray<OCKGroupedBarChartBarType *> *_barTypes;
    
    NSMutableArray<NSLayoutConstraint *> *_constraints;
    
    UIView *_groupsBox;
    OCKChartLegendView *_legendsView;
    
    BOOL _shouldInvalidateLegendViewIntrinsicContentSize;
    double _maxValue;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

- (void)setDataSource:(id<OCKGroupedBarChartViewDataSource>)dataSource {
    _dataSource = dataSource;
    
    if (_dataSource) {
        NSUInteger barsPerGroup = [_dataSource numberOfDataSeriesInChartView:self];
        
        _barTypes = [NSMutableArray new];
        for (NSUInteger barIndex = 0; barIndex < barsPerGroup; barIndex++) {
            OCKGroupedBarChartBarType *barType = [OCKGroupedBarChartBarType new];
            barType.color = [_dataSource chartView:self colorForDataSeriesAtIndex:barIndex];
            barType.name = [_dataSource chartView:self nameForDataSeriesAtIndex:barIndex];
            [_barTypes addObject:barType];
        }
        
        NSUInteger numberOfGroups = [_dataSource numberOfCategoriesPerDataSeriesInChartView:self];
        
        _maxValue = DBL_MIN;
        double minValue = DBL_MAX;
        _barGroups = [NSMutableArray new];
        
        double maxValueLabelWidth = 0;
        UILabel *sizingLabel = [UILabel new];
        sizingLabel.font = [UIFont boldSystemFontOfSize:BarEndFontSize];
        CGSize sizingLabelMaxSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
        
        for (NSUInteger groupIndex = 0; groupIndex < numberOfGroups; groupIndex++) {
            OCKGroupedBarChartBarGroup *barGroup = [OCKGroupedBarChartBarGroup new];
            barGroup.title = [_dataSource chartView:self titleForCategoryAtIndex:groupIndex];
            if ([_dataSource respondsToSelector:@selector(chartView:subtitleForCategoryAtIndex:)]) {
                barGroup.text = [_dataSource chartView:self subtitleForCategoryAtIndex:groupIndex];
            }
            
            NSMutableArray *bars = [NSMutableArray new];
            for (NSUInteger barIndex = 0; barIndex < barsPerGroup; barIndex++) {
                OCKGroupedBarChartBar *bar = [OCKGroupedBarChartBar new];
                bar.value = [_dataSource chartView:self valueForCategoryAtIndex:groupIndex inDataSeriesAtIndex:barIndex];
                if (bar.value.doubleValue > _maxValue) {
                    _maxValue = bar.value.doubleValue;
                }
                if (bar.value.doubleValue < minValue) {
                    minValue = bar.value.doubleValue;
                }
                bar.text = [_dataSource chartView:self valueStringForCategoryAtIndex:groupIndex inDataSeriesAtIndex:barIndex];
                bar.color = _barTypes[barIndex].color;
                [bars addObject:bar];
                
                sizingLabel.text = bar.text;
                CGSize requiredSize = [sizingLabel sizeThatFits:sizingLabelMaxSize];
                if (maxValueLabelWidth < requiredSize.width) {
                    maxValueLabelWidth = requiredSize.width;
                }
            }
            barGroup.bars = [bars copy];
            [_barGroups addObject:barGroup];
        }
        
        for (OCKGroupedBarChartBarGroup *barGroup in _barGroups) {
            for (OCKGroupedBarChartBar *bar in barGroup.bars) {
                bar.valueLabelMaxWidth = maxValueLabelWidth;
            }
        }
        
        BOOL specifiedMinValue = NO;
        if ([_dataSource respondsToSelector:@selector(minimumScaleRangeValueOfChartView:)]) {
            NSNumber *sepecifiedMinValue = [_dataSource minimumScaleRangeValueOfChartView:self];
            if (sepecifiedMinValue.doubleValue < minValue) {
                minValue = sepecifiedMinValue.doubleValue;
            }
            specifiedMinValue = YES;
        } else if(minValue > 0) {
            // Unspecidied situation, use 0 as min value.
            minValue = 0;
        }
        
        if ([_dataSource respondsToSelector:@selector(maximumScaleRangeValueOfChartView:)]) {
            NSNumber *sepecifiedMaxValue = [_dataSource maximumScaleRangeValueOfChartView:self];
            if (sepecifiedMaxValue.doubleValue > _maxValue) {
                _maxValue = sepecifiedMaxValue.doubleValue;
            }
        }
        
        // If a minValue is specified, use the min value as the baseline to adjust bar values.
        if (specifiedMinValue) {
            for (OCKGroupedBarChartBarGroup *barGroup in _barGroups) {
                for (OCKGroupedBarChartBar *bar in barGroup.bars) {
                    bar.value = @(bar.value.doubleValue - minValue);
                }
            }
            _maxValue = _maxValue - minValue;
        }
    }
    [self recreateViews];
}

- (void)animateWithDuration:(NSTimeInterval)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (OCKGroupedBarChartBarGroupView *groupView in _groupsBox.subviews) {
            [groupView animationWithDuration:duration];
        }
    });
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_shouldInvalidateLegendViewIntrinsicContentSize) {
        _shouldInvalidateLegendViewIntrinsicContentSize = NO;
        [_legendsView invalidateIntrinsicContentSize];
    }
}

- (void)recreateViews {
    [NSLayoutConstraint deactivateConstraints:_constraints];
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    _constraints = [NSMutableArray new];
    
    _groupsBox = [UIView new];
    _groupsBox.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_groupsBox];
    
    [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_groupsBox]|"
                                                                              options:NSLayoutFormatDirectionLeadingToTrailing
                                                                              metrics:nil
                                                                                views:@{@"_groupsBox": _groupsBox}]];
    
    _legendsView = [[OCKChartLegendView alloc] initWithTitles:[_barTypes valueForKeyPath:@"name"] colors:[_barTypes valueForKeyPath:@"color"] ];
    _legendsView.translatesAutoresizingMaskIntoConstraints = NO;
#if LAYOUT_DEBUG
    _legendsView.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
#endif
    _shouldInvalidateLegendViewIntrinsicContentSize = YES;
    [self addSubview:_legendsView];

    [_constraints addObject:[NSLayoutConstraint constraintWithItem:_legendsView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationLessThanOrEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0 constant:0.0]];
    
    [_constraints addObject:[NSLayoutConstraint constraintWithItem:_legendsView
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0 constant:0.0]];
    
    [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_groupsBox]-24.0-[_legendsView]|"
                                                                              options:NSLayoutFormatDirectionLeadingToTrailing
                                                                              metrics:nil
                                                                                views:@{@"_groupsBox": _groupsBox, @"_legendsView": _legendsView}]];
    
    
    for (OCKGroupedBarChartBarGroup *barGroup in _barGroups) {
        OCKGroupedBarChartBarGroupView *groupView = [[OCKGroupedBarChartBarGroupView alloc] initWithGroup:barGroup maxValue:_maxValue];
        [self updateGroupViewAccessibility:groupView];
        groupView.translatesAutoresizingMaskIntoConstraints = NO;
#if LAYOUT_DEBUG
        groupView.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
#endif
        OCKGroupedBarChartBarGroupView *viewAbove = _groupsBox.subviews.lastObject;
        [_groupsBox addSubview:groupView];
        
        [_constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[groupView]|"
                                                                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                 metrics:nil
                                                                                   views:@{@"groupView": groupView}]];
        
        if (viewAbove) {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:viewAbove
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0 constant:MarginBetweenGroups]];
            
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:viewAbove
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:1.0 constant:0.0]];
            
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView.labelBox
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:viewAbove.labelBox
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.0 constant:0.0]];
            
        } else {
            [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_groupsBox
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0 constant:2.0]];
            
           
        }
        
        [_constraints addObject:[NSLayoutConstraint constraintWithItem:groupView
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_groupsBox
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:1.0 constant:0.0]];
    
    }
    
    if (self.subviews.lastObject) {
        UIView *lastView = _groupsBox.subviews.lastObject;
        [_constraints addObject:[NSLayoutConstraint constraintWithItem:lastView
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_groupsBox
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0 constant:0.0]];
        
    }
    
    [NSLayoutConstraint activateConstraints:_constraints];
}


#pragma mark - Accessibility

- (void)updateGroupViewAccessibility:(OCKGroupedBarChartBarGroupView *)groupView {
    OCKGroupedBarChartBarGroup *barGroup = groupView.group;
    NSString *barsString = @"";
    for (int i = 0; i < [barGroup.bars count]; i++) {
        OCKGroupedBarChartBar *bar = [barGroup.bars objectAtIndex:i];
        barsString = [NSString stringWithFormat:@"%@, %@, %@", barsString, _barTypes[i].name,  bar.text];
    }
    groupView.accessibilityValue = barsString;
    groupView.isAccessibilityElement = YES;
    groupView.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", barGroup.title, barGroup.text];
}

- (NSArray *)accessibilityElements {
    return [_groupsBox subviews];
}

@end

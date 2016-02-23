//
//  OCKCareCardDetailViewController.m
//  CareKit
//
//  Created by Umer Khan on 2/18/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKCareCardDetailViewController.h"
#import "OCKCarePlanActivity.h"


static const CGFloat LeadingMargin = 30.0;
static const CGFloat TrailingMargin = 50.0;
static const CGFloat TopMargin = 100.0;
static const CGFloat VerticalMargin = 15.0;

static const CGFloat ImageViewSize = 160.0;

@implementation OCKCareCardDetailViewController {
    UILabel *_titleLabel;
    UILabel *_textLabel;
    UILabel *_instructionsLabel;
    UIImageView *_imageView;
    
    UILabel *_leadingEdge;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)setTreatment:(OCKCarePlanActivity *)treatment {
    _treatment = treatment;
    [self prepareView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePreferredContentSize)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (void)prepareView {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.font = [UIFont systemFontOfSize:40.0 weight:UIFontWeightRegular];
        [self.view addSubview:_titleLabel];
    }
    _titleLabel.text = _treatment.title;
    
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _textLabel.font = [UIFont systemFontOfSize:25.0 weight:UIFontWeightThin];
        [self.view addSubview:_textLabel];
    }
    _textLabel.text = _treatment.text;

    if (!_instructionsLabel) {
        _instructionsLabel = [UILabel new];
        _instructionsLabel.numberOfLines = 10;
        _instructionsLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _instructionsLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightLight];
        [self.view addSubview:_instructionsLabel];
    }
    // TODO: Implement this.
    _instructionsLabel.text = @"Make sure to eat before each event and drink at least 3 glasses of water.";
    
    if (!_imageView) {
        _imageView = [UIImageView new];
        [self.view addSubview:_imageView];
    }
    // TODO: Implement this.
    _imageView.image = [UIImage imageNamed:@"test"];
    _imageView.backgroundColor = _treatment.tintColor;
    
    if (!_leadingEdge) {
        _leadingEdge = [UILabel new];
        [self.view addSubview:_leadingEdge];
    }
    _leadingEdge.backgroundColor = _treatment.tintColor;
    
    [self setUpConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _instructionsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    _leadingEdge.translatesAutoresizingMaskIntoConstraints = NO;
    
    [constraints addObjectsFromArray:@[
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:TopMargin],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:LeadingMargin],
                                       [NSLayoutConstraint constraintWithItem:_titleLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_textLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_textLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_titleLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_instructionsLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_textLabel
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_instructionsLabel
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeWidth
                                                                   multiplier:1.0
                                                                     constant:-TrailingMargin],
                                       [NSLayoutConstraint constraintWithItem:_instructionsLabel
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_textLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:VerticalMargin],
                                       [NSLayoutConstraint constraintWithItem:_imageView
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_instructionsLabel
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:5*VerticalMargin],
                                       [NSLayoutConstraint constraintWithItem:_imageView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0
                                                                     constant:0.0],
                                       [NSLayoutConstraint constraintWithItem:_imageView
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:ImageViewSize],
                                       [NSLayoutConstraint constraintWithItem:_imageView
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0
                                                                     constant:ImageViewSize],
                                       [NSLayoutConstraint constraintWithItem:_leadingEdge
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
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
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1.0
                                                                     constant:0.0]
                                       ]];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)didChangePreferredContentSize {
    [self prepareView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end

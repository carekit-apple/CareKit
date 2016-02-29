//
//  OCKEvaluationTableViewHeader.h
//  CareKit
//
//  Created by Umer Khan on 2/4/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCircleView;

@interface OCKEvaluationTableViewHeader : UIView

@property (nonatomic) CGFloat progress;
@property (nonatomic) OCKCircleView *circleView;
@property (nonatomic, copy) NSString *date;

@end

NS_ASSUME_NONNULL_END

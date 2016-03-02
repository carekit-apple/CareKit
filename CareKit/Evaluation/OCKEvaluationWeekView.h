//
//  OCKEvaluationWeekView.h
//  CareKit
//
//  Created by Umer Khan on 2/16/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@class OCKEvaluationWeekView, OCKWeekView;

@protocol OCKEvaluationWeekViewDelegate <NSObject>

@required

- (void)evaluationWeekViewSelectionDidChange:(OCKEvaluationWeekView *)evaluationWeekView;

@end


@interface OCKEvaluationWeekView : UIView

@property (nonatomic) id<OCKEvaluationWeekViewDelegate> delegate;
@property (nonatomic, copy) NSArray *progressValues;
@property (nonatomic, readonly) OCKWeekView *weekView;
@property (nonatomic) NSInteger selectedIndex;

@end

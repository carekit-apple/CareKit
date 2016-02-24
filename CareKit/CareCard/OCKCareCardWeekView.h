//
//  OCKHeartWeekView.h
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCareCardWeekView, OCKWeekView;

@protocol OCKCareCardWeekViewDelegate <NSObject>

@required

- (void)careCardWeekViewSelectionDidChange:(OCKCareCardWeekView *)careCardWeekView;

@end


@interface OCKCareCardWeekView : UIView

@property (nonatomic) id<OCKCareCardWeekViewDelegate> delegate;
@property (nonatomic, copy) NSArray *adherenceValues;
@property (nonatomic, readonly) OCKWeekView *weekView;
@property (nonatomic, readonly) NSInteger selectedIndex;

@end

NS_ASSUME_NONNULL_END

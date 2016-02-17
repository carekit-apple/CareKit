//
//  OCKHeartWeekView.h
//  CareKit
//
//  Created by Umer Khan on 1/29/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKCareCard, OCKHeartWeekView;

@protocol OCKHeartWeekDelegate <NSObject>

@required

- (void)heartWeekViewSelectionDidChange:(OCKHeartWeekView *)heartWeekView;

@end


@interface OCKHeartWeekView : UIView

@property (nonatomic) NSArray <OCKCareCard *> *careCards;
@property (nonatomic) id<OCKHeartWeekDelegate> delegate;
@property (nonatomic, readonly) NSInteger selectedDay;

@end

NS_ASSUME_NONNULL_END

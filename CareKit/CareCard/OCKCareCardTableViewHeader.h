//
//  OCKCareCardView.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKAdherence;

@interface OCKCareCardTableViewHeader : UIView

@property (nonatomic) CGFloat adherence;
@property (nonatomic, copy) NSString *date;

@end

NS_ASSUME_NONNULL_END

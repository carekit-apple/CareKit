//
//  OCKEvaluationTableViewHeader.h
//  CareKit
//
//  Created by Umer Khan on 2/4/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OCKEvaluationTableViewHeader : UIView

@property (nonatomic, copy) NSString *date;
@property (nonatomic) CGFloat progress;
@property (nonatomic, copy) NSString *text;

@end

NS_ASSUME_NONNULL_END

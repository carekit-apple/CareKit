//
//  OCKEvaluationTableViewCell.h
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKEvaluationEvent;

@interface OCKEvaluationTableViewCell : UITableViewCell

@property (nonatomic) OCKEvaluationEvent *evaluationEvent;

@end

NS_ASSUME_NONNULL_END

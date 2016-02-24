//
//  OCKCarePlanStore_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/12/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>

@interface OCKCarePlanStore ()

@property (nonatomic, weak, nullable) id<OCKCarePlanStoreDelegate> careCardUIDelegate;

@property (nonatomic, weak, nullable) id<OCKCarePlanStoreDelegate> checkupsUIDelegate;

@end

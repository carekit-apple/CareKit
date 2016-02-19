//
//  OCKCarePlanEventResult_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/18/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>
#import <CoreData/CoreData.h>
#import "OCKCarePlanEvent_Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface OCKCarePlanEventResult () <OCKCoreDataObjectMirroring>

@end

@class OCKCDCarePlanEvent;
@interface OCKCDCarePlanEventResult : NSManagedObject

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                        result:(OCKCarePlanEventResult *)result
                         event:(OCKCDCarePlanEvent *)cdEvent;

- (void)updateWithResult:(OCKCDCarePlanEventResult *)result;

@end


@interface OCKCDCarePlanEventResult (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *creationDate;
@property (nullable, nonatomic, retain) NSDate *completionDate;
@property (nullable, nonatomic, retain) NSString *valueString;
@property (nullable, nonatomic, retain) NSString *unitString;
@property (nullable, nonatomic, retain) id userInfo;
@property (nullable, nonatomic, retain) OCKCDCarePlanEvent *event;

@end

NS_ASSUME_NONNULL_END
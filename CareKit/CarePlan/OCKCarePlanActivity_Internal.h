//
//  OCKCarePlanItem_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanActivity.h"
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OCKCoreDataObjectMirroring <NSObject>

- (instancetype)initWithCoreDataObject:(NSManagedObject *)cdObject;

@end


@interface OCKCarePlanActivity () <OCKCoreDataObjectMirroring>

@end

@class OCKCDCarePlanItemType;

@interface OCKCDCarePlanActivity : NSManagedObject

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                          item:(OCKCarePlanActivity *)item;

@property (nullable, nonatomic, retain) id color;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) OCKCareSchedule *schedule;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *detailText;
@property (nullable, nonatomic, retain) NSNumber *type;
@property (nullable, nonatomic, retain) NSString *groupIdentifier;
@property (nullable, nonatomic, retain) NSNumber *optional;
@property (nullable, nonatomic, retain) NSNumber *numberOfDaysWriteable;
@property (nullable, nonatomic, retain) NSNumber *resultResettable;
@property (nullable, nonatomic, retain) NSDictionary *userInfo;

@end

NS_ASSUME_NONNULL_END
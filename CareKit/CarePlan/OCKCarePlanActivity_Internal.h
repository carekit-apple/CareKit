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

- (instancetype)initWithIdentifier:(NSString *)identifier
                              type:(nullable NSString *)type
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
                             color:(nullable UIColor *)color
                          schedule:(OCKCareSchedule *)schedule
                          optional:(BOOL)optional
              eventMutableDayRange:(OCKDayRange)eventMutableDayRange;

@end

@class OCKCDCarePlanItemType;

@interface OCKCDCarePlanItem : NSManagedObject

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                          item:(OCKCarePlanActivity *)item;

@property (nullable, nonatomic, retain) id color;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) id schedule;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSNumber *optional;
@property (nullable, nonatomic, retain) NSNumber *mutableDaysBeforeEventDay;
@property (nullable, nonatomic, retain) NSNumber *mutableDaysAfterEventDay;

@end

NS_ASSUME_NONNULL_END
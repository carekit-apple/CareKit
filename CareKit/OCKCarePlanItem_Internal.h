//
//  OCKCarePlanItem_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanItem.h"
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OCKCoreDataObjectMirroring <NSObject>

- (instancetype)initWithCoreDataObject:(NSManagedObject *)cdObject;

@end


@class OCKCDCarePlanItem;



@interface OCKCarePlanItem () <OCKCoreDataObjectMirroring>

- (instancetype)initWithType:(nullable NSString *)type
                       title:(nullable NSString *)title
                        text:(nullable NSString *)text
                       color:(nullable UIColor *)color
                    schedule:(OCKCareSchedule *)schedule
                    optional:(BOOL)optional;

@end

@class OCKCDCarePlanItemType;

@interface OCKCDCarePlanItem : NSManagedObject

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                          item:(OCKCarePlanItem *)item;

@property (nullable, nonatomic, retain) id color;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) id schedule;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSNumber *optional;

@end

NS_ASSUME_NONNULL_END
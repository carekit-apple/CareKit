//
//  OCKTreatment_Internal.h
//  CareKit
//
//  Created by Yuan Zhu on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <CareKit/CareKit.h>
#import "OCKCarePlanItem_Internal.h"

@class OCKCDTreatmentEvent;

NS_ASSUME_NONNULL_BEGIN

@interface OCKCDTreatment : OCKCDCarePlanItem

@end

@interface OCKCDTreatment (CoreDataProperties)

@property (nullable, nonatomic, retain) NSSet<OCKCDTreatmentEvent *> *events;

@end

@interface OCKCDTreatment (CoreDataGeneratedAccessors)

- (void)addEventsObject:(OCKCDTreatmentEvent *)value;
- (void)removeEventsObject:(OCKCDTreatmentEvent *)value;
- (void)addEvents:(NSSet<OCKCDTreatmentEvent *> *)values;
- (void)removeEvents:(NSSet<OCKCDTreatmentEvent *> *)values;

@end

NS_ASSUME_NONNULL_END



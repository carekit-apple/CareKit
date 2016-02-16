//
//  OCKCarePlanItem.m
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanActivity.h"
#import "OCKCarePlanActivity_Internal.h"
#import "OCKHelpers.h"

@implementation OCKCarePlanActivity

- (instancetype)initWithIdentifier:(NSString *)identifier
                              type:(NSString *)type
                             title:(NSString *)title
                              text:(NSString *)text
                             color:(UIColor *)color
                          schedule:(OCKCareSchedule *)schedule
                          optional:(BOOL)optional
              eventMutableDayRange:(OCKDayRange)eventMutableDayRange{
    
    NSParameterAssert(type);
    NSParameterAssert(identifier);
    NSParameterAssert(schedule);
    
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _type = [type copy];
        _title = [title copy];
        _text = [text copy];
        _color = color;
        _schedule = schedule;
        _optional = optional;
        _eventMutableDayRange = eventMutableDayRange;
    }
    return self;
}

- (instancetype)initWithCoreDataObject:(OCKCDCarePlanItem *)cdObject {
    
    NSParameterAssert(cdObject);
    self = [super init];
    if (self) {
        _identifier = cdObject.identifier;
        _type = cdObject.type;
        _title = [cdObject.title copy];
        _text = [cdObject.text copy];
        _color = cdObject.color;
        _schedule = cdObject.schedule;
        _optional = [cdObject.optional boolValue];
        OCKDayRange range;
        range.daysBeforeEventDay = cdObject.mutableDaysBeforeEventDay.unsignedIntegerValue;
        range.daysAfterEventDay = cdObject.mutableDaysAfterEventDay.unsignedIntegerValue;
        _eventMutableDayRange =  range;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_CLASS(coder, identifier, NSString);
        OCK_DECODE_OBJ_CLASS(coder, title, NSString);
        OCK_DECODE_OBJ_CLASS(coder, text, NSString);
        OCK_DECODE_OBJ_CLASS(coder, color, UIColor);
        OCK_DECODE_OBJ_CLASS(coder, schedule, OCKCareSchedule);
        OCK_DECODE_OBJ_CLASS(coder, type, NSString);
        OCK_DECODE_BOOL(coder, optional);
        OCKDayRange range;
        range.daysBeforeEventDay = [[coder decodeObjectOfClass:[NSNumber class] forKey:@"daysBeforeEventDay"] unsignedIntegerValue];
        range.daysAfterEventDay = [[coder decodeObjectOfClass:[NSNumber class] forKey:@"daysAfterEventDay"] unsignedIntegerValue];
        _eventMutableDayRange =  range;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    OCK_ENCODE_OBJ(coder, identifier);
    OCK_ENCODE_OBJ(coder, title);
    OCK_ENCODE_OBJ(coder, text);
    OCK_ENCODE_OBJ(coder, color);
    OCK_ENCODE_OBJ(coder, schedule);
    OCK_ENCODE_OBJ(coder, type);
    OCK_ENCODE_BOOL(coder, optional);
    [coder encodeObject:@(_eventMutableDayRange.daysBeforeEventDay) forKey:@"daysBeforeEventDay"];
    [coder encodeObject:@(_eventMutableDayRange.daysAfterEventDay) forKey:@"daysAfterEventDay"];
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.text, castObject.text) &&
            OCKEqualObjects(self.color, castObject.color) &&
            OCKEqualObjects(self.schedule, castObject.schedule) &&
            OCKEqualObjects(self.type, castObject.type) &&
            OCKEqualObjects(self.identifier, castObject.identifier) &&
            (self.optional == castObject.optional) &&
            (self.eventMutableDayRange.daysBeforeEventDay == castObject.eventMutableDayRange.daysBeforeEventDay) &&
            (self.eventMutableDayRange.daysAfterEventDay == castObject.eventMutableDayRange.daysAfterEventDay)
            );
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCarePlanActivity *item = [[[self class] allocWithZone:zone] init];
    item->_title = [_title copy];
    item->_identifier = [_identifier copy];
    item->_text = [_text copy];
    item->_color = _color;
    item->_schedule = _schedule;
    item->_type = _type;
    item->_optional = _optional;
    item->_eventMutableDayRange = _eventMutableDayRange;
    return item;
}

@end


@implementation OCKCDCarePlanItem

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                          item:(OCKCarePlanActivity *)item {
    
    NSParameterAssert(item);
    self = [self initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self) {
        self.identifier = item.identifier;
        self.title = item.title;
        self.text = item.text;
        self.color = item.color;
        self.schedule = item.schedule;
        self.type = item.type;
        self.optional = @(item.optional);
        self.mutableDaysBeforeEventDay = @(item.eventMutableDayRange.daysBeforeEventDay);
        self.mutableDaysAfterEventDay = @(item.eventMutableDayRange.daysAfterEventDay);
    }
    return self;
}

@dynamic mutableDaysBeforeEventDay;
@dynamic mutableDaysAfterEventDay;
@dynamic color;
@dynamic identifier;
@dynamic schedule;
@dynamic text;
@dynamic title;
@dynamic type;
@dynamic optional;

@end


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
                              type:(OCKCarePlanActivityType)type
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
                         tintColor:(nullable UIColor *)tintColor
                          schedule:(OCKCareSchedule *)schedule {
    
    OCKDayRange range = {0, 0};
    
    return [self initWithIdentifier:identifier
                    groupIdentifier:nil
                               type:type
                              title:title
                               text:text
                          tintColor:tintColor
                           schedule:schedule
                           optional:NO
               eventMutableDayRange:range
                   resultResettable:NO
                           userInfo:nil];
}


- (instancetype)initWithIdentifier:(NSString *)identifier
                   groupIdentifier:(nullable NSString *)groupIdentifier
                              type:(OCKCarePlanActivityType)type
                             title:(nullable NSString *)title
                              text:(nullable NSString *)text
                         tintColor:(nullable UIColor *)tintColor
                          schedule:(OCKCareSchedule *)schedule
                          optional:(BOOL)optional
              eventMutableDayRange:(OCKDayRange)eventMutableDayRange
                  resultResettable:(BOOL)resultResettable
                          userInfo:(nullable NSDictionary *)userInfo {
    
    NSParameterAssert(identifier);
    NSParameterAssert(schedule);
    
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _groupIdentifier = [groupIdentifier copy];
        _type = type;
        _title = [title copy];
        _text = [text copy];
        _tintColor = tintColor;
        _schedule = schedule;
        _optional = optional;
        _eventMutableDayRange = eventMutableDayRange;
        _resultResettable = resultResettable;
        _userInfo = [userInfo copy];
    }
    return self;
}

- (instancetype)initWithCoreDataObject:(OCKCDCarePlanActivity *)cdObject {
    
    NSParameterAssert(cdObject);
    self = [super init];
    if (self) {
        _identifier = cdObject.identifier;
        _groupIdentifier = cdObject.groupIdentifier;
        _type = cdObject.type.integerValue;
        _title = [cdObject.title copy];
        _text = [cdObject.text copy];
        _tintColor = cdObject.color;
        _schedule = cdObject.schedule;
        
        _optional = [cdObject.optional boolValue];
        OCKDayRange range;
        range.daysBeforeEventDay = cdObject.mutableDaysBeforeEventDay.unsignedIntegerValue;
        range.daysAfterEventDay = cdObject.mutableDaysAfterEventDay.unsignedIntegerValue;
        _eventMutableDayRange =  range;
        _resultResettable = cdObject.resultResettable.boolValue;
        _userInfo = cdObject.userInfo;
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
        OCK_DECODE_OBJ_CLASS(coder, groupIdentifier, NSString);
        OCK_DECODE_OBJ_CLASS(coder, title, NSString);
        OCK_DECODE_OBJ_CLASS(coder, text, NSString);
        OCK_DECODE_OBJ_CLASS(coder, tintColor, UIColor);
        OCK_DECODE_OBJ_CLASS(coder, schedule, OCKCareSchedule);
        OCK_DECODE_ENUM(coder, type);
        OCK_DECODE_BOOL(coder, optional);
        OCKDayRange range;
        range.daysBeforeEventDay = [[coder decodeObjectOfClass:[NSNumber class] forKey:@"daysBeforeEventDay"] unsignedIntegerValue];
        range.daysAfterEventDay = [[coder decodeObjectOfClass:[NSNumber class] forKey:@"daysAfterEventDay"] unsignedIntegerValue];
        _eventMutableDayRange =  range;
        OCK_DECODE_BOOL(coder, resultResettable);
        OCK_DECODE_OBJ_CLASS(coder, userInfo, NSDictionary);
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    OCK_ENCODE_OBJ(coder, identifier);
    OCK_ENCODE_OBJ(coder, groupIdentifier);
    OCK_ENCODE_OBJ(coder, title);
    OCK_ENCODE_OBJ(coder, text);
    OCK_ENCODE_OBJ(coder, tintColor);
    OCK_ENCODE_OBJ(coder, schedule);
    OCK_ENCODE_ENUM(coder, type);
    OCK_ENCODE_BOOL(coder, optional);
    [coder encodeObject:@(_eventMutableDayRange.daysBeforeEventDay) forKey:@"daysBeforeEventDay"];
    [coder encodeObject:@(_eventMutableDayRange.daysAfterEventDay) forKey:@"daysAfterEventDay"];
    OCK_ENCODE_BOOL(coder, resultResettable);
    OCK_ENCODE_OBJ(coder, userInfo);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.text, castObject.text) &&
            OCKEqualObjects(self.tintColor, castObject.tintColor) &&
            OCKEqualObjects(self.schedule, castObject.schedule) &&
            (self.type == castObject.type) &&
            OCKEqualObjects(self.identifier, castObject.identifier) &&
            OCKEqualObjects(self.groupIdentifier, castObject.groupIdentifier) &&
            (self.optional == castObject.optional) &&
            (self.eventMutableDayRange.daysBeforeEventDay == castObject.eventMutableDayRange.daysBeforeEventDay) &&
            (self.eventMutableDayRange.daysAfterEventDay == castObject.eventMutableDayRange.daysAfterEventDay) &&
            (self.resultResettable == castObject.resultResettable) &&
            OCKEqualObjects(self.userInfo, castObject.userInfo)
            );
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCarePlanActivity *item = [[[self class] allocWithZone:zone] init];
    item->_title = [_title copy];
    item->_identifier = [_identifier copy];
    item->_groupIdentifier = [_groupIdentifier copy];
    item->_text = [_text copy];
    item->_tintColor = _tintColor;
    item->_schedule = _schedule;
    item->_type = _type;
    item->_optional = _optional;
    item->_eventMutableDayRange = _eventMutableDayRange;
    item->_resultResettable = _resultResettable;
    item->_userInfo = _userInfo;
    return item;
}

@end


@implementation OCKCDCarePlanActivity

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                          item:(OCKCarePlanActivity *)item {
    
    NSParameterAssert(item);
    self = [self initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self) {
        self.identifier = item.identifier;
        self.groupIdentifier = item.groupIdentifier;
        self.title = item.title;
        self.text = item.text;
        self.color = item.tintColor;
        self.schedule = item.schedule;
        self.type = @(item.type);
        self.optional = @(item.optional);
        self.mutableDaysBeforeEventDay = @(item.eventMutableDayRange.daysBeforeEventDay);
        self.mutableDaysAfterEventDay = @(item.eventMutableDayRange.daysAfterEventDay);
        self.userInfo = item.userInfo;
        self.resultResettable  = @(item.resultResettable);
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"OCKCDCarePlanActivity %@ %@", ((OCKCareSchedule *)self.schedule).endDate, self.schedule];
}

@dynamic mutableDaysBeforeEventDay;
@dynamic mutableDaysAfterEventDay;
@dynamic color;
@dynamic identifier;
@dynamic groupIdentifier;
@dynamic schedule;
@dynamic text;
@dynamic title;
@dynamic type;
@dynamic optional;
@dynamic resultResettable;
@dynamic userInfo;

@end


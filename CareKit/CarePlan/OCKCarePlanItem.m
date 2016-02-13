//
//  OCKCarePlanItem.m
//  CareKit
//
//  Created by Yuan Zhu on 2/1/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKCarePlanItem.h"
#import "OCKCarePlanItem_Internal.h"
#import "OCKHelpers.h"

@implementation OCKCarePlanItem

- (instancetype)initWithType:(NSString *)type
                       title:(NSString *)title
                        text:(NSString *)text
                       color:(UIColor *)color
                    schedule:(OCKCareSchedule *)schedule
                    optional:(BOOL)optional
   onlyMutableDuringEventDay:(BOOL)onlyMutableDuringEventDay{
    
    NSParameterAssert(type);
    NSParameterAssert(schedule);
    
    self = [super init];
    if (self) {
        _identifier = [[NSUUID UUID] UUIDString];
        _type = type;
        _title = [title copy];
        _text = [text copy];
        _color = color;
        _schedule = schedule;
        _optional = optional;
        _onlyMutableDuringEventDay = onlyMutableDuringEventDay;
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
        _onlyMutableDuringEventDay = [cdObject.onlyMutableDuringEventDay boolValue];
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
        OCK_DECODE_BOOL(coder, onlyMutableDuringEventDay);
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
    OCK_ENCODE_BOOL(coder, onlyMutableDuringEventDay);
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
            (self.onlyMutableDuringEventDay == castObject.onlyMutableDuringEventDay)
            );
}

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKCarePlanItem *item = [[[self class] allocWithZone:zone] init];
    item->_title = [_title copy];
    item->_identifier = [_identifier copy];
    item->_text = [_text copy];
    item->_color = _color;
    item->_schedule = _schedule;
    item->_type = _type;
    item->_optional = _optional;
    item->_onlyMutableDuringEventDay = _onlyMutableDuringEventDay;
    return item;
}

@end


@implementation OCKCDCarePlanItem

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                          item:(OCKCarePlanItem *)item {
    
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
        self.onlyMutableDuringEventDay = @(item.onlyMutableDuringEventDay);
    }
    return self;
}

@dynamic onlyMutableDuringEventDay;
@dynamic color;
@dynamic identifier;
@dynamic schedule;
@dynamic text;
@dynamic title;
@dynamic type;
@dynamic optional;

@end


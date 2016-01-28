//
//  OCKPrescription.m
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKTreatment.h"
#import "OCKHelpers.h"

@implementation OCKTreatment

- (instancetype)initWithType:(OCKTreatmentType *)type
                       title:(NSString *)title
                        text:(NSString *)text
                       color:(UIColor *)color
                    schedule:(OCKTreatmentSchedule *)schedule
                    inActive:(BOOL)inActive {
    
    NSParameterAssert(type);
    NSParameterAssert(schedule);
    
    self = [super init];
    if (self) {
        _identifier = [[NSUUID UUID] UUIDString];
        _treatmentType = type;
        _title = [title copy];
        _text = [text copy];
        _color = color;
        _schedule = schedule;
        _inActive = inActive;
    }
    return self;
}

- (instancetype)initWithType:(OCKTreatmentType *)type
                       color:(UIColor *)color
                    schedule:(OCKTreatmentSchedule *)schedule
                    inActive:(BOOL)inActive {
    self = [self initWithType:type
                        title:type.name
                         text:type.text
                        color:color
                     schedule:schedule
                     inActive:inActive];
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
        OCK_DECODE_OBJ_CLASS(coder, schedule, OCKTreatmentSchedule);
        OCK_DECODE_OBJ_CLASS(coder, inActive, NSNumber);
        OCK_DECODE_OBJ_CLASS(coder, treatmentType, OCKTreatmentType);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {

    OCK_ENCODE_OBJ(coder, identifier);
    OCK_ENCODE_OBJ(coder, title);
    OCK_ENCODE_OBJ(coder, text);
    OCK_ENCODE_OBJ(coder, color);
    OCK_ENCODE_OBJ(coder, schedule);
    OCK_ENCODE_BOOL(coder, inActive);
    OCK_ENCODE_OBJ(coder, treatmentType);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.text, castObject.text) &&
            OCKEqualObjects(self.color, castObject.color) &&
            OCKEqualObjects(self.schedule, castObject.schedule) &&
            OCKEqualObjects(self.treatmentType, castObject.treatmentType) &&
            OCKEqualObjects(self.identifier, castObject.identifier) &&
            (self.inActive == castObject.inActive)
            );
}

@end



@implementation OCKTreatmentSchedule

- (instancetype)initWithStartDate:(NSDate *)startDate
                          endDate:(NSDate *)endDate
                         timeZone:(NSTimeZone *)timeZone {
    
    NSParameterAssert(startDate);
    if (endDate) {
        NSAssert(startDate.timeIntervalSince1970 < endDate.timeIntervalSince1970, @"startDate should be earlier than endDate.");
    }
    self = [super init];
    if (self) {
        _startDate = startDate;
        _endDate = endDate;
        _timeZone = timeZone;
    }
    return self;
    
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_CLASS(coder, startDate, NSDate);
        OCK_DECODE_OBJ_CLASS(coder, endDate, NSDate);
        OCK_DECODE_OBJ_CLASS(coder, timeZone, NSTimeZone);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    OCK_ENCODE_OBJ(coder, startDate);
    OCK_ENCODE_OBJ(coder, endDate);
    OCK_ENCODE_OBJ(coder, timeZone);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.startDate, castObject.startDate) &&
            OCKEqualObjects(self.endDate, castObject.endDate) &&
            OCKEqualObjects(self.timeZone, castObject.timeZone)
            );
}

- (NSUInteger)numberOfOccurencesOnDay:(NSDate *)day {
    return ((day.timeIntervalSince1970 >= _startDate.timeIntervalSince1970) && (_endDate == nil || day.timeIntervalSince1970 <= _endDate.timeIntervalSince1970)) ? 3 : 0;
}

@end
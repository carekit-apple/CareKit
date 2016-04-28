/*
 Copyright (c) 2016, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "OCKCarePlanEventResult_Internal.h"
#import "OCKHelpers.h"


@implementation OCKCarePlanEventResult {
    NSString *_valueString;
    NSString *_unitString;
    
    HKSampleType *_sampleType;
    NSUUID *_sampleUUID;
    NSDictionary<NSNumber *, NSString *> *_categoryValueStringKeys;
    NSNumberFormatter *_quantityStringFormatter;
    HKUnit *_displayUnit;
    NSDictionary<HKUnit *, NSString *> *_unitStringKeys;
    HKSample *_sample;
    HKUnit *_preferredUnit;
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithValueString:(NSString *)valueString
                         unitString:(nullable NSString *)unitString
                           userInfo:(nullable NSDictionary *)userInfo {
    OCKThrowInvalidArgumentExceptionIfNil(valueString);
    self = [super init];
    if (self) {
        _valueString = valueString;
        _unitString = unitString;
        _userInfo = userInfo;
        _creationDate = [NSDate date];
    }
    return self;
}

- (instancetype)initWithSample:(HKSample *)sample
       quantityStringFormatter:(nullable NSNumberFormatter *)quantityStringFormatter
                   displayUnit:(nullable HKUnit *)displayUnit
                unitStringKeys:(NSDictionary<HKUnit *, NSString *> *)unitStringKeys
                      userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo {
    NSParameterAssert(sample);
    
    if ([sample isKindOfClass:[HKQuantitySample class]] && displayUnit) {
        if (![((HKQuantitySample *)sample).quantity isCompatibleWithUnit:displayUnit]) {
            NSString *reason = [NSString stringWithFormat:@"Sample is not compatible with unit %@.", displayUnit];
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        }
    }
    
    if ([sample isKindOfClass:[HKWorkout class]] ) {
        NSString *reason = [NSString stringWithFormat:@"HKWorkout is not supported."];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
    
    if ([sample isKindOfClass:[HKCorrelation class]]) {
        HKCorrelation *correlation = (HKCorrelation *)sample;
        
        if (![correlation.correlationType.identifier isEqualToString: HKCorrelationTypeIdentifierBloodPressure]) {
             @throw [NSException exceptionWithName:NSInvalidArgumentException
                                            reason:@"Correlation only support HKCorrelationTypeIdentifierBloodPressure."
                                          userInfo:nil];
        }
        
        HKQuantityType *systolicType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
        HKQuantityType *diastolicType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];
        
        if ([correlation objectsForType:systolicType].count < 1 || [correlation objectsForType:diastolicType].count < 1) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"Blood pressure type correlation should contain both systolic value and diastolic value."
                                         userInfo:nil];
        }
        
        HKQuantitySample *sample = correlation.objects.allObjects.firstObject;
        if (displayUnit && ![sample.quantity isCompatibleWithUnit:displayUnit]) {
            NSString *reason = [NSString stringWithFormat:@"Sample is not compatible with unit %@.", displayUnit];
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        }
    }
    
    if (displayUnit && unitStringKeys[displayUnit] == nil) {
        NSString *reason = [NSString stringWithFormat:@"Need to provide a localized string key for %@ %@", displayUnit, unitStringKeys];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
    
    self = [super init];
    if (self) {
        _quantityStringFormatter = quantityStringFormatter;
        _sampleType = sample.sampleType;
        _sample = sample;
        _sampleUUID = sample.UUID;
        _displayUnit = displayUnit;
        _unitStringKeys = [unitStringKeys copy];
        _userInfo = [userInfo copy];
        _creationDate = [NSDate date];
    }
    return self;
}

- (instancetype)initWithQuantitySample:(HKQuantitySample *)quantitySample
               quantityStringFormatter:(nullable NSNumberFormatter *)quantityStringFormatter
                           displayUnit:(HKUnit *)displayUnit
                  displayUnitStringKey:(NSString *)displayUnitStringKey
                              userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo {
    
    NSParameterAssert(displayUnit);
    NSParameterAssert(displayUnitStringKey);
    
    return [self initWithSample:quantitySample
        quantityStringFormatter:quantityStringFormatter
                    displayUnit:displayUnit
                 unitStringKeys:@{displayUnit: displayUnitStringKey}
                       userInfo:userInfo];
}

- (instancetype)initWithQuantitySample:(HKQuantitySample *)quantitySample
               quantityStringFormatter:(NSNumberFormatter *)quantityStringFormatter
                        unitStringKeys:(NSDictionary<HKUnit *, NSString *> *)unitStringKeys
                              userInfo:(NSDictionary<NSString *, id<NSCoding>> *)userInfo {
    NSParameterAssert(unitStringKeys);
    return [self initWithSample:quantitySample
        quantityStringFormatter:quantityStringFormatter
                    displayUnit:nil
                 unitStringKeys:unitStringKeys
                       userInfo:userInfo];
}

- (instancetype)initWithCorrelation:(HKCorrelation *)correlation
            quantityStringFormatter:(NSNumberFormatter *)quantityStringFormatter
                        displayUnit:(HKUnit *)displayUnit
                     unitStringKeys:(NSDictionary<HKUnit *, NSString *> *)unitStringKeys
                           userInfo:(NSDictionary<NSString *, id<NSCoding>> *)userInfo {
    return [self initWithSample:correlation
        quantityStringFormatter:quantityStringFormatter
                    displayUnit:displayUnit
                 unitStringKeys:unitStringKeys
                       userInfo:userInfo];
}

- (instancetype)initWithCategorySample:(HKCategorySample *)sample
               categoryValueStringKeys:(NSDictionary<NSNumber *, NSString *> *)categoryValueStringKeys
                              userInfo:(nullable NSDictionary<NSString *, id<NSCoding>> *)userInfo {
    
    NSParameterAssert(categoryValueStringKeys);
    
    self = [self initWithSample:sample
        quantityStringFormatter:nil
                    displayUnit:nil
                 unitStringKeys:nil
                       userInfo:userInfo];
    
    _categoryValueStringKeys = [categoryValueStringKeys copy];
    return self;
}

- (HKUnit *)preferredUnit {
    if (!_preferredUnit && _displayUnit) {
        _preferredUnit = _displayUnit;
    }
    
    if (!_preferredUnit &&
        ([_sample isKindOfClass:[HKQuantitySample class]] || [_sample isKindOfClass:[HKCorrelation class]])) {
        HKQuantityType *type = nil;
        if ([_sample isKindOfClass:[HKQuantitySample class]]) {
            HKQuantitySample *sample = (HKQuantitySample *)_sample;
            type = sample.quantityType;
        } else if ([_sample isKindOfClass:[HKCorrelation class]]) {
            HKCorrelation *correlation = (HKCorrelation *)_sample;
            type = ((HKQuantitySample *)correlation.objects.anyObject).quantityType;
        }
        
        HKHealthStore *store = [HKHealthStore new];
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [store preferredUnitsForQuantityTypes:[NSSet setWithObject:type]
                                   completion:^(NSDictionary<HKQuantityType *,HKUnit *> * _Nonnull preferredUnits, NSError * _Nullable error) {
                                       NSAssert(error == nil, error.localizedDescription);
                                       _preferredUnit = preferredUnits[type];
                                       dispatch_semaphore_signal(sem);
                                   }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
    return _preferredUnit;
}

- (NSString *)stringForDoubleValue:(double)value {
    if (_quantityStringFormatter) {
        return [_quantityStringFormatter stringFromNumber:@(value)];
    }
    return [NSNumberFormatter localizedStringFromNumber:@(value) numberStyle:NSNumberFormatterDecimalStyle];
}

- (NSString *)valueString {
    if (_valueString) {
        return _valueString;
    }
    
    NSString * string = @"";
    if (_sample) {
        if ([_sample isKindOfClass:[HKCategorySample class]] ) {
            HKCategorySample *categorySample = (HKCategorySample *)_sample;
            NSInteger value = categorySample.value;
            string = (value >= 0) ? NSLocalizedString(_categoryValueStringKeys[@(value)], @"")  : @"";
        } else if ([_sample isKindOfClass:[HKQuantitySample class]]) {
            HKQuantitySample *sample = (HKQuantitySample *)_sample;
            HKUnit *unit = [self preferredUnit];
            double doubleValue = [sample.quantity doubleValueForUnit:unit];
            string = [self stringForDoubleValue:doubleValue];
        }else if ([_sample isKindOfClass:[HKCorrelation class]]) {
            HKCorrelation *correlation = (HKCorrelation *)_sample;
            HKQuantityType *systolicType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
            HKQuantityType *diastolicType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];
            
            HKQuantitySample *systolicSample = [correlation objectsForType:systolicType].anyObject;
            HKQuantitySample *diastolicSample = [correlation objectsForType:diastolicType].anyObject;
            
            HKUnit *unit = [self preferredUnit];
            double systolicValue = [systolicSample.quantity doubleValueForUnit:unit];
            double diastolicValue = [diastolicSample.quantity doubleValueForUnit:unit];
            string = [NSString stringWithFormat:@"%@ - %@",[self stringForDoubleValue:diastolicValue], [self stringForDoubleValue:systolicValue]];
        }
    }
    return string;
}

- (NSString *)unitString {
    if (_unitString) {
        return NSLocalizedString(_unitString, nil);
    } else if (_sample && [self preferredUnit]) {
        HKUnit *preferredUnit = [self preferredUnit];
        if (_unitStringKeys[preferredUnit]) {
            return NSLocalizedString(_unitStringKeys[preferredUnit], nil);
        } else {
            return NSLocalizedString([preferredUnit unitString], nil);
        }
    }
    
    return nil;
}

- (instancetype)initWithCoreDataObject:(OCKCDCarePlanEventResult *)cdObject {
    NSParameterAssert(cdObject);
    
    if (cdObject.sampleType) {
        self = [super init];
        
        _sampleUUID = cdObject.sampleUUID;
        _sampleType = cdObject.sampleType;
        _displayUnit = cdObject.displayUnit;
        _categoryValueStringKeys = cdObject.categoryValueStringKeys;
        _quantityStringFormatter = cdObject.quantityStringFormatter;
        _unitStringKeys = cdObject.unitStringKeys;
        
        _userInfo = cdObject.userInfo;
    } else {
        self = [self initWithValueString:cdObject.valueString
                              unitString:cdObject.unitString userInfo:cdObject.userInfo];
    }
    
    if (self) {
        _creationDate = cdObject.creationDate;
    }
    return self;
}

- (NSUUID *)sampleUUID {
    return _sampleUUID;
}

- (HKSampleType *)sampleType {
    return _sampleType;
}

- (NSNumberFormatter *)quantityStringFormatter {
    return _quantityStringFormatter;
}

- (NSDictionary<NSNumber *, NSString *> *)categoryValueStringKeys {
    return _categoryValueStringKeys;
}

- (NSDictionary<HKUnit *, NSString *> *)unitStringKeys {
    return _unitStringKeys;
}

- (HKUnit *)displayUnit {
    return _displayUnit;
}

- (HKSample *)sample {
    return _sample;
}

- (void)setSample:(HKSample *)sample {
    _sample = sample;
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.creationDate, castObject.creationDate) &&
            OCKEqualObjects(self.valueString, castObject.valueString) &&
            OCKEqualObjects(self.unitString, castObject.unitString) &&
            OCKEqualObjects(self.sampleType, castObject.sampleType) &&
            OCKEqualObjects(self.sampleUUID, castObject.sampleUUID) &&
            OCKEqualObjects(self.displayUnit, castObject.displayUnit) &&
            OCKEqualObjects(self.unitStringKeys, castObject.unitStringKeys) &&
            OCKEqualObjects(self.quantityStringFormatter, castObject.quantityStringFormatter) &&
            OCKEqualObjects(self.categoryValueStringKeys, castObject.categoryValueStringKeys) &&
            OCKEqualObjects(self.userInfo, castObject.userInfo)
            );
}

@end


@implementation OCKCDCarePlanEventResult

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(nullable NSManagedObjectContext *)context
                        result:(OCKCarePlanEventResult *)result
                         event:(OCKCDCarePlanEvent *)cdEvent {
    NSParameterAssert(result);
    NSParameterAssert(cdEvent);
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self) {
        self.creationDate = result.creationDate;
        self.valueString = result.valueString;
        self.unitString = result.unitString;
        self.userInfo = result.userInfo;
        
        self.sampleType = result.sampleType;
        self.displayUnit = result.displayUnit;
        self.unitStringKeys = result.unitStringKeys;
        self.sampleUUID = result.sampleUUID;
        self.quantityStringFormatter = result.quantityStringFormatter;
        self.categoryValueStringKeys = result.categoryValueStringKeys;
        
        self.event = cdEvent;
    }
    return self;
}

- (void)updateWithResult:(OCKCDCarePlanEventResult *)result {
    self.creationDate = result.creationDate;
    self.valueString = result.valueString;
    self.unitString = result.unitString;
    self.userInfo = result.userInfo;
    
    self.sampleType = result.sampleType;
    self.displayUnit = result.displayUnit;
    self.sampleUUID = result.sampleUUID;
    self.unitStringKeys = result.unitStringKeys;
    self.quantityStringFormatter = result.quantityStringFormatter;
    self.categoryValueStringKeys = result.categoryValueStringKeys;
}

@end


@implementation OCKCDCarePlanEventResult (CoreDataProperties)

@dynamic creationDate;
@dynamic valueString;
@dynamic unitString;
@dynamic userInfo;
@dynamic event;

@dynamic quantityStringFormatter;
@dynamic sampleUUID;
@dynamic sampleType;
@dynamic displayUnit;
@dynamic unitStringKeys;
@dynamic categoryValueStringKeys;

@end

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


#import "OCKCarePlanActivity.h"
#import "OCKCarePlanActivity_Internal.h"
#import "OCKHelpers.h"


@implementation OCKCarePlanActivity

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                   groupIdentifier:(NSString *)groupIdentifier
                              type:(OCKCarePlanActivityType)type
                             title:(NSString *)title
                              text:(NSString *)text
                         tintColor:(UIColor *)tintColor
                      instructions:(NSString *)instructions
                          imageURL:(NSURL *)imageURL
                          schedule:(OCKCareSchedule *)schedule
                  resultResettable:(BOOL)resultResettable
                          userInfo:(NSDictionary *)userInfo {
    
    OCKThrowInvalidArgumentExceptionIfNil(identifier);
    OCKThrowInvalidArgumentExceptionIfNil(schedule);
    
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _groupIdentifier = [groupIdentifier copy];
        _type = type;
        _title = [title copy];
        _text = [text copy];
        _tintColor = tintColor;
        _instructions = [instructions copy];
        _imageURL = imageURL;
        _schedule = schedule;
        _resultResettable = resultResettable;
        _userInfo = [userInfo copy];
    }
    return self;
}

+ (instancetype)assessmentWithIdentifier:(NSString *)identifier
                         groupIdentifier:(NSString *)groupIdentifier
                                   title:(NSString *)title
                                    text:(NSString *)text
                               tintColor:(UIColor *)tintColor
                        resultResettable:(BOOL)resultResettable
                                schedule:(OCKCareSchedule *)schedule
                                userInfo:(NSDictionary *)userInfo {
    
    return [[self alloc] initWithIdentifier:identifier
                            groupIdentifier:groupIdentifier
                                       type:OCKCarePlanActivityTypeAssessment
                                      title:title
                                       text:text
                                  tintColor:tintColor
                               instructions:nil
                                   imageURL:nil
                                   schedule:schedule
                           resultResettable:resultResettable
                                   userInfo:userInfo];
}

+ (instancetype)interventionWithIdentifier:(NSString *)identifier
                           groupIdentifier:(NSString *)groupIdentifier
                                     title:(NSString *)title
                                      text:(NSString *)text
                                 tintColor:(UIColor *)tintColor
                              instructions:(NSString *)instructions
                                  imageURL:(NSURL *)imageURL
                                  schedule:(OCKCareSchedule *)schedule
                                  userInfo:(NSDictionary *)userInfo {
    
    return [[self alloc] initWithIdentifier:identifier
                            groupIdentifier:groupIdentifier
                                       type:OCKCarePlanActivityTypeIntervention
                                      title:title
                                       text:text
                                  tintColor:tintColor
                               instructions:instructions
                                   imageURL:imageURL
                                   schedule:schedule
                           resultResettable:YES
                                   userInfo:userInfo];
}

- (instancetype)initWithCoreDataObject:(OCKCDCarePlanActivity *)cdObject {
    
    NSParameterAssert(cdObject);
    self = [self initWithIdentifier:cdObject.identifier
                    groupIdentifier:cdObject.groupIdentifier
                               type:cdObject.type.integerValue
                              title:cdObject.title
                               text:cdObject.text
                          tintColor:cdObject.color
                       instructions:cdObject.instructions
                           imageURL:OCKURLFromBookmarkData(cdObject.imageURL)
                           schedule:cdObject.schedule
                   resultResettable:cdObject.resultResettable.boolValue
                           userInfo:cdObject.userInfo];
    
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
        OCK_DECODE_OBJ_CLASS(coder, instructions, NSString);
        OCK_DECODE_OBJ_CLASS(coder, tintColor, UIColor);
        OCK_DECODE_OBJ_CLASS(coder, schedule, OCKCareSchedule);
        OCK_DECODE_ENUM(coder, type);
        OCK_DECODE_URL_BOOKMARK(coder, imageURL);
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
    OCK_ENCODE_OBJ(coder, instructions);
    OCK_ENCODE_OBJ(coder, tintColor);
    OCK_ENCODE_OBJ(coder, schedule);
    OCK_ENCODE_ENUM(coder, type);
    OCK_ENCODE_URL_BOOKMARK(coder, imageURL);
    OCK_ENCODE_BOOL(coder, resultResettable);
    OCK_ENCODE_OBJ(coder, userInfo);
}

- (BOOL)isEqual:(id)object {
    BOOL isClassMatch = ([self class] == [object class]);
    
    __typeof(self) castObject = object;
    return (isClassMatch &&
            OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.text, castObject.text) &&
            OCKEqualObjects(self.instructions, castObject.instructions) &&
            OCKEqualObjects(self.tintColor, castObject.tintColor) &&
            OCKEqualObjects(self.schedule, castObject.schedule) &&
            (self.type == castObject.type) &&
            OCKEqualObjects(self.identifier, castObject.identifier) &&
            OCKEqualObjects(self.groupIdentifier, castObject.groupIdentifier) &&
            OCKEqualObjects(self.imageURL, castObject.imageURL) &&
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
    item->_instructions = [_instructions copy];
    item->_tintColor = _tintColor;
    item->_schedule = _schedule;
    item->_type = _type;
    item->_imageURL = _imageURL;
    item->_resultResettable = _resultResettable;
    item->_userInfo = _userInfo;
    return item;
}

@end


@implementation OCKCDCarePlanActivity

- (instancetype)initWithEntity:(NSEntityDescription *)entity
insertIntoManagedObjectContext:(NSManagedObjectContext *)context
                          item:(OCKCarePlanActivity *)item {
    
    NSParameterAssert(item);
    self = [self initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self) {
        self.identifier = item.identifier;
        self.groupIdentifier = item.groupIdentifier;
        self.title = item.title;
        self.text = item.text;
        self.instructions = item.instructions;
        self.color = item.tintColor;
        self.imageURL = OCKBookmarkDataFromURL(item.imageURL);
        self.schedule = item.schedule;
        self.type = @(item.type);
        self.userInfo = item.userInfo;
        self.resultResettable  = @(item.resultResettable);
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"OCKCDCarePlanActivity %@ %@", ((OCKCareSchedule *)self.schedule).endDate, self.schedule];
}

@dynamic color;
@dynamic identifier;
@dynamic groupIdentifier;
@dynamic schedule;
@dynamic text;
@dynamic title;
@dynamic instructions;
@dynamic imageURL;
@dynamic type;
@dynamic resultResettable;
@dynamic userInfo;

@end

//
//  OCKEvaluation.m
//  CareKit
//
//  Created by Umer Khan on 2/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKEvaluation.h"
#import "OCKEvaluation_Internal.h"
#import "OCKHelpers.h"


@implementation OCKEvaluation {
    ORKTaskResult *_result;
}

+ (instancetype)new {
    OCKThrowMethodUnavailableException();
    return nil;
}

+ (instancetype)evaluationWithTitle:(NSString *)title
                               text:(NSString *)text
                               task:(ORKOrderedTask *)task
                           delegate:(id<OCKEvaluationDelegate>)delegate {
    return [[OCKEvaluation alloc] initWithTitle:title
                                           text:text
                                           task:task
                                       delegate:delegate];
}

- (instancetype)init {
    OCKThrowMethodUnavailableException();
    return nil;
}

- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                         task:(ORKOrderedTask *)task
                     delegate:(id<OCKEvaluationDelegate>)delegate {
    self = [super init];
    if (self) {
        _title = [title copy];
        _text = [text copy];
        _task = task;
        _delegate = delegate;
        _value = 0;
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor {
    if (!tintColor ) {
        tintColor = [UIColor darkGrayColor];
    }
    _tintColor = tintColor;
}

- (BOOL)isEqual:(id)object {
    if ([self class] != [object class]) {
        return NO;
    }
    
    __typeof(self) castObject = object;
    return (OCKEqualObjects(self.title, castObject.title) &&
            OCKEqualObjects(self.text, castObject.text) &&
            (self.value == castObject.value) &&
            OCKEqualObjects(self.tintColor, castObject.tintColor));
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        OCK_DECODE_OBJ_CLASS(aDecoder, title, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, text, NSString);
        OCK_DECODE_OBJ_CLASS(aDecoder, task, ORKOrderedTask);
        OCK_DECODE_OBJ(aDecoder, delegate);
        OCK_DECODE_OBJ_CLASS(aDecoder, tintColor, UIColor);
        OCK_DECODE_DOUBLE(aDecoder, value);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    OCK_ENCODE_OBJ(aCoder, title);
    OCK_ENCODE_OBJ(aCoder, text);
    OCK_ENCODE_OBJ(aCoder, task);
    OCK_ENCODE_OBJ(aCoder, delegate);
    OCK_ENCODE_OBJ(aCoder, tintColor);
    OCK_ENCODE_DOUBLE(aCoder, value);
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    OCKEvaluation *evaluation = [[[self class] allocWithZone:zone] init];
    evaluation->_title = [_title copy];
    evaluation->_text = [_text copy];
    evaluation->_task = _task;
    evaluation->_delegate = _delegate;
    evaluation->_tintColor = _tintColor;
    evaluation->_value = _value;
    return evaluation;
}


@end

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


#import <UIKit/UIKit.h>
#import "OCKDefines.h"


NS_ASSUME_NONNULL_BEGIN

/**
 The `OCKBarSeries` class represents a single data set in `OCKBarChart`.
 */
OCK_CLASS_AVAILABLE
@interface OCKBarSeries : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialzed bar series using the specified values.
 
 @param title           The title for the bar series.
 @param values          An array of data values.
 @param valueLabels     An array of strings representing the data values.
 @param tintColor       The bar series tint color.
 
 @return An initialzed bar series object.
 */
- (instancetype)initWithTitle:(NSString *)title
                       values:(NSArray<NSNumber *> *)values
                  valueLabels:(NSArray<NSString *> *)valueLabels
                    tintColor:(nullable UIColor *)tintColor;

/**
 The title of the bar series.
 */
@property (nonatomic, copy, readonly) NSString *title;

/**
 The values of the bar series.
 */
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *values;

/**
 The string representation of the values.
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *valueLabels;

/**
 The tint color of the bar series.
 
 If the value is not specified, the app's tint color is used.
 */
@property (nonatomic, readonly, nullable) UIColor *tintColor;

@end

NS_ASSUME_NONNULL_END

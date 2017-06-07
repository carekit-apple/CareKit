/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import "OCKPatientWidget.h"
#import "OCKPatientWidgetView.h"


NS_ASSUME_NONNULL_BEGIN

@interface OCKPatientWidget()

/**
 An enumeration of the types of patient widgets available.
 */
typedef NS_ENUM(NSUInteger, OCKPatientWidgetType) {
    /**
     A default widget with a title and text.
     */
    OCKPatientWidgetTypeDefault = 0,
    
    /**
     A 2x2 widget with an icon and text stacked.
     */
    OCKPatientWidgetTypeStacked,
    
    /**
     A widget with a title and image.
     */
    OCKPatientWidgetTypeImage,
    
    /**
     A widget with a title and numeric badge.
     */
    OCKPatientWidgetTypeBadge
};

- (instancetype)initWithWidgetType:(OCKPatientWidgetType)type
         primaryActivityIdentifier:(nullable NSString *)primaryIdentifier
       secondaryActivityIdentifier:(nullable NSString *)secondaryIdentifier
                       primaryText:(nullable NSString *)primaryText
                     secondaryText:(nullable NSString *)secondaryText
                      primaryImage:(nullable UIImage *)primaryImage
                    secondaryImage:(nullable UIImage *)secondaryImage
                             value:(nullable NSNumber *)value
                         tintColor:(nullable UIColor *)tintColor;

@property (nonatomic, readonly) OCKPatientWidgetType type;

@property (nonatomic, copy, readonly, nullable) NSString *primaryIdentifier;

@property (nonatomic, copy, readonly, nullable) NSString *secondaryIdentifier;

@property (nonatomic, copy, readonly, nullable) NSString *primaryText;

@property (nonatomic, copy, readonly, nullable) NSString *secondaryText;

@property (nonatomic, readonly, nullable) UIImage *primaryImage;

@property (nonatomic, readonly, nullable) UIImage *secondaryImage;

@property (nonatomic, readonly, nullable) NSNumber *value;

@property (nonatomic, readonly, nullable) UIColor *tintColor;

@end

NS_ASSUME_NONNULL_END

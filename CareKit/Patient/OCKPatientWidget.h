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


#import <CareKit/CareKit.h>


NS_ASSUME_NONNULL_BEGIN

/**
 The `OCKPatientWidget` class is an object that represents a patient widget to be presented on `OCKInsightsViewController`.
 
 Some  patient widgets can be populated using an activity identifier. 
 For these widgets, the content is automatically populated using the activity title and threshold values.
 
 All patient widgets can be manually populated with content also.
 */
OCK_CLASS_AVAILABLE
@interface OCKPatientWidget : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns a default patient widget using the specified activity identifier.
 The widget content is automatically populated with activity title and threshold value.
 
 The tint color is only applied when a threshold has been triggered.
 
 @param activityIdentifier      The widget activity identifier.
 @param tintColor               The widget tint color.
 
 @return An initialized patient widget object.
 */
+ (OCKPatientWidget *)defaultWidgetWithActivityIdentifier:(NSString *)activityIdentifier
                                                tintColor:(nullable UIColor *)tintColor;


/**
 Returns a default patient widget using the specified values.
 A default widget includes a title label and a text label.

 @param title                   The widget title.
 @param text                    The widget text.
 @param tintColor               The widget tint color.
 
 @return An initialized patient widget object.
 */
+ (OCKPatientWidget *)defaultWidgetWithTitle:(NSString *)title
                                        text:(NSString *)text
                                   tintColor:(nullable UIColor *)tintColor;

/**
 Returns a stacked patient widget using the specified values.
 A stacked widget includes a 2x2 grid with an icon and text label stacked.
 
 @param primaryText             The widget primary text.
 @param primaryIcon             The widget primary icon.
 @param secondaryText           The widget seconday text.
 @param secondaryIcon           The widget seconday icon.
 @param tintColor               The widget tint color.
 
 @return An initialized patient widget object.
 */
+ (OCKPatientWidget *)stackedWidgetWithPrimaryText:(NSString *)primaryText
                                       primaryIcon:(UIImage *)primaryIcon
                                     secondaryText:(nullable NSString *)secondaryText
                                     secondaryIcon:(nullable UIImage *)secondaryIcon
                                         tintColor:(nullable UIColor *)tintColor;

/**
 Returns a badge patient widget using the specified values.
 A badge widget includes a title label and a numeric label.
 
 @param title                   The widget title.
 @param value                   The widget numeric value.
 @param tintColor               The widget tint color.
 
 @return An initialized patient widget object.
 */
+ (OCKPatientWidget *)badgeWidgetWithTitle:(NSString *)title
                                     value:(NSNumber *)value
                                 tintColor:(nullable UIColor *)tintColor;

/**
 Returns an image patient widget using the specified values.
 An image widget includes a title label and a text label.
 
 @param title                   The widget title.
 @param image                   The widget image.
 @param tintColor               The widget tint color.
 
 @return An initialized patient widget object.
 */
+ (OCKPatientWidget *)imageWidgetWithTitle:(NSString *)title
                                     image:(UIImage *)image
                                 tintColor:(nullable UIColor *)tintColor;

@end

NS_ASSUME_NONNULL_END

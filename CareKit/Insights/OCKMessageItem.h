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


#import <CareKit/CareKit.h>


NS_ASSUME_NONNULL_BEGIN

/**
 An enumeration of the types of messages available.
 */
typedef NS_ENUM(NSInteger, OCKMessageItemType) {
    /**
     A tip message type.
     */
    OCKMessageItemTypeTip = 0,
    
    /**
     An alert message type.
     */
    OCKMessageItemTypeAlert
};


/**
 The `OCKMessageItem` is an object that can display text such as tips or alerts.
 */
@interface OCKMessageItem : OCKInsightItem

/**
 Returns an initialzed message item using the specified values.
 
 @param title           The title for the message item (see `OCKInsightItem`).
 @param text            The description text for the message item (see `OCKInsightItem`).
 @param tintColor       The tint color for the message item (see `OCKInsightItem`).
 @param messageType     The message item type.
 
 @return An initialzed message item.
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                         text:(nullable NSString *)text
                    tintColor:(nullable UIColor *)tintColor
                  messageType:(OCKMessageItemType)messageType;

/**
 The message item type.
 This determines the icon indicator displayed next to the message title.
 
 See the `OCKMessageItemType` enum.
 */
@property (nonatomic, readonly) OCKMessageItemType messageType;

@end

NS_ASSUME_NONNULL_END

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
#import "OCKDefines.h"


NS_ASSUME_NONNULL_BEGIN

/**
 An enumeration of the types of message items available.
 */
OCK_ENUM_AVAILABLE
typedef NS_ENUM(NSInteger, OCKConnectMessageType) {
    /**
     A recieved message.
     */
    OCKConnectMessageTypeReceived = 0,
    
    /**
     A sent message.
     */
    OCKConnectMessageTypeSent
};


/**
 The `OCKConnectMessageItem` is an object that can be used to display a message in the connect view controller.
 */
OCK_CLASS_AVAILABLE
@interface OCKConnectMessageItem : NSObject <NSSecureCoding, NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialzed message item using the specified values.
 
 @param type            The message type (see `OCKConnectMessageType`).
 @param name            The contact name associated with the message.
 @param message         The content of the message.
 @param dateString      The string representation of the message date.
 
 @return An initialzed connect message item.
 */
- (instancetype)initWithMessageType:(OCKConnectMessageType)type
                               name:(NSString *)name
                            message:(NSString *)message
                         dateString:(NSString *)dateString;

/**
 The message type (see OCKConnectMessageType).
 */
@property (nonatomic, readonly) OCKConnectMessageType type;

/**
 A string indicating the contact name associated with the message.
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 A string indicating the message content.
 */
@property (nonatomic, copy, readonly) NSString *message;

/**
 A string indicating the date for the message.
 */
@property (nonatomic, readonly) NSString *dateString;

@end

NS_ASSUME_NONNULL_END

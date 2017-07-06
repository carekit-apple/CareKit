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
 The `OCKRingItem` is an object that can display a ring representing a value, 
 along with a title and text.
 */
@interface OCKRingItem : OCKInsightItem

/**
 Returns an initialzed ring item using the specified values.
 
 @param title           The title for the message item (see `OCKInsightItem`).
 @param text            The description text for the message item (see `OCKInsightItem`).
 @param tintColor       The tint color for the message item (see `OCKInsightItem`).
 @param value           The value to display in the ring view.
 @param glyphType       The glyph type (see `OCKGlyphType`).
 @param glyphFilename   The glyph filename to be used if using glyph type custom (see `OCKGlyphTypeCustom`).
 
 @return An initialzed ring item.
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                         text:(nullable NSString *)text
                    tintColor:(nullable UIColor *)tintColor
                        value:(double)value
                    glyphType:(OCKGlyphType)glyphType
                glyphFilename:(nullable NSString *)glyphFilename;

/**
 The ring value.
 
 This fills the ring up to the value. Value must be between 0 and 1.
 */
@property (nonatomic, readonly) double value;

/**
 The glpyh type.
 This determines the icon used inside the ring.
 
 See the `OCKGlyphType` enum.
 */
@property (nonatomic, readonly) OCKGlyphType glyphType;


/**
 The glpyh filename.
 
 This filename is only used if the glyph type is custom (see `OCKGlyphTypeCustom`).
 */
@property (nonatomic, copy, readonly) NSString *glyphFilename;


@end

NS_ASSUME_NONNULL_END

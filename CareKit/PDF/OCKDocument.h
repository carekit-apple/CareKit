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

#import <Foundation/Foundation.h>
#import <CareKit/CareKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 OCKDocumentElement defines the protocol to be adopted by all the elements in OCKDocument.
 It requires an element to output to HTML content.
 Developer can create custom element confirming to this protocol to be inlcuded in a document.
 */
@protocol OCKDocumentElement <NSObject>

/**
 Content in HTML format.
 */
@property (nonatomic, copy, readonly) NSString *HTMLContent;

@end

/**
 OCKDocument defines a document object which caontains title, pageHeader, and elements.
 It supports exporting to HTML or PDF file.
 */
@interface OCKDocument : NSObject

/**
 Initializer of OCKDocument.
 
 @param title       Title of the document.
 @param elements    Elements to be included in the document.
 
 @return    Initialized OCKDocument instance.
 */
- (instancetype)initWithTitle:(NSString *)title elements:(NSArray<id<OCKDocumentElement>> *)elements;

/**
 Title of the document; printed in large font at the beginging of the file.
 */
@property (nonatomic, copy, nullable) NSString *title;

/**
 pageHeader will be printed in every PDF page above other content.
 It can be used to help identify the source of a file.
 For example, @"App Name: ABC, User ID: 123456";
 */
@property (nonatomic, copy, nullable) NSString *pageHeader;

/**
 Elements in the document.
 */
@property (nonatomic, copy, nullable) NSArray<id <OCKDocumentElement>> *elements;

/**
 Document content in HTML format.
 */
@property (nonatomic, copy, readonly) NSString *HTMLContent;

/**
 Create a PDF file data based on current document object.
 */
- (void)createPDFDataWithCompletion:(void (^)(NSData *PDFdata, NSError * _Nullable error))completion;

@end


/**
 Defines a subtitle element to be included in document.
 */
@interface OCKDocumentElementSubtitle : NSObject <OCKDocumentElement>

/**
 Initializer of OCKDocumentElementSubtitle.
 
 @param subtitle    Subtitle string.
 @return    Initialized OCKDocumentElementSubtitle instance.
 */
- (instancetype)initWithSubtitle:(NSString *)subtitle;

/**
 Subtitle string.
 */
@property (nonatomic, copy, nullable) NSString *subtitle;

@end


/**
 Defines an text paragraph element to be included in document.
 */
@interface OCKDocumentElementParagraph : NSObject <OCKDocumentElement>

/**
 Initializer of OCKDocumentElementParagraph.
 
 @param     content    Paragraph content string.
 @return    Initialized OCKDocumentElementParagraph instance.
 */
- (instancetype)initWithContent:(NSString *)content;

/**
 Paragraph content string.
 */
@property (nonatomic, copy, nullable) NSString *content;

@end


/**
 Defines an image element to be included in a document.
 */
@interface OCKDocumentElementImage : NSObject <OCKDocumentElement>

/**
 Initializer of OCKDocumentElementImage.
 
 @param     image    Image object.
 @return    Initialized OCKDocumentElementImage instance.
 */
- (instancetype)initWithImage:(UIImage *)image;

/**
 Image object.
 */
@property (nonatomic, strong, nullable) UIImage *image;

@end


/**
 Defines an chart element to be included in a document.
 The title and text of the chart will be included in document as well.
 */
@interface OCKDocumentElementChart : NSObject <OCKDocumentElement>

/**
 Initializer of OCKDocumentElementChart.
 
 @param     chart    OCKChart object.
 @return    Initialized OCKDocumentElementChart instance.
 */
- (instancetype)initWithChart:(OCKChart *)chart;

/**
 OCKChart object.
 */
@property (nonatomic, strong, nullable) OCKChart *chart;

@end

NS_ASSUME_NONNULL_END

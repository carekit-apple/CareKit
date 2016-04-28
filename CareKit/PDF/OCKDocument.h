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
 The OCKDocumentElement class defines the protocol to be adopted by all the elements in an OCKDocument object. 
 You can create custom elements that conform to this protocol to be inlcuded in a document.
 */
@protocol OCKDocumentElement <NSCopying>

/**
 Content in HTML format.
 */
@property (nonatomic, copy, readonly) NSString *HTMLContent;

@end


/**
 The OCKDocument class defines a document object that contains a title, page header, and elements. 
 It supports exporting to an HTML or PDF file.
 */
OCK_CLASS_AVAILABLE
@interface OCKDocument : NSObject <NSCopying>

/**
 Initializer for an OCKDocument object.
 
 @param title       Title of the document.
 @param elements    An array of elements to be included in the document.
 
 @return    An initialized OCKDocument instance.
 */
- (instancetype)initWithTitle:(nullable NSString *)title elements:(nullable NSArray<id<OCKDocumentElement>> *)elements;

/**
 Title of the document; printed in large font at the beginging of the document.
 */
@property (nonatomic, copy, nullable) NSString *title;

/**
 The page header string will be printed in every PDF page above other content. 
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
 Create PDF file using data from the current document object.
 
 @param completion  PDF data creation completion callback.
 */
- (void)createPDFDataWithCompletion:(void (^)(NSData *PDFdata, NSError * _Nullable error))completion;

@end


/**
 Defines a subtitle element to be included in the document.
 */
OCK_CLASS_AVAILABLE
@interface OCKDocumentElementSubtitle : NSObject <OCKDocumentElement>

/**
 Initializer for an OCKDocumentElementSubtitle object.
 
 @param subtitle    Subtitle string.
 @return    An initialized OCKDocumentElementSubtitle instance.
 */
- (instancetype)initWithSubtitle:(NSString *)subtitle;

/**
 Subtitle string.
 */
@property (nonatomic, copy, nullable) NSString *subtitle;

@end


/**
 Defines a text paragraph element to include in the document.
 */
OCK_CLASS_AVAILABLE
@interface OCKDocumentElementParagraph : NSObject <OCKDocumentElement>

/**
 Initializer for an OCKDocumentElementParagraph object.
 
 @param content    Paragraph content string.
 @return    An initialized OCKDocumentElementParagraph instance.
 */
- (instancetype)initWithContent:(NSString *)content;

/**
 Paragraph content string.
 */
@property (nonatomic, copy, nullable) NSString *content;

@end


/**
 Defines an image element to include in the document.
 */
OCK_CLASS_AVAILABLE
@interface OCKDocumentElementImage : NSObject <OCKDocumentElement>

/**
 Initializer for an OCKDocumentElementImage object.
 
 @param image    Image object.
 @return    An initialized OCKDocumentElementImage instance.
 */
- (instancetype)initWithImage:(UIImage *)image;

/**
 Image object.
 */
@property (nonatomic, strong, nullable) UIImage *image;

@end


/**
 Defines a chart element to be included in a document.
 The title and text of the chart will be included in the document.
 */
OCK_CLASS_AVAILABLE
@interface OCKDocumentElementChart : NSObject <OCKDocumentElement>

/**
 Initializer for an OCKDocumentElementChart object.
 
 @param     chart    OCKChart object.
 @return    An initialized OCKDocumentElementChart instance.
 */
- (instancetype)initWithChart:(OCKChart *)chart;

/**
 OCKChart object.
 You can attach an OCKChart subclass object, for example an `OCKBarChart` object.
 */
@property (nonatomic, strong, nullable) OCKChart *chart;

@end


/**
 Defines a table element to include in a document.
 */
OCK_CLASS_AVAILABLE
@interface OCKDocumentElementTable : NSObject <OCKDocumentElement>

/**
 Initializer for an OCKDocumentElementTable object.
 
 @param     headers         An array of table header strings.
 @param     rows            An array of table rows.
                            Each row contains an array of string values.
 @return    An initialized OCKDocumentElementTable instance.
 */
- (instancetype)initWithHeaders:(nullable NSArray<NSString *> *)headers
                           rows:(nullable NSArray<NSArray<NSString *> *> *)rows;

/**
 An array of table header strings.
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *headers;

/**
 An array of table rows.
 Each row contains an array of string values for each table cell in a row.
 */
@property (nonatomic, copy, nullable) NSArray<NSArray<NSString *> *> *rows;

@end

NS_ASSUME_NONNULL_END

//
//  OCKDocument.h
//  CareKit
//
//  Created by Yuan Zhu on 2/23/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CareKit/CareKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
 OCKDocumentElement defines the protocol to be adopted by all the elements in OCKDocument.
 It requires an element to output to HTML content.
 Developer can create custom element confirming to this protocol to be inlcuded in a document.
 */
@protocol OCKDocumentElement <NSObject>

- (NSString *)HTMLContent;

@end

/**
 OCKDocument defines a document object which caontains title, pageHeader, and elements.
 It sopports exporting to HTML or PDF file.
 A document accepts customization via style property.
 */
@interface OCKDocument : NSObject

- (instancetype)initWithTitle:(NSString *)title elements:(NSArray<id<OCKDocumentElement>> *)elements;

/**
 Title of the document.
 */
@property (nonatomic, copy, nullable) NSString *title;

/**
 pageHeader will be printed in every PDF page.
 It can be used to help identify the source of a file.
 For example, @"App Name: ABC, User ID: 123456";
 */
@property (nonatomic, copy, nullable) NSString *pageHeader;

/**
 Included elements.
 */
@property (nonatomic, copy, nullable) NSArray<id <OCKDocumentElement>> *elements;

/**
 */
@property (nonatomic, copy, readonly) NSString *HTMLContent;

/**
 Create PDF from current document object.
 */
- (void)createPDFWithCompletion:(void (^)(NSData *data, NSError *error))completion;

@end

/**
 Defines an element carries a subtitle in document.
 */
@interface OCKDocumentElementSubtitle : NSObject <OCKDocumentElement>

- (instancetype)initWithSubtitle:(NSString *)subtitle;

@property (nonatomic, copy, nullable) NSString *subtitle;

@end


/**
 Defines an element carries a paragraph of text in document.
 */
@interface OCKDocumentElementParagraph : NSObject <OCKDocumentElement>

- (instancetype)initWithContent:(NSString *)content;

@property (nonatomic, copy, nullable) NSString *content;

@end


/**
 Defines an element carries an image object to be included in a document.
 */
@interface OCKDocumentElementImage : NSObject <OCKDocumentElement>

- (instancetype)initWithImage:(UIImage *)image;

@property (nonatomic, strong, nullable) UIImage *image;

@end


/**
 Defines an element carries a chart to be included in a document as image.
 */
@interface OCKDocumentElementChart : NSObject <OCKDocumentElement>

- (instancetype)initWithChart:(OCKChart *)chart;

@property (nonatomic, strong, nullable) OCKChart *chart;

@end



NS_ASSUME_NONNULL_END

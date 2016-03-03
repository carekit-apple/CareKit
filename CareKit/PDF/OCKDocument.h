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

@protocol OCKHTMLElement <NSObject>

- (NSString *)htmlContent;

@end

@interface OCKDocument : NSObject <OCKHTMLElement>

- (instancetype)initWithTitle:(NSString *)title elements:(NSArray<id<OCKHTMLElement>> *)elements;

@property (nonatomic, copy, nullable) NSString *title;

/*
 This will be printed in every PDF page. 
 It can be used to help identify the source of a file.
 For example, @"App Name: ABC, User ID: 123456";
 */
@property (nonatomic, copy, nullable) NSString *pageHeader;

/*
 CSS style sheet to be included in the html's head section.
 For example, @"body { background-color: red; }";
 */
@property (nonatomic, copy, nullable) NSString *internalStyleSheet;

@property (nonatomic, copy, nullable) NSArray<id <OCKHTMLElement>> *elements;

- (void)createPDFWithCompletion:(void (^)(NSData *data, NSError *error))completion;

@end

@interface OCKDocumentElementSubtitle : NSObject <OCKHTMLElement>

- (instancetype)initWithSubtitle:(NSString *)subtitle;

@property (nonatomic, copy, nullable) NSString *subtitle;

@end

@interface OCKDocumentElementParagrah : NSObject <OCKHTMLElement>

- (instancetype)initWithContent:(NSString *)content;

@property (nonatomic, copy, nullable) NSString *content;

@end

/*
 OCKDocumentElementUIView can attach a UIVIew as image to a document.
 */
@interface OCKDocumentElementUIView : NSObject <OCKHTMLElement>

- (instancetype)initWithView:(UIView *)view;

@property (nonatomic, strong, nullable) UIView *view;

@end

@interface OCKDocumentElementChart : NSObject <OCKHTMLElement>

- (instancetype)initWithChart:(OCKChart *)chart;

@property (nonatomic, strong, nullable) OCKChart *chart;

@end



NS_ASSUME_NONNULL_END

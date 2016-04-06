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


#import "DocumentViewController.h"
#import <CareKit/CareKit.h>


@implementation DocumentViewController {
    OCKDocument *_document;
    UIWebView *_webView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Test Document";
    
    _webView = [UIWebView new];
    _webView.frame = self.view.bounds;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_webView];
    
    _document = [self createDocument];
    [_document createPDFDataWithCompletion:^(NSData * _Nonnull PDFdata, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_webView loadData:PDFdata MIMEType:@"application/pdf" textEncodingName:@"" baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", [NSUUID UUID].UUIDString]]];
        });
        
    }];
}

- (OCKChart *)createBarChart {
    OCKBarSeries *barSeries1 = [[OCKBarSeries alloc] initWithTitle:@"Bars 1"
                                                            values:@[@1, @2, @3, @4, @5]
                                                       valueLabels:@[@"1.0", @"2.0", @"3.0", @"4.0", @"5.0"]
                                                         tintColor:[[UIColor blueColor] colorWithAlphaComponent:0.2]];
    
    OCKBarSeries *barSeries2 = [[OCKBarSeries alloc] initWithTitle:@"Bars 2"
                                                            values:@[@5, @4, @3, @2, @1]
                                                       valueLabels:@[@"5.0", @"4.0", @"3.0", @"2.0", @"1.0"]
                                                         tintColor:[[UIColor purpleColor] colorWithAlphaComponent:0.2]];
    
    OCKBarChart *barChart = [[OCKBarChart alloc] initWithTitle:@"Title"
                                                          text:@"Text"
                                                     tintColor:[UIColor whiteColor]
                                                    axisTitles:@[@"Day1", @"Day2", @"Day3", @"Day4", @"Day5"]
                                                 axisSubtitles:@[@"M", @"T", @"W", @"T", @"F"]
                                                    dataSeries:@[barSeries1, barSeries2]];
    
    return barChart;
    
}

- (UIImage *)createImageWithColor:(UIColor *)color {
    CGSize size = CGSizeMake(200, 200);
    UIGraphicsBeginImageContext(size);
    [color setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(10, 10, size.width - 20, size.height - 20) cornerRadius:20] fill];
    UIImage *image =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (OCKDocument *)createDocument {
    OCKDocumentElementSubtitle *subtitle = [[OCKDocumentElementSubtitle alloc] initWithSubtitle:@"First subtitle"];
    OCKDocumentElementParagraph *paragrah = [[OCKDocumentElementParagraph alloc] initWithContent:@"Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque."];
    
    OCKDocumentElementChart *barChart = [[OCKDocumentElementChart alloc] initWithChart:[self createBarChart]];
    OCKDocumentElementImage *imageElement1 = [[OCKDocumentElementImage alloc] initWithImage:[self createImageWithColor:[[UIColor redColor] colorWithAlphaComponent:0.2]]];
    OCKDocumentElementImage *imageElement2 = [[OCKDocumentElementImage alloc] initWithImage:[self createImageWithColor:[[UIColor yellowColor] colorWithAlphaComponent:0.2]]];
    OCKDocumentElementImage *imageElement3 = [[OCKDocumentElementImage alloc] initWithImage:[self createImageWithColor:[[UIColor blueColor] colorWithAlphaComponent:0.2]]];
    
    OCKDocumentElementTable *table = [[OCKDocumentElementTable alloc] init];
    table.headers = @[@"Mon", @"Tue", @"Wed", @"Thu", @"Fri"];
    table.rows = @[@[@"1", @"2", @"3", @"4", @"5"], @[@"2", @"3", @"4", @"5", @"6"], @[@"3", @"4", @"5", @"6", @"7"]];
    
    OCKDocument *doc = [[OCKDocument alloc] initWithTitle:@"This is a title" elements:@[subtitle, table, paragrah, barChart, paragrah, imageElement1, imageElement2, imageElement3, paragrah]];
    doc.pageHeader = @"App Name: ABC, User Name: John Appleseed";
    
    return doc;
}

@end

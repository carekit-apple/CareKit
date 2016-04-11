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


#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>


@interface CareKitPDFTests : XCTestCase

@end


@implementation CareKitPDFTests

- (NSString *)testPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [searchPaths objectAtIndex:0];
    NSString *storePath = [docPath stringByAppendingPathComponent:@"testpdf"];
    [[NSFileManager defaultManager] createDirectoryAtPath:storePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    return storePath;
}

- (NSString *)cleanTestPath {
    NSString *testPath = [self testPath];
    [[NSFileManager defaultManager] removeItemAtPath:testPath error:nil];
    return [self testPath];
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

- (UIImage *)createImage {
    CGSize size = CGSizeMake(200, 200);
    UIGraphicsBeginImageContext(size);
    [[[UIColor grayColor] colorWithAlphaComponent:0.2] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(10, 10, size.width - 20, size.height - 20) cornerRadius:20] fill];
    UIImage *image =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)testHTML {
    OCKDocumentElementSubtitle *subtitle = [[OCKDocumentElementSubtitle alloc] initWithSubtitle:@"First subtitle"];
    OCKDocumentElementParagraph *paragrah = [[OCKDocumentElementParagraph alloc] initWithContent:@"\tLorem ipsum dolor sit amet\n\n, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque."];
    
    OCKDocumentElementChart *barChart = [[OCKDocumentElementChart alloc] initWithChart:[self createBarChart]];
    OCKDocumentElementImage *imageElement = [[OCKDocumentElementImage alloc] initWithImage:[self createImage]];
    
    OCKDocumentElementTable *table = [[OCKDocumentElementTable alloc] init];
    table.headers = @[@"Mon", @"Tue", @"Wed", @"Thu", @"Fri"];
    table.rows = @[@[@"1", @"2", @"3", @"4", @"5"], @[@"2", @"3", @"4", @"5"], @[@"3", @"4", @"5", @"6"]];
    
    OCKDocument *doc = [[OCKDocument alloc] initWithTitle:@"This is a title" elements:@[subtitle, table, paragrah, barChart, paragrah, imageElement, paragrah]];
    doc.pageHeader = @"App Name: ABC, User Name: John Appleseed";
    
    NSString *path = [[self cleanTestPath] stringByAppendingPathComponent:@"x.html"];
    
    [[doc HTMLContent] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    XCTAssertGreaterThan(doc.HTMLContent.length, 0);
    
    NSLog(@"open %@", path);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"pdf"];
    
    [doc createPDFDataWithCompletion:^(NSData * _Nonnull data, NSError * _Nonnull error) {
        NSString *path = [[self testPath] stringByAppendingPathComponent:@"x.pdf"];
        [data writeToFile:path atomically:YES];
        NSLog(@"open %@", path);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
}

@end

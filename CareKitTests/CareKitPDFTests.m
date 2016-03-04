//
//  CareKitPDFTests.m
//  CareKit
//
//  Created by Yuan Zhu on 2/23/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CareKit/CareKit.h>
#import "OCKChartTableViewCell.h"
#import "OCKChart_Internal.h"

@interface CareKitPDFTests : XCTestCase {

}

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
    
    OCKBarGroup *barGroup1 = [[OCKBarGroup alloc] initWithTitle:@"Bars 1"
                                                        values:@[@1, @2, @3, @4, @5]
                                                   valueLabels:@[@"1.0", @"2.0", @"3.0", @"4.0", @"5.0"]
                                                      tintColor:[[UIColor blueColor] colorWithAlphaComponent:0.2]];
    
    OCKBarGroup *barGroup2 = [[OCKBarGroup alloc] initWithTitle:@"Bars 2"
                                                         values:@[@5, @4, @3, @2, @1]
                                                    valueLabels:@[@"5.0", @"4.0", @"3.0", @"2.0", @"1.0"]
                                                      tintColor:[[UIColor purpleColor] colorWithAlphaComponent:0.2]];
    
    OCKBarChart *barChart = [[OCKBarChart alloc] initWithWithTitle:@"Title"
                                                              text:@"Text"
                                                        axisTitles:@[@"Day1", @"Day2", @"Day3", @"Day4", @"Day5"]
                                                     axisSubtitles:@[@"M", @"T", @"W", @"T", @"F"]
                                                            groups:@[barGroup1, barGroup2]];
    
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
    OCKDocumentElementParagraph *paragrah = [[OCKDocumentElementParagraph alloc] initWithContent:@"Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque. Lorem ipsum dolor sit amet, vim primis noster sententiae ne, et albucius apeirian accusata mea, vim at dicunt laoreet. Eu probo omnes inimicus ius, duo at veritus alienum. Nostrud facilisi id pro. Putant oporteat id eos. Admodum antiopam mel in, at per everti quaeque."];
    
    OCKDocumentElementChart *barChart = [[OCKDocumentElementChart alloc] initWithChart:[self createBarChart]];
    OCKDocumentElementImage *imageElement = [[OCKDocumentElementImage alloc] initWithImage:[self createImage]];
    
    OCKDocument *doc = [[OCKDocument alloc] initWithTitle:@"This is a title" elements:@[subtitle, paragrah, barChart, paragrah, imageElement, paragrah]];
    doc.style = @"body {\n"
    "font-family: -apple-system, Helvetica, Arial;\n"
    "}\n";
    doc.pageHeader = @"App Name: ABC, User Name: John Appleseed";
    
    NSString *path = [[self cleanTestPath] stringByAppendingPathComponent:@"x.html"];
    
    [[doc HTMLContent] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"open %@", path);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"pdf"];
    
    [doc createPDFWithCompletion:^(NSData * _Nonnull data, NSError * _Nonnull error) {
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

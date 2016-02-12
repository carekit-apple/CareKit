//
//  OCKLineChart.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChart.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKLine;

@interface OCKLineChart : OCKChart <OCKChartAxisProtocol>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)lineChartWithTitle:(nullable NSString *)title
                              text:(nullable NSString *)text
                             lines:(NSArray <OCKLine *> *)lines;
+ (instancetype)lineChartWithLines:(NSArray <OCKLine *> *)lines;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTitle:(nullable NSString *)title
                         text:(nullable NSString *)text
                        lines:(NSArray <OCKLine *> *)lines;
- (instancetype)initWithLines:(NSArray <OCKLine *> *)lines;

@property (nonatomic, readonly) NSArray <OCKLine *> *lines;

@end

NS_ASSUME_NONNULL_END

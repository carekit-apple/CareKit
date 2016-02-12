//
//  OCKDiscreteChart.h
//  CareKit
//
//  Created by Umer Khan on 1/20/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChart.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKRangeGroup;

@interface OCKDiscreteChart : OCKChart <OCKChartAxisProtocol>

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)discreteChartWithTitle:(nullable NSString *)title
                                  text:(nullable NSString *)text
                                groups:(NSArray <OCKRangeGroup *> *)groups;
+ (instancetype)discreteChartWithGroups:(NSArray <OCKRangeGroup *> *)groups;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTitle:(nullable NSString *)title
                         text:(nullable NSString *)text
                       groups:(NSArray <OCKRangeGroup *> *)groups;
- (instancetype)initWithGroups:(NSArray <OCKRangeGroup *> *)groups;

@property (nonatomic, readonly) NSArray <OCKRangeGroup *> *groups;
@property (nonatomic) BOOL drawsConnectedRanges;

@end

NS_ASSUME_NONNULL_END

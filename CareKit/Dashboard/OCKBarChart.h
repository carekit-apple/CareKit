//
//  OCKBarChart.h
//  CareKit
//
//  Created by Umer Khan on 3/2/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import "OCKChart.h"


NS_ASSUME_NONNULL_BEGIN

@class OCKBarGroup;

@interface OCKBarChart : OCKChart

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)barChartWithTitle:(nullable NSString *)title
                             text:(nullable NSString *)text
                       axisTitles:(nullable NSArray<NSString *> *)axisTitles
                    axisSubtitles:(nullable NSArray<NSString *> *)axisSubtitles
                           groups:(NSArray<OCKBarGroup *> *)groups;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithWithTitle:(nullable NSString *)title
                             text:(nullable NSString *)text
                       axisTitles:(nullable NSArray<NSString *> *)axisTitles
                    axisSubtitles:(nullable NSArray<NSString *> *)axisSubtitles
                           groups:(NSArray<OCKBarGroup *> *)groups;

@property (nonatomic, readonly) NSArray<NSString *> *axisTitles;
@property (nonatomic, readonly) NSArray<NSString *> *axisSubtitles;
@property (nonatomic, readonly) NSArray<OCKBarGroup *> *groups;

@end

NS_ASSUME_NONNULL_END

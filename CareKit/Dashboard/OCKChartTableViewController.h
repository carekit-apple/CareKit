//
//  OCKChartTableViewController.h
//  CareKit
//
//  Created by Umer Khan on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKChart;

@interface OCKChartTableViewController : UITableViewController

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCharts:(NSArray <OCKChart *> *)charts;

@property (nonatomic, copy) NSArray<OCKChart *> *charts;
@property (nonatomic, copy) NSString *headerTitle;
@property (nonatomic, copy) NSString *headerText;

@end

NS_ASSUME_NONNULL_END

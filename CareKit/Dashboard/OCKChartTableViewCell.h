//
//  OCKChartTableViewCell.h
//  CareKit
//
//  Created by Umer Khan on 1/22/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@class OCKChart;

@interface OCKChartTableViewCell : UITableViewCell

@property (nonatomic) OCKChart *chart;

- (void)animateWithDuration:(NSTimeInterval)duration;

@end

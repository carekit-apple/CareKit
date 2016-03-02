//
//  OCKTreatmentWeekView.h
//  CareKit
//
//  Created by Umer Khan on 1/27/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface OCKWeekView : UIView

@property (nonatomic) NSArray<UILabel *> *weekLabels;

- (void)highlightDay:(NSInteger)selectedIndex;

@end

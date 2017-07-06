/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 
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


#import <CareKit/CareKit.h>


NS_ASSUME_NONNULL_BEGIN
@class OCKInsightsViewController, OCKPatientWidget;

/**
 The `OCKInsightsViewController` class is a view controller that displays an array of `OCKInsightItem` objects.
 */
OCK_CLASS_AVAILABLE
@interface OCKInsightsViewController : UIViewController

/**
 Returns an initialzed insights view controller using the specified parameters.
 
 @param items               An array of `OCKInsightItem` objects.
 @param widgets             An array of `OCKPatientWidget` objects.
 @param thresholds          An array of threshold activity identifiers.
 @param store               A care plan store.
 
 @return An initialized insights view controller.
 */
- (instancetype)initWithInsightItems:(nullable NSArray<OCKInsightItem *> *)items
                      patientWidgets:(nullable NSArray<OCKPatientWidget *> *)widgets
                          thresholds:(nullable NSArray<NSString *> *)thresholds
                               store:(nullable OCKCarePlanStore *)store;

/**
 Returns an initialzed insights view controller using the specified items.
 
 @param items           An array of `OCKInsightItem` objects.
 
 @return An initialized insights view controller.
 */
- (instancetype)initWithInsightItems:(nullable NSArray<OCKInsightItem *> *)items;

/**
 An array of insight items.
 */
@property (nonatomic, copy, nullable) NSArray<OCKInsightItem *> *items;

/**
 An array of patient widgets.
 
 Maximum of 3 widgets.
 A care plan store is required for widgets with activity identifiers.
 */
@property (nonatomic, copy, nullable, readonly) NSArray<OCKPatientWidget *> *widgets;

/**
 An array of activity identifiers for threshold evaluations.
 
 A care plan store is required for thresholds.
 */
@property (nonatomic, copy, nullable, readonly) NSArray<NSString *> *thresholds;

/**
 A care plan store is required for threshold and widgets.
 */
@property (nonatomic, copy, nullable, readonly) OCKCarePlanStore *store;

@end

NS_ASSUME_NONNULL_END

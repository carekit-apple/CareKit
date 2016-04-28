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


#import <CareKit/CareKit.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKSymptomTrackerViewController;

/**
 An object that adopts the `OCKSymptomTrackerViewControllerDelegate` protocol is responsible for presenting
 the appropriate view controller to perform the assessment. It also allows the object to modify or update the
 events before they are displayed.
 */
@protocol OCKSymptomTrackerViewControllerDelegate <NSObject>

@required

/**
 Tells the delegate when the user selected an assessment event.
 
 @param viewController      The view controller providing the callback.
 @param assessmentEvent     The assessment event that the user selected.
 */
- (void)symptomTrackerViewController:(OCKSymptomTrackerViewController *)viewController didSelectRowWithAssessmentEvent:(OCKCarePlanEvent *)assessmentEvent;

@optional

/**
 Tells the delegate when a new set of events is fetched from the care plan store.
 
 This is invoked when the date changes or when the care plan store's `carePlanStoreActivityListDidChange` delegate method is called.
 This provides a good opportunity to update the store such as fetching data from HealthKit.
 
 @param viewController      The view controller providing the callback.
 @param events              An array containing the fetched set of assessment events grouped by activity.
 @param dateComponents      The date components for which the events will be displayed.
 */
- (void)symptomTrackerViewController:(OCKSymptomTrackerViewController *)viewController willDisplayEvents:(NSArray<NSArray<OCKCarePlanEvent*>*>*)events dateComponents:(NSDateComponents *)dateComponents;

@end


/**
 The `OCKSymptomTrackerViewController` class is a view controller that displays the activities and events
 from an `OCKCarePlanStore` that are of assessment type (see `OCKCarePlanActivityTypeAssessment`).
 
 It must be embedded inside a `UINavigationController` to allow for calendar operations, such as `Today` bar button item.
 */
OCK_CLASS_AVAILABLE
@interface OCKSymptomTrackerViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized symptom tracker view controller using the specified store.
 
 @param store        A care plan store.
 
 @return An initialized symptom tracker view controller.
 */
- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store;

/**
 The care plan store that provides the content for the symptom tracker.
 
 The symptom tracker displays activites and events that are of assessment type (see `OCKCarePlanActivityTypeAssessment`).
 */
@property (nonatomic, readonly) OCKCarePlanStore *store;

/**
 The delegate is used to provide the appropriate view controller for a given assessment event.
 It also allows the fetched events to be modified or updated before they are displayed.
 
 See the `OCKSymptomTrackerViewControllerDelegate` protocol.
 */
@property (nonatomic, weak, nullable) id<OCKSymptomTrackerViewControllerDelegate> delegate;

/**
 The last assessment event selected by the user.
 
 This value is nil if no assessment has been selected yet.
 */
@property (nonatomic, readonly, nullable) OCKCarePlanEvent *lastSelectedAssessmentEvent;

/**
 The tint color that will be used to fill the ring view.
 
 If the value is not specified, the app's tint color is used.
 */
@property (nonatomic, null_resettable) UIColor *progressRingTintColor;

/**
 A boolean to show the edge indicators.
 
 The default value is NO.
 */
@property (nonatomic) BOOL showEdgeIndicators;

@end

NS_ASSUME_NONNULL_END

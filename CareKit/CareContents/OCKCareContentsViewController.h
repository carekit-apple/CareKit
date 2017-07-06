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

@class OCKCarePlanStore, OCKCareContentsViewController;

/**
 An object that adopts the `OCKCareContentsViewControllerDelegate` protocol can use it to modify or update the events before they are displayed.
 */
@protocol OCKCareContentsViewControllerDelegate <NSObject>

@required

/**
 Tells the delegate when the user selected an assessment event.
 
 @param viewController      The view controller providing the callback.
 @param assessmentEvent     The assessment event that the user selected.
 */
- (void)careContentsViewController:(OCKCareContentsViewController *)viewController didSelectRowWithAssessmentEvent:(OCKCarePlanEvent *)assessmentEvent;

@optional

/**
 Tells the delegate when the user tapped an intervention event.
 
 If the user must perform some activity in order to complete the intervention event,
 then this method can be implemented to show a custom view controller.
 
 If the completion status of the event is dependent on the presented activity, the developer can implement
 the `careContentsViewController:shouldHandleEventCompletionForActivity` to control the completion status of the event.
 
 @param viewController              The view controller providing the callback.
 @param interventionEvent           The intervention event that the user selected.
 */
- (void)careContentsViewController:(OCKCareContentsViewController *)viewController didSelectButtonWithInterventionEvent:(OCKCarePlanEvent *)interventionEvent;

/**
 Tells the delegate when the user selected an intervention activity.
 
 This can be implemented to show a custom detail view controller.
 If not implemented, a default detail view controller will be presented.
 
 @param viewController              The view controller providing the callback.
 @param interventionActivity        The intervention activity that the user selected.
 */
- (void)careContentsViewController:(OCKCareContentsViewController *)viewController didSelectRowWithInterventionActivity:(OCKCarePlanActivity *)interventionActivity;

/**
 Tells the delegate when the user selected a readonly activity.
 
 This can be implemented to show a custom detail view controller.
 If not implemented, a default detail view controller will be presented.
 
 @param viewController              The view controller providing the callback.
 @param readOnlyActivity            The readonly activity that the user selected.
 */
- (void)careContentsViewController:(OCKCareContentsViewController *)viewController didSelectRowWithReadOnlyActivity:(OCKCarePlanActivity *)readOnlyActivity;

/**
 Asks the delegate if care view controller should automatically mark the state of an intervention activity when
 the user selects and deselects the intervention circle button. If this method is not implemented, care view controller
 handles all event completion by default.
 
 If returned NO, the `careContentsViewController:didSelectButtonWithInterventionEvent` method can be implemeted to provide
 custom logic for completion.
 
 @param viewController              The view controller providing the callback.
 @param interventionActivity        The intervention activity that the user selected.
 */
- (BOOL)careContentsViewController:(OCKCareContentsViewController *)viewController shouldHandleEventCompletionForInterventionActivity:(OCKCarePlanActivity *)interventionActivity;

/**
 Tells the delegate when a new set of events is fetched from the care plan store.
 
 This is invoked when the date changes or when the care plan store's `carePlanStoreActivityListDidChange` delegate method is called.
 This provides a good opportunity to update the store such as fetching data from HealthKit.
 
 @param viewController          The view controller providing the callback.
 @param events                  An array containing the fetched set of intervention events grouped by activity.
 @param dateComponents          The date components for which the events will be displayed.
 */
- (void)careContentsViewController:(OCKCareContentsViewController *)viewController willDisplayEvents:(NSArray<NSArray<OCKCarePlanEvent*>*>*)events dateComponents:(NSDateComponents *)dateComponents;

@end


/**
 The `OCKCareContentsViewController` class is a view controller that displays the activities and events from an `OCKCarePlanStore` that are of
 intervention type (see `OCKCarePlanActivityTypeIntervention`), assessment type (see `OCKCarePlanActivityTypeAssessment`), and read only 
 intervention and assessment types (see `OCKCarePlanActivityTypeReadOnly`).
 
 Activities can include a detail view. Therefore, it must be embedded inside a `UINavigationController`.
 */
OCK_CLASS_AVAILABLE
@interface OCKCareContentsViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized care view controller using the specified store.
 
 @param store        A care plan store.
 
 @return An initialized care view controller.
 */
- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store;

/**
 The care plan store that provides the content for the care card.
 
 The care view displays activites and events of type intervention, assessment, intervention read-only, 
 and assessment read-only (see `OCKCarePlanActivityType`).
 */
@property (nonatomic, readonly) OCKCarePlanStore *store;


/**
 The last activity selected by the user.
 
 This value is nil if no activity has been selected yet.
 */
@property (nonatomic, readonly, nullable) OCKCarePlanActivity *lastSelectedActivity;


/**
 The last event selected by the user.
 
 This value is nil if no event has been selected yet.
 */
@property (nonatomic, readonly, nullable) OCKCarePlanEvent *lastSelectedEvent;


/**
 The image that will be used to mask the fill shape in the week view.
 
 In order to provide a custom maskImage, you must have a regular size and small size.
 For example, in the assets catalog, there are "heart" and a "heart-small" assets.
 Both assets must be provided in order to properly render the interface.
 
 The tint color that will be used to fill the shape.
 
 If tint color is not specified, a default red color will be used.
 */
@property (nonatomic, null_resettable) UIColor *glyphTintColor;


/**
 The glyph type for the header view (see OCKGlyphType).
 */
@property (nonatomic) OCKGlyphType glyphType;

/**
 Image name string if using a custom image. Cannot access image name once image has been created
 and we need a way to access that to send the custom image name string to the watch
 */
@property (nonatomic, copy) NSString *customGlyphImageName;


/**
 The delegate can be used to modify or update the internvention events before they are displayed.
 
 See the `OCKCareContentsViewControllerDelegate` protocol.
 */
@property (nonatomic, weak, nullable) id<OCKCareContentsViewControllerDelegate> delegate;

/**
 The section header title for all the Optional activities. Default is `Optional` if nil.
 */
@property (nonatomic, nullable) NSString *optionalSectionHeader;

/**
 The section header title for all the ReadOnly activities. Default is `Read Only` if nil.
 */
@property (nonatomic, nullable) NSString *readOnlySectionHeader;

@end

NS_ASSUME_NONNULL_END

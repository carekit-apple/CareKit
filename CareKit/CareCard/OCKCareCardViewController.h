/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 Copyright (c) 2017, Erik Hornberger. All rights reserved.
 
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

@class OCKCarePlanStore, OCKCareCardViewController;

/**
 An object that adopts the `OCKCareCardViewControllerDelegate` protocol can use it modify or update the events before they are displayed.
 */
@protocol OCKCareCardViewControllerDelegate <NSObject>

@optional

/**
 Asks the delegate if care card view controller should automatically mark the state of an intervention activity when
 the user selects and deselects the intervention circle button. If this method is not implemented, care card view controller
 handles all event completion by default.
 
 If returned NO, the `careCardViewController:didSelectButtonWithInterventionEvent` method can be implemeted to provide
 custom logic for completion.
 
 @param viewController              The view controller providing the callback.
 @param interventionActivity        The intervention activity that the user selected.
 */
- (BOOL)careCardViewController:(OCKCareCardViewController *)viewController shouldHandleEventCompletionForActivity:(OCKCarePlanActivity *)interventionActivity;

/**
 Tells the delegate when the user tapped an intervention event.
 
 If the user must perform some activity in order to complete the intervention event,
 then this method can be implemented to show a custom view controller.
 
 If the completion status of the event is dependent on the presented activity, the developer can implement 
 the `careCardViewController:shouldHandleEventCompletionForActivity` to control the completion status of the event.
 
 @param viewController              The view controller providing the callback.
 @param interventionEvent           The intervention event that the user selected.
 */
- (void)careCardViewController:(OCKCareCardViewController *)viewController didSelectButtonWithInterventionEvent:(OCKCarePlanEvent *)interventionEvent;

/**
 Tells the delegate when the user selected an intervention activity.
 
 This can be implemented to show a custom detail view controller.
 If not implemented, a default detail view controller will be presented.
 
 @param viewController              The view controller providing the callback.
 @param interventionActivity        The intervention activity that the user selected.
 */
- (void)careCardViewController:(OCKCareCardViewController *)viewController didSelectRowWithInterventionActivity:(OCKCarePlanActivity *)interventionActivity;

/**
 Tells the delegate when a new set of events is fetched from the care plan store.
 
 This is invoked when the date changes or when the care plan store's `carePlanStoreActivityListDidChange` delegate method is called.
 This provides a good opportunity to update the store such as fetching data from HealthKit.
 
 @param viewController          The view controller providing the callback.
 @param events                  An array containing the fetched set of intervention events grouped by activity.
 @param dateComponents          The date components for which the events will be displayed.
 */
- (void)careCardViewController:(OCKCareCardViewController *)viewController willDisplayEvents:(NSArray<NSArray<OCKCarePlanEvent*>*>*)events dateComponents:(NSDateComponents *)dateComponents;

/**
 Asks the delegate if the care card view controller should enable pull-to-refresh behavior on the activities list. If not implemented,
 pull-to-refresh will not be enabled.
 
 If returned YES, the `careCardViewController:didActivatePullToRefreshControl:` method should be implemented to provide custom 
 refreshing behavior when triggered by the user.
 
 @param viewController              The view controller providing the callback.
 */
- (BOOL)shouldEnablePullToRefreshInCareCardViewController:(OCKCareCardViewController *)viewController;

/**
 Tells the delegate the user has triggered pull to refresh on the activities list.
 
 Provides the opportunity to refresh data in the local store by, for example, fetching from a cloud data store.
 This method should always be implmented in cases where `shouldEnablePullToRefreshInCareCardViewController:` might return YES.
 
 @param viewController              The view controller providing the callback.
 @param refreshControl              The refresh control which has been triggered, where `isRefreshing` should always be YES.
                                    It is the developers responsibility to call `endRefreshing` as appropriate, on the main thread.
 */
- (void)careCardViewController:(OCKCareCardViewController *)viewController didActivatePullToRefreshControl:(UIRefreshControl *)refreshControl;

@end


/**
 The `OCKCareCardViewController` class is a view controller that displays the activities and events
 from an `OCKCarePlanStore` that are of intervention type (see `OCKCarePlanActivityTypeIntervention`).
 
 It includes a master view and a detail view. Therefore, it must be embedded inside a `UINavigationController`.
 */
OCK_CLASS_AVAILABLE
@interface OCKCareCardViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns an initialized care card view controller using the specified store.
 
 @param store        A care plan store.
 
 @return An initialized care card view controller.
 */
- (instancetype)initWithCarePlanStore:(OCKCarePlanStore *)store;

/**
 The care plan store that provides the content for the care card.
 
 The care card displays activites and events that are of intervention type (see `OCKCarePlanActivityTypeIntervention`).
 */
@property (nonatomic, readonly) OCKCarePlanStore *store;

/**
 The delegate can be used to modify or update the internvention events before they are displayed.
 
 See the `OCKCareCardViewControllerDelegate` protocol.
 */
@property (nonatomic, weak, nullable) id<OCKCareCardViewControllerDelegate> delegate;

/**
 The last intervention activity selected by the user.
 
 This value is nil if no intervention activity has been selected yet.
 */
@property (nonatomic, readonly, nullable) OCKCarePlanActivity *lastSelectedInterventionActivity;

/**
 The last intervention event selected by the user.
 
 This value is nil if no intervention event has been selected yet.
 */
@property (nonatomic, readonly, nullable) OCKCarePlanEvent *lastSelectedInterventionEvent;

/** 
 A reference to the `UITableView` contained in the view controller
 */
@property (nonatomic, readonly, nonnull) UITableView *tableView;

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
 The string that will be used as the Care Card header title.
 
 If the value is not specified, CareKit's default string ("Care Completion") is used.
 */
@property (nonatomic, null_resettable) NSString *headerTitle;

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
 The property that allows activities to be grouped.
 
 If true, the activities will be grouped by groupIdentifier into sections, 
 otherwise the activities will all be in one section and groupIdentifier is ignored.
 
 The default is true.
 */
@property (nonatomic) BOOL isGrouped;

/**
 The property that allows activities to be sorted.
 
 If true, the activities will be sorted alphabetically by title and by groupIdentifier if isGrouped is true,
 otherwise the activities will be sorted in the order they are added in the care plan store.
 
 The default is true.
 */
@property (nonatomic) BOOL isSorted;

@end

NS_ASSUME_NONNULL_END

/*
 Copyright (c) 2017, Apple Inc. All rights reserved.
 Copyright (c) 2017, WWT Asynchrony Labs. All rights reserved.
 Copyright (c) 2017, Erik Hornberger. All rights reserved. 
 Copyright (c) 2017, Troy Tsubota. All rights reserved.

 
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
#import <MessageUI/MessageUI.h>


NS_ASSUME_NONNULL_BEGIN

@class OCKContact, OCKConnectViewController, OCKConnectMessageItem;

/**
 An object that adopts the `OCKConnectViewControllerDataSource` protocol can use it provide connect message to be displayed.
 */
@protocol OCKConnectViewControllerDataSource <NSObject>

@required
/**
 Asks the data source for an array of contacts to be displayed under inbox.
 
 @param viewController          The view controller providing the callback.
 */
- (NSArray<OCKContact *> *)connectViewControllerCareTeamConnections:(OCKConnectViewController *)viewController;

/**
 Asks the data source for a connect message item for a given index.
 
 The message items (connect messages) are displayed in the inbox under connect.
 The `connectViewControllerNumberOfConnectMessageItems:` and `connectViewControllerCareTeamConnections:` implementations are required with this method.
 
 @param viewController          The view controller providing the callback.
 @param index                   The index of the table view row.
 @param contact                 The care team contact.
 */
- (OCKConnectMessageItem *)connectViewController:(OCKConnectViewController *)viewController connectMessageItemAtIndex:(NSInteger)index careTeamContact:(OCKContact *)contact;

/**
 Asks the data source for the number of connect message items.
 
 The message items (connect messages) are displayed in the inbox under connect.
 The `connectViewController:connectMessageItemAtIndex:` implementation is required with this method.
 
 @param viewController          The view controller providing the callback.
 @param contact                 The care team contact.
 */
- (NSInteger)connectViewControllerNumberOfConnectMessageItems:(OCKConnectViewController *)viewController careTeamContact:(OCKContact *)contact;
@end

/**
 An object that adopts the `OCKConnectViewControllerDelegate` protocol is responsible for providing the
 data required to populate the sharing section in the table view of an `OCKConnectViewController` object.
 */
@protocol OCKConnectViewControllerDelegate <NSObject>

@optional
/**
 Tells the delegate when the user selected the share button for a contact.
 
 @param connectViewController       The view controller providing the callback.
 @param contact                     The contact that is currently displayed.
 @param sourceView                  Source view can be used to present a popover on iPad.
 */
- (void)connectViewController:(OCKConnectViewController *)connectViewController didSelectShareButtonForContact:(OCKContact *)contact presentationSourceView:(nullable UIView *)sourceView;

/**
 Asks the delegate for the title to be shown in the sharing cell for a contact.
 If the method returns nil or is not implemented, the localized string for the `SHARING_CELL_TITLE` key is displayed.
 
 Single-lined.
 
 @param connectViewController       The view controller providing the callback.
 @param contact                     The contact that is currently displayed.
 
 @return The string that will be displayed in the sharing cell for the contact.
 */
- (nullable NSString *)connectViewController:(OCKConnectViewController *)connectViewController titleForSharingCellForContact:(OCKContact *)contact;

/**
 Asks the delegate to handle the selection of the contact info. This can be used to provide custom handling for
 contacting the contact. If the method is not implemented or if it returns NO then the default handling will be
 used instead.
 
 @param connectViewController       The view controller providing the callback.
 @param contactInfo                 The contact info that was selected.
 
 @return YES if the contact info selection was handled, or NO if the default handling should be performed instead.
 */
- (BOOL)connectViewController:(OCKConnectViewController *)connectViewController handleContactInfoSelected:(OCKContactInfo *)contactInfo;

/**
 Tells the delegate when the user has sent a connect message.
 
 @param viewController          The view controller providing the callback.
 @param message                 The message that is being sent.
 @param contact                 The care team contact the message is being sent to.
 */
- (void)connectViewController:(OCKConnectViewController *)viewController didSendConnectMessage:(NSString *)message careTeamContact:(OCKContact *)contact;

/**
 Tells the delegate when the user has tapped the profile header.
 
 @param viewController          The view controller providing the callback.
 @param patient                 The patient profile.
 */
- (void)connectViewController:(OCKConnectViewController *)viewController didSelectProfileForPatient:(OCKPatient *)patient;

@end


/**
 The `OCKConnectViewController` class is a view controller that displays an array of `OCKContact` objects.
 It includes a master view and a detail view. Therefore, it must be embedded inside a `UINavigationController`.
 */
OCK_CLASS_AVAILABLE
@interface OCKConnectViewController : UIViewController <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

/**
 Returns an initialized connect view controller using the specified contacts.
 
 @param contacts        An array of `OCKContact` objects.
 @param patient         A patient object.
 
 @return An initialized connect view controller.
 */
- (instancetype)initWithContacts:(nullable NSArray<OCKContact *> *)contacts
                         patient:(nullable OCKPatient *)patient;


/**
 Returns an initialized connect view controller using the specified contacts.
 
 @param contacts        An array of `OCKContact` objects.
 
 @return An initialized connect view controller.
 */
- (instancetype)initWithContacts:(nullable NSArray<OCKContact *> *)contacts;

/**
 An array of contacts.
 */
@property (nonatomic, copy, nullable) NSArray<OCKContact *> *contacts;

/**
 A patient object.
 */
@property (nonatomic, copy, nullable) OCKPatient *patient;

/**
 The data source can be used to provide connect message items.
 
 See the `OCKConnectViewControllerDataSource` protocol.
 */
@property (nonatomic, weak, nullable) id <OCKConnectViewControllerDataSource> dataSource;

/**
 The delegate is used for the sharing section in the contact detail view.
 
 See the `OCKConnectViewControllerDelegate` protocol.
 */
@property (nonatomic, weak, nullable) id<OCKConnectViewControllerDelegate> delegate;

/**
 A reference to the `UITableView` contained in the view controller
 */
@property (nonatomic, readonly, nonnull) UITableView *tableView;

/**
 A boolean to show the edge indicators.
 
 The default value is NO.
 */
@property (nonatomic) BOOL showEdgeIndicators;

@end

NS_ASSUME_NONNULL_END

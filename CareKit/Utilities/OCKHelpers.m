/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
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


#import "OCKHelpers.h"
#import <CareKit/CareKit.h>
#import <CoreText/CoreText.h>


NSString *const OCKErrorDomain = @"OCKErrorDomain";

NSString *const OCKInvalidArgumentException = @"OCKInvalidArgumentException";

NSURL *OCKCreateRandomBaseURL() {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://carekit.%@/", [NSUUID UUID].UUIDString]];
}

NSBundle *OCKAssetsBundle(void) {
    static NSBundle *__bundle;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __bundle = [NSBundle bundleForClass:[OCKConnectViewController class]];
    });
    
    return __bundle;
}

static inline CGFloat OCKCGFloor(CGFloat value) {
    if (sizeof(value) == sizeof(float)) {
        return (CGFloat)floorf((float)value);
    } else {
        return (CGFloat)floor((double)value);
    }
}

static inline CGFloat AdjustToScale(CGFloat (adjustFn)(CGFloat), CGFloat v, CGFloat s) {
    if (s == 0) {
        static CGFloat __s = 1.0;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ __s = [UIScreen mainScreen].scale; });
        s = __s;
    }
    if (s == 1.0) {
        return adjustFn(v);
    } else {
        return adjustFn(v * s) / s;
    }
}

CGFloat OCKFloorToViewScale(CGFloat value, UIView *view) {
    return AdjustToScale(OCKCGFloor, value, view.contentScaleFactor);
}

NSString *OCKStringFromDateISO8601(NSDate *date) {
    static NSDateFormatter *__formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __formatter = [[NSDateFormatter alloc] init];
        [__formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [__formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return [__formatter stringFromDate:date];
}

NSDate *OCKDateFromStringISO8601(NSString *string) {
    static NSDateFormatter *__formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __formatter = [[NSDateFormatter alloc] init];
        [__formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        [__formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return [__formatter dateFromString:string];
}

NSString *OCKSignatureStringFromDate(NSDate *date) {
    static NSDateFormatter *__formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __formatter = [NSDateFormatter new];
        __formatter.dateStyle = NSDateFormatterShortStyle;
        __formatter.timeStyle = NSDateFormatterNoStyle;
    });
    return [__formatter stringFromDate:date];
}

UIColor *OCKRGBA(uint32_t x, CGFloat alpha) {
    CGFloat b = (x & 0xff) / 255.0f; x >>= 8;
    CGFloat g = (x & 0xff) / 255.0f; x >>= 8;
    CGFloat r = (x & 0xff) / 255.0f;
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

UIColor *OCKRGB(uint32_t x) {
    return OCKRGBA(x, 1.0f);
}

UIColor *OCKSystemGrayColor() {
    return [UIColor colorWithRed:142./255. green:142./255. blue:147./255. alpha:1.];
}

UIFontDescriptor *OCKFontDescriptorForLightStylisticAlternative(UIFontDescriptor *descriptor) {
    UIFontDescriptor *fontDescriptor = [descriptor
                                        fontDescriptorByAddingAttributes:
                                        @{ UIFontDescriptorFeatureSettingsAttribute: @[
                                                   @{ UIFontFeatureTypeIdentifierKey: @(kCharacterAlternativesType),
                                                      UIFontFeatureSelectorIdentifierKey: @(1) }]}];
    return fontDescriptor;
}


UIFont *OCKTimeFontForSize(CGFloat size) {
    UIFontDescriptor *fontDescriptor = [OCKLightFontWithSize(size) fontDescriptor];
    fontDescriptor = OCKFontDescriptorForLightStylisticAlternative(fontDescriptor);
    UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:0];
    return font;
}

CGFloat OCKExpectedLabelHeight(UILabel *label) {
    CGSize expectedLabelSize = [label.text boundingRectWithSize:CGSizeMake(label.frame.size.width, CGFLOAT_MAX)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{ NSFontAttributeName : label.font }
                                                        context:nil].size;
    return expectedLabelSize.height;
}

void OCKAdjustHeightForLabel(UILabel *label) {
    CGRect rect = label.frame;
    rect.size.height = OCKExpectedLabelHeight(label);
    label.frame = rect;
}

UIImage *OCKImageWithColor(UIColor *color) {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

void OCKEnableAutoLayoutForViews(NSArray *views) {
    [views enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(UIView *)obj setTranslatesAutoresizingMaskIntoConstraints:NO];
    }];
}

NSDateFormatter *OCKResultDateTimeFormatter() {
    static NSDateFormatter *dateTimeformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateTimeformatter = [[NSDateFormatter alloc] init];
        [dateTimeformatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        dateTimeformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return dateTimeformatter;
}

NSDateFormatter *OCKResultTimeFormatter() {
    static NSDateFormatter *timeformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeformatter = [[NSDateFormatter alloc] init];
        [timeformatter setDateFormat:@"HH:mm"];
        timeformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return timeformatter;
}

NSDateFormatter *OCKResultDateFormatter() {
    static NSDateFormatter *dateformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyy-MM-dd"];
        dateformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return dateformatter;
}

NSDateFormatter *OCKTimeOfDayLabelFormatter() {
    static NSDateFormatter *timeformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeformatter = [[NSDateFormatter alloc] init];
        NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hma" options:0 locale:[NSLocale currentLocale]];
        [timeformatter setDateFormat:dateFormat];
        timeformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return timeformatter;
}

NSNumberFormatter *OCKPercentFormatter(NSInteger maxFractionDigits, NSInteger minFractionDigits) {
    static NSNumberFormatter *_OCKNumberFormatterWithOptions = nil;
    static dispatch_once_t _OCKNumberFormatterWithOptionsOnceToken;
    dispatch_once(&_OCKNumberFormatterWithOptionsOnceToken, ^{
        _OCKNumberFormatterWithOptions = [[NSNumberFormatter alloc] init];
        [_OCKNumberFormatterWithOptions setLocale:[NSLocale currentLocale]];
    });
    
    [_OCKNumberFormatterWithOptions setNumberStyle:NSNumberFormatterPercentStyle];
    [_OCKNumberFormatterWithOptions setMinimumFractionDigits:minFractionDigits];
    [_OCKNumberFormatterWithOptions setMaximumFractionDigits:maxFractionDigits];
    return _OCKNumberFormatterWithOptions;
}

NSBundle *OCKBundle() {
    static NSBundle *__bundle;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __bundle = [NSBundle bundleForClass:[OCKCarePlanStore class]];
    });
    
    return __bundle;
}

NSBundle *OCKDefaultLocaleBundle() {
    static NSBundle *__bundle;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [OCKBundle() pathForResource:[OCKBundle() objectForInfoDictionaryKey:@"CFBundleDevelopmentRegion"] ofType:@"lproj"];
        __bundle = [NSBundle bundleWithPath:path];
    });
    
    return __bundle;
}

NSDateComponentsFormatter *OCKTimeIntervalLabelFormatter() {
    static NSDateComponentsFormatter *durationFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        durationFormatter = [[NSDateComponentsFormatter alloc] init];
        [durationFormatter setUnitsStyle:NSDateComponentsFormatterUnitsStyleFull];
        [durationFormatter setAllowedUnits:NSCalendarUnitHour | NSCalendarUnitMinute];
        [durationFormatter setFormattingContext:NSFormattingContextStandalone];
        [durationFormatter setMaximumUnitCount: 2];
    });
    return durationFormatter;
}

NSDateComponentsFormatter *OCKDurationStringFormatter() {
    static NSDateComponentsFormatter *durationFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        durationFormatter = [[NSDateComponentsFormatter alloc] init];
        [durationFormatter setUnitsStyle:NSDateComponentsFormatterUnitsStyleFull];
        [durationFormatter setAllowedUnits: NSCalendarUnitMinute | NSCalendarUnitSecond];
        [durationFormatter setFormattingContext:NSFormattingContextStandalone];
        [durationFormatter setMaximumUnitCount: 2];
    });
    return durationFormatter;
}

NSCalendar *OCKTimeOfDayReferenceCalendar() {
    static NSCalendar *calendar;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return calendar;
}

NSString *OCKTimeOfDayStringFromComponents(NSDateComponents *dateComponents) {
    static NSDateComponentsFormatter *timeOfDayFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeOfDayFormatter = [[NSDateComponentsFormatter alloc] init];
        [timeOfDayFormatter setUnitsStyle:NSDateComponentsFormatterUnitsStylePositional];
        [timeOfDayFormatter setAllowedUnits:NSCalendarUnitHour | NSCalendarUnitMinute];
        [timeOfDayFormatter setZeroFormattingBehavior:NSDateComponentsFormatterZeroFormattingBehaviorPad];
    });
    return [timeOfDayFormatter stringFromDateComponents:dateComponents];
}

NSDateComponents *OCKTimeOfDayComponentsFromString(NSString *string) {
    // NSDateComponentsFormatter don't support parsing, this is a wOCK around.
    static NSDateFormatter *timeformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeformatter = [[NSDateFormatter alloc] init];
        [timeformatter setDateFormat:@"HH:mm"];
        timeformatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    NSDate *date = [timeformatter dateFromString:string];
    return [OCKTimeOfDayReferenceCalendar() components:(NSCalendarUnitMinute |NSCalendarUnitHour) fromDate:date];
}

NSDateComponents *OCKTimeOfDayComponentsFromDate(NSDate *date) {
    if (date == nil) {
        return nil;
    }
    return [OCKTimeOfDayReferenceCalendar() components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:date];
}

NSDate *OCKTimeOfDayDateFromComponents(NSDateComponents *dateComponents) {
    return [OCKTimeOfDayReferenceCalendar() dateFromComponents:dateComponents];
}

BOOL OCKCurrentLocalePresentsFamilyNameFirst() {
    NSString *language = [[NSLocale preferredLanguages].firstObject substringToIndex:2];
    static dispatch_once_t onceToken;
    static NSArray *familyNameFirstLanguages = nil;
    dispatch_once(&onceToken, ^{
        familyNameFirstLanguages = @[@"zh", @"ko", @"ja", @"vi"];
    });
    return (language != nil) && [familyNameFirstLanguages containsObject:language];
}

BOOL OCKWantsWideContentMargins(UIScreen *screen) {
    
    if (screen != [UIScreen mainScreen]) {
        return NO;
    }
    
    // If our screen's minimum dimension is bigger than a fixed threshold,
    // decide to use wide content margins. This is less restrictive than UIKit,
    // but a good enough approximation.
    CGRect screenRect = screen.bounds;
    CGFloat minDimension = MIN(screenRect.size.width, screenRect.size.height);
    BOOL isWideScreenFormat = (minDimension > 375.);
    
    return isWideScreenFormat;
}

#define OCK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_REGULAR 20.0
#define OCK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT 16.0
#define OCK_LAYOUT_MARGIN_WIDTH_REGULAR_BEZEL 15.0

CGFloat OCKTableViewLeftMargin(UITableView *tableView) {
    if (OCKWantsWideContentMargins(tableView.window.screen)) {
        if (CGRectGetWidth(tableView.frame) > 320.0) {
            return OCK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_REGULAR;
            
        } else {
            return OCK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT;
        }
    } else {
        // Probably should be OCK_LAYOUT_MARGIN_WIDTH_REGULAR_BEZEL
        return OCK_LAYOUT_MARGIN_WIDTH_THIN_BEZEL_COMPACT;
    }
}

UIFont *OCKThinFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightThin];
    } else {
        font = [UIFont fontWithName:@".HelveticaNeueInterface-Thin" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

UIFont *OCKMediumFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    } else {
        font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

UIFont *OCKLightFontWithSize(CGFloat size) {
    UIFont *font = nil;
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 8, .minorVersion = 2, .patchVersion = 0}]) {
        font = [UIFont systemFontOfSize:size weight:UIFontWeightLight];
    } else {
        font = [UIFont fontWithName:@".HelveticaNeueInterface-Light" size:size];
        if (!font) {
            font = [UIFont systemFontOfSize:size];
        }
    }
    return font;
}

NSURL *OCKURLFromBookmarkData(NSData *data) {
    if (data == nil) {
        return nil;
    }
    
    BOOL bookmarkIsStale = NO;
    NSError *bookmarkError = nil;
    NSURL *bookmarkURL = [NSURL URLByResolvingBookmarkData:data
                                                   options:NSURLBookmarkResolutionWithoutUI
                                             relativeToURL:nil
                                       bookmarkDataIsStale:&bookmarkIsStale
                                                     error:&bookmarkError];
    if (!bookmarkURL) {
        OCK_Log_Warning(@"Error loading URL from bookmark: %@", bookmarkError);
    }
    
    return bookmarkURL;
}

NSData *OCKBookmarkDataFromURL(NSURL *url) {
    if (!url) {
        return nil;
    }
    
    NSError *error = nil;
    NSData *bookmark = [url bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                     includingResourceValuesForKeys:nil
                                      relativeToURL:nil
                                              error:&error];
    if (!bookmark) {
        OCK_Log_Warning(@"Error converting URL to bookmark: %@", error);
    }
    return bookmark;
}

NSString *OCKPathRelativeToURL(NSURL *url, NSURL *baseURL) {
    NSURL *standardizedURL = [url URLByStandardizingPath];
    NSURL *standardizedBaseURL = [baseURL URLByStandardizingPath];
    
    NSString *path = [standardizedURL absoluteString];
    NSString *basePath = [standardizedBaseURL absoluteString];
    
    if ([path hasPrefix:basePath]) {
        NSString *relativePath = [path substringFromIndex:basePath.length];
        if ([relativePath hasPrefix:@"/"]) {
            relativePath = [relativePath substringFromIndex:1];
        }
        return relativePath;
    } else {
        return path;
    }
}

static NSURL *OCKHomeDirectoryURL() {
    static NSURL *homeDirectoryURL = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        homeDirectoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
    });
    return homeDirectoryURL;
}

NSURL *OCKURLForRelativePath(NSString *relativePath) {
    if (!relativePath) {
        return nil;
    }
    
    NSURL *homeDirectoryURL = OCKHomeDirectoryURL();
    NSURL *url = [NSURL fileURLWithFileSystemRepresentation:relativePath.fileSystemRepresentation isDirectory:NO relativeToURL:homeDirectoryURL];
    
    if (url != nil) {
        BOOL isDirectory = NO;;
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory];
        if (fileExists && isDirectory) {
            url = [NSURL fileURLWithFileSystemRepresentation:relativePath.fileSystemRepresentation isDirectory:YES relativeToURL:homeDirectoryURL];
        }
    }
    return url;
}
NSString *OCKRelativePathForURL(NSURL *url) {
    if (!url) {
        return nil;
    }
    
    return OCKPathRelativeToURL(url, OCKHomeDirectoryURL());
}

id OCKDynamicCast_(id x, Class objClass) {
    return [x isKindOfClass:objClass] ? x : nil;
}

void OCKValidateArrayForObjectsOfClass(NSArray *array, Class expectedObjectClass, NSString *exceptionReason) {
    NSCParameterAssert(array);
    NSCParameterAssert(expectedObjectClass);
    NSCParameterAssert(exceptionReason);
    
    for (id object in array) {
        if (![object isKindOfClass:expectedObjectClass]) {
            @throw [NSException exceptionWithName:NSGenericException reason:exceptionReason userInfo:nil];
        }
    }
}

void OCKRemoveConstraintsForRemovedViews(NSMutableArray *constraints, NSArray *removedViews) {
    for (NSLayoutConstraint *constraint in [constraints copy]) {
        for (UIView *view in removedViews) {
            if (constraint.firstItem == view || constraint.secondItem == view) {
                [constraints removeObject:constraint];
            }
        }
    }
}

void OCKAdjustPageViewControllerNavigationDirectionForRTL(UIPageViewControllerNavigationDirection *direction) {
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        *direction = (*direction == UIPageViewControllerNavigationDirectionForward) ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward;
    }
}

NSString *OCKPaddingWithNumberOfSpaces(NSUInteger numberOfPaddingSpaces) {
    return [@"" stringByPaddingToLength:numberOfPaddingSpaces withString:@" " startingAtIndex:0];
}


NSString *const __AXStringForVariablesSentinel = @"__AXStringForVariablesSentinel";

NSString *_OCKAccessibilityStringForVariablesWithVariadics(id firstArgument, va_list arguments) {
    Class stringClass = [NSString class];
    NSMutableString *axString = [NSMutableString string];
    
    if (firstArgument != nil) {
        [axString appendString:[firstArgument accessibilityLabel]];
    }
    
    BOOL done = NO;
    while (!done) {
        id nextArgument = va_arg(arguments, id);
        if (nextArgument != nil) {
            done = [nextArgument isKindOfClass:stringClass];
            if (!done) {
                [axString appendString:[NSString stringWithFormat:@", %@", [nextArgument accessibilityLabel]]];
            }
        }
    }
    return axString;
}

NSString *_OCKAccessibilityStringForVariables(id firstArgument, ...) {
    va_list args;
    va_start(args, firstArgument);
    NSString *result = _OCKAccessibilityStringForVariablesWithVariadics(firstArgument, args);
    va_end(args);
    
    return result;
}


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


#import "OCKInsightItem.h"


NS_ASSUME_NONNULL_BEGIN

/**
 The `OCKChart` class provides a model for charts in `OCKInsightsViewController`.
 
 This class cannot be directly initialized.
 In order to use an `OCKChart`, you must use one of the subclassed charts, such as `OCKBarChart`.
 */
OCK_CLASS_AVAILABLE
@interface OCKChart : OCKInsightItem

/**
 Override this method to provide a custom chart view for any subclasses of `OCKChart`.
 */
- (UIView *)chartView;

/**
 Override this method to provide custom animation for any subclasses of `OCKChart`.
 
 This method is called for visible charts only. It is called once and only when `OCKInsightsViewController` appears.
 
 @param view            The chart view.
 @param duration        The animation duration.
 */
+ (void)animateView:(UIView *)view withDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END

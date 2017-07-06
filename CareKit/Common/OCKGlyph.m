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


#import "OCKGlyph.h"
#import "OCKGlyph_Internal.h"
#import "OCKColor.h"


@implementation OCKGlyph


+ (UIImage *)glyphImageForType:(OCKGlyphType)type {
    NSMutableString *glyphName = [NSMutableString stringWithString:[self nameForGlyphType:type]];
    return [UIImage imageNamed:glyphName inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

+ (NSString *)nameForGlyphType:(OCKGlyphType)type {
    NSString *name;
    switch (type) {
        case OCKGlyphTypeHeart:
            name = @"Heart";
            break;
        case OCKGlyphTypeAccessibility:
            name = @"Accessibility";
            break;
        case OCKGlyphTypeActiveLife:
            name = @"ActiveLife";
            break;
        case OCKGlyphTypeAdultLearning:
            name = @"AdultLearning";
            break;
        case OCKGlyphTypeAwareness:
            name = @"Awareness";
            break;
        case OCKGlyphTypeBlood:
            name = @"Blood";
            break;
        case OCKGlyphTypeBloodPressure:
            name = @"BloodPressure";
            break;
        case OCKGlyphTypeCardio:
            name = @"Cardio";
            break;
        case OCKGlyphTypeChildLearning:
            name = @"ChildLearning";
            break;
        case OCKGlyphTypeDentalHealth:
            name = @"DentalHealth";
            break;
        case OCKGlyphTypeFemaleHealth:
            name = @"FemaleHealth";
            break;
        case OCKGlyphTypeHearing:
            name = @"Hearing";
            break;
        case OCKGlyphTypeHomeCare:
            name = @"HomeCare";
            break;
        case OCKGlyphTypeInfantCare:
            name = @"InfantCare";
            break;
        case OCKGlyphTypeLaboratory:
            name = @"Laboratory";
            break;
        case OCKGlyphTypeMaleHealth:
            name = @"MaleHealth";
            break;
        case OCKGlyphTypeMaternalHealth:
            name = @"MaternalHealth";
            break;
        case OCKGlyphTypeMedication:
            name = @"Medication";
            break;
        case OCKGlyphTypeMentalHealth:
            name = @"MentalHealth";
            break;
        case OCKGlyphTypeNeuro:
            name = @"Neuro";
            break;
        case OCKGlyphTypeNutrition:
            name = @"Nutrition";
            break;
        case OCKGlyphTypeOptometry:
            name = @"Optometry";
            break;
        case OCKGlyphTypePediatrics:
            name = @"Pediatrics";
            break;
        case OCKGlyphTypePhysicalTherapy:
            name = @"PhysicalTherapy";
            break;
        case OCKGlyphTypePodiatry:
            name = @"Podiatry";
            break;
        case OCKGlyphTypeRespiratoryHealth:
            name = @"RespiratoryHealth";
            break;
        case OCKGlyphTypeScale:
            name = @"Scale";
            break;
        case OCKGlyphTypeStethoscope:
            name = @"Stethoscope";
            break;
        case OCKGlyphTypeSyringe:
            name = @"Syringe";
            break;
        default:
            break;
    }
    return name;
}

+ (UIColor *)defaultColorForGlyph:(OCKGlyphType)type {
    switch (type) {
        case OCKGlyphTypeHeart:
            return OCKColor.red;
        case OCKGlyphTypeAccessibility:
            return OCKColor.royalBlue;
        case OCKGlyphTypeActiveLife:
            return OCKColor.green;
        case OCKGlyphTypeAdultLearning:
            return OCKColor.red;
        case OCKGlyphTypeAwareness:
            return OCKColor.fuchsia;
        case OCKGlyphTypeBlood:
            return OCKColor.rose;
        case OCKGlyphTypeBloodPressure:
            return OCKColor.peach;
        case OCKGlyphTypeCardio:
            return OCKColor.red;
        case OCKGlyphTypeChildLearning:
            return OCKColor.lightOrange;
        case OCKGlyphTypeDentalHealth:
            return OCKColor.mediumBlue;
        case OCKGlyphTypeFemaleHealth:
            return OCKColor.orange;
        case OCKGlyphTypeHearing:
            return OCKColor.lightBlue;
        case OCKGlyphTypeHomeCare:
            return OCKColor.goldenYellow;
        case OCKGlyphTypeInfantCare:
            return OCKColor.fuchsia;
        case OCKGlyphTypeLaboratory:
            return OCKColor.peach;
        case OCKGlyphTypeMaleHealth:
            return OCKColor.lightOrange;
        case OCKGlyphTypeMaternalHealth:
            return OCKColor.lightPink;
        case OCKGlyphTypeMedication:
            return OCKColor.purple;
        case OCKGlyphTypeMentalHealth:
            return OCKColor.lightBlue;
        case OCKGlyphTypeNeuro:
            return OCKColor.darkPurple;
        case OCKGlyphTypeNutrition:
            return OCKColor.green;
        case OCKGlyphTypeOptometry:
            return OCKColor.brightPurple;
        case OCKGlyphTypePediatrics:
            return OCKColor.brightPurple;
        case OCKGlyphTypePhysicalTherapy:
            return OCKColor.orange;
        case OCKGlyphTypePodiatry:
            return OCKColor.lightBlue;
        case OCKGlyphTypeRespiratoryHealth:
            return OCKColor.peach;
        case OCKGlyphTypeScale:
            return OCKColor.green;
        case OCKGlyphTypeStethoscope:
            return OCKColor.red;
        case OCKGlyphTypeSyringe:
            return OCKColor.goldenYellow;
        default:
            return OCKColor.red;
    }
}

@end

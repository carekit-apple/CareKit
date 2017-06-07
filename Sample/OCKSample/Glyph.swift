//
//  Glyph.swift
//  OCKSample
//
//  Created by Akshay on 10/30/16.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class Glyph: NSObject {
    

    enum glyphType: Int {
        case GlyphTypeHeart = 0
        
        case GlyphTypeAccessibility
        
        case GlyphTypeActiveLife
        
        case GlyphTypeAdultLearning
        
        case GlyphTypeAwareness
        
        case GlyphTypeBlood
        
        case GlyphTypeBloodPressure
        
        case GlyphTypeCardio
        
        case GlyphTypeChildLearning
        
        case GlyphTypeDentalHealth
        
        case GlyphTypeFemaleHealth
        
        case GlyphTypeHearing
        
        case GlyphTypeHomeCare
        
        case GlyphTypeInfantCare
        
        case GlyphTypeLaboratory
        
        case GlyphTypeMaleHealth
        
        case GlyphTypeMaternalHealth
        
        case GlyphTypeMedication
        
        case GlyphTypeMentalHealth
        
        case GlyphTypeNeuro
        
        case GlyphTypeNutrition
        
        case GlyphTypeOptometry
        
        case GlyphTypePediatrics
        
        case GlyphTypePhysicalTherapy
        
        case GlyphTypePodiatry
        
        case GlyphTypeRespiratoryHealth
        
        case GlyphTypeScale
        
        case GlyphTypeStethoscope
        
        case GlyphTypeSyringe
        
        case GlyphTypeCustom

    }
    
    class func imageNameForGlyphType(glyphType: glyphType) -> String {
        
        var imageName = ""
        
        switch glyphType {
            
        case .GlyphTypeHeart :
            imageName = "Heart"
            break
        
        case .GlyphTypeAccessibility :
            imageName = "Accessibility"
            break
            
        case .GlyphTypeActiveLife :
            imageName = "ActiveLife"
            break
            
        case .GlyphTypeAdultLearning :
            imageName = "AdultLearning"
            break
            
        case .GlyphTypeAwareness :
            imageName = "Awareness"
            break
            
        case .GlyphTypeBlood :
            imageName = "Blood"
            break
            
        case .GlyphTypeBloodPressure :
            imageName = "BloodPressure"
            break
            
        case .GlyphTypeCardio :
            imageName = "Cardio"
            break
        
        case .GlyphTypeChildLearning :
            imageName = "ChildLearning"
            break
        
        case .GlyphTypeDentalHealth :
            imageName = "DentalHealth"
            break
        
        case .GlyphTypeFemaleHealth :
            imageName = "FemaleHealth"
            break
        
        case .GlyphTypeHearing :
            imageName = "Hearing"
            break
            
        case .GlyphTypeHomeCare :
            imageName = "HomeCare"
            break
        
        case .GlyphTypeInfantCare :
            imageName = "InfantCare"
            break
        
        case .GlyphTypeLaboratory :
            imageName = "Laboratory"
            break
            
        case .GlyphTypeMaleHealth :
            imageName = "MaleHealth"
            break
        
        case .GlyphTypeMaternalHealth :
            imageName = "MaternalHealth"
            break
        
        case .GlyphTypeMedication :
            imageName = "Medication"
            break
            
        case .GlyphTypeMentalHealth :
            imageName = "MentalHealth"
            break
        
        case .GlyphTypeNeuro :
            imageName = "Neuro"
            break
        
        case .GlyphTypeNutrition :
            imageName = "Nutrition"
            break
        
        case .GlyphTypeOptometry :
            imageName = "Optometry"
            break
        
        case .GlyphTypePediatrics :
            imageName = "Pediatrics"
            break
        
        case .GlyphTypePhysicalTherapy :
            imageName = "PhysicalTherapy"
            break
        
        case .GlyphTypePodiatry :
            imageName = "Podiatry"
            break
        
        case .GlyphTypeRespiratoryHealth :
            imageName = "RespiratoryHealth"
            break
        
        case .GlyphTypeScale :
            imageName = "Scale"
            break
        
        case .GlyphTypeStethoscope :
            imageName = "Stethoscope"
            break
        
        case .GlyphTypeSyringe :
            imageName = "Syringe"
            break
            
        case .GlyphTypeCustom :
            imageName = "Custom"
            break
        }
        
        return imageName
    }
}

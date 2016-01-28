//
//  OCKMedicationTracker.h
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>
#import <CareKit/CareKit.h>


@class OCKTreatmentType;
@class OCKTreatment;

@interface OCKTreatmentPlanManager : NSObject

- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)url;

- (void)addTreatmentTypes:(NSArray<OCKTreatmentType *> *)treatmentTypes;

- (void)addTreatment:(OCKTreatment *)treatment;

@property (nonatomic, copy ,readonly) NSArray<OCKTreatmentType *> *treatmentTypes;

@property (nonatomic, copy ,readonly) NSArray<OCKTreatment *> *treatments;

@end



//
//  OCKMedicationTracker.m
//  CareKit
//
//  Created by Yuan Zhu on 1/21/16.
//  Copyright © 2016 carekit.org. All rights reserved.
//

#import "OCKTreatmentPlanManager.h"
#import <ResearchKit/ResearchKit.h>

static NSString * const TrackerArchiveFileName = @".ock.tracker.data";
static NSString * const TypesKey = @".ock.types";
static NSString * const TreatmentsKey = @".ock.treatments";

@implementation OCKTreatmentPlanManager {
    NSURL *_persistenceDirectoryURL;
    dispatch_queue_t _queue;
    NSMutableArray *_treatments;
    NSMutableArray *_types;
}

- (instancetype)initWithPersistenceDirectoryURL:(NSURL *)url {
    NSParameterAssert(url);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL exist = [fileManager fileExistsAtPath:url.path isDirectory:&isDirectory];
    if (exist == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"persistenceDirectoryURL is not exist." userInfo:nil];
    }
    if (isDirectory == NO) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"persistenceDirectoryURL is not a directory." userInfo:nil];
    }
    
    self = [super init];
    if (self) {
        _persistenceDirectoryURL = url;
        
        NSString *queueId = [@"CareKit.MedicationTracker." stringByAppendingString:[_persistenceDirectoryURL path]];
        _queue = dispatch_queue_create([queueId cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        
        if (!_queue) {
            return nil;
        }
        
        if (NO == [fileManager fileExistsAtPath:[self archiveFilePath]]) {
            [self persistNow];
        } else {
            [self loadFromPersistence];
        }
    }
    return self;
}

- (NSString *)archiveFilePath {
    return [_persistenceDirectoryURL.path stringByAppendingPathComponent:TrackerArchiveFileName];
}

- (void)persistNow {
    
    NSDictionary *trackerStore = @{TypesKey:[self treatmentTypes], TreatmentsKey:[self treatments]};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:trackerStore];
    NSError *error;
    [data writeToFile:[self archiveFilePath] options:NSDataWritingAtomic error:&error];
    if (error) {
        NSString *reason = [NSString stringWithFormat:@"Failed to persist it to persistence file URL: %@, error: %@", [self archiveFilePath], error];
        @throw [NSException exceptionWithName:NSGenericException reason:reason userInfo:@{@"error": error}];
    }
}

- (void)loadFromPersistence {
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:[self archiveFilePath] options:0 error:&error];
    if (error) {
        NSString *reason = [NSString stringWithFormat:@"Failed to read from persistenceDirectoryURL: %@, error: %@", [self archiveFilePath], error];
        @throw [NSException exceptionWithName:NSGenericException reason:reason userInfo:@{@"error": error}];
    }
    
    NSDictionary *store = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (store == nil) {
        NSString *reason = [NSString stringWithFormat:@"Failed to unarchiveObject `_trackerStore`"];
        @throw [NSException exceptionWithName:NSGenericException reason:reason userInfo:nil];
    }
    
    _types = [store[TypesKey] mutableCopy];
    _treatments = [store[TreatmentsKey] mutableCopy];
}

- (void)addTreatmentTypes:(NSArray<OCKTreatmentType *> *)treatmentTypes {
    NSParameterAssert(treatmentTypes);
    if (_types == nil) {
        _types = [NSMutableArray new];
    }
    [_types addObjectsFromArray:treatmentTypes];
    [self persistNow];
}

- (void)addTreatment:(OCKTreatment *)treatment {
    NSParameterAssert(treatment);
    if (_treatments == nil) {
        _treatments = [NSMutableArray new];
    }
    [_treatments addObject:treatment];
    [self persistNow];
}

- (NSArray<OCKTreatmentType *> *)treatmentTypes {
    return _types ? [_types copy] : [NSArray new];
}

- (NSArray<OCKTreatment *> *)treatments {
    return _treatments ? [_treatments copy] : [NSArray new];
}

@end

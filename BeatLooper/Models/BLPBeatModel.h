//
//  BeatModel.h
//  BeatLooper
//
//  Created by Isaak Meier on 4/7/21.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Beat+CoreDataClass.h"
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVComposition.h>
#import <CoreMedia/CMTimeRange.h>

NS_ASSUME_NONNULL_BEGIN

@interface BLPBeatModel : NSObject

// do not use in prod, use regular init instead.
- (id)initWithContainer:(NSPersistentContainer *)container;

- (NSArray *)getAllSongs;
- (NSURL *)getURLForCachedSong:(NSManagedObjectID *)songID;
- (Beat *)getSongForUniqueID:(NSManagedObjectID *)songID;
- (BOOL)saveSongFromURL:(NSURL *)songURL;
- (void)saveSongWith:(NSString *)title url:(NSString *)url;
- (void)deleteSong:(Beat *)song;
- (void)deleteAllEntities;
- (void)saveTempo:(int)tempo forSong:(NSManagedObjectID *)songID;

+ (CMTimeRange)timeRangeFromBars:(int)startBar to:(int)endBar withTempo:(int)tempo;

@end

NS_ASSUME_NONNULL_END

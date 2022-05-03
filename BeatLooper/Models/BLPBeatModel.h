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
#import <AVFoundation/AVPlayerItem.h>
#import <CoreMedia/CMTimeRange.h>

NS_ASSUME_NONNULL_BEGIN

@interface BLPBeatModel : NSObject

// do not use in prod, use regular init instead.
- (id)initWithContainer:(NSPersistentContainer *)container;

- (NSArray *)getAllSongs;
- (NSURL *)getURLForCachedSong:(NSManagedObjectID *)songID;
- (Beat *)getSongFromSongName:(NSString *)songName;
- (Beat *)getSongForUniqueID:(NSManagedObjectID *)songID;
- (BOOL)saveSongFromURL:(NSURL *)songURL;
- (void)saveTempo:(int)tempo forSong:(NSManagedObjectID *)songID;
- (void)deleteSong:(Beat *)song;
- (void)deleteAllEntities;
- (void)updatePathsOfAllEntities;

+ (CMTimeRange)timeRangeFromBars:(int)startBar to:(int)endBar withTempo:(int)tempo;
+ (NSString *)getSongNameFrom:(AVPlayerItem *)playerItem;

@end

NS_ASSUME_NONNULL_END

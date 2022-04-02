//
//  BLPPlayer.h
//  BeatLooper
//
//  Created by Isaak Meier on 1/4/22.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Beat+CoreDataClass.h"
#import <CoreMedia/CMTimeRange.h>
#import <AVFoundation/AVPlayer.h>
@import AVFoundation;
@import AVFAudio.AVAudioSession;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BLPPlayerSongPlaying,
    BLPPlayerSongPaused,
    BLPPlayerLoopPlaying,
    BLPPlayerLoopPaused,
    BLPPlayerEmpty,
} BLPPlayerState;

@protocol BLPPlayerDelegate <NSObject>
- (void)playerDidChangeSongTitle:(NSString *)songTitle;
- (void)playerDidChangeState:(BLPPlayerState)state;
- (void)currentItemDidChangeStatus:(AVPlayerItemStatus)status;
- (void)didUpdateCurrentProgressTo:(double)fractionCompleted;
- (void)requestTableViewUpdate;
- (void)selectedIndexesChanged:(NSUInteger)count;
@end

@interface BLPPlayer : NSObject <UITableViewDelegate, UITableViewDataSource>

// will return nil if songs array is empty
- (instancetype)initWithSongs:(NSArray *)songs;
- (instancetype)initWithDelegate:(nullable id<BLPPlayerDelegate>)delegate andSongs:(NSArray *)songs;

// Methods for player, return success
- (BOOL)togglePlayOrPause;
- (BOOL)skipForward;
- (BOOL)skipBackward;
- (BOOL)startLoopingTimeRange:(CMTimeRange)timeRange;
- (BOOL)stopLooping;
- (BOOL)seekToProgressValue:(float)value;
// Methods for queue
- (BOOL)changeCurrentSongTo:(Beat *)song;
- (BOOL)addSongToQueue:(Beat *)song;
// removes selected songs from the queue
- (void)removeSelectedSongs;

- (NSProgress *)getProgressForCurrentItem;

@property (readonly) BLPPlayerState playerState;
@property (readonly) Beat *currentSong;

@end

NS_ASSUME_NONNULL_END

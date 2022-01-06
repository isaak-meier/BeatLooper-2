//
//  BLPPlayer.h
//  BeatLooper
//
//  Created by Isaak Meier on 1/4/22.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BLPPlayerSongPlaying,
    BLPPlayerSongPaused,
    BLPPlayerLoopPlaying,
    BLPPlayerLoopPaused,
    BLPPlayerEmpty,
} BLPPlayerState;

@interface BLPPlayer : NSObject

// will return nil if songs array is empty
- (instancetype)initWithSongs:(NSArray *)songs;

// returns success
- (BOOL)togglePlayOrPause;
- (BOOL)skipForward;
- (BOOL)skipBackward;
// removes selected songs from the queue
- (void)removeSelectedSongs;

@property BLPPlayerState playerState;

@end

NS_ASSUME_NONNULL_END

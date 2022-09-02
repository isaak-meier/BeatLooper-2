//
//  PlayerViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BLPCoordinator.h"
#import "BLPPlayer.h"
@class BLPCoordinator;

NS_ASSUME_NONNULL_BEGIN

@interface PlayerViewController : UIViewController <BLPPlayerDelegate>

@property (weak) BLPCoordinator *coordinator;

- (id)initWithCoordinator:(BLPCoordinator *)coordinator;
- (void)setup:(BLPPlayer *)playerModel;
- (void)startLoopWithTimeRange:(CMTimeRange)timeRange;
- (void)stopLooping;
- (void)changeCurrentSongTo:(Beat *)newSong;
- (void)addSongToQueue:(Beat *)song;

@end

NS_ASSUME_NONNULL_END

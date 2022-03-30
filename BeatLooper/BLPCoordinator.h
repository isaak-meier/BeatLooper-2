//
//  BLPCoordinator.h
//  BeatLooper
//
//  Created by Isaak Meier on 4/4/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HomeViewController.h"
#import "PlayerViewController.h"
#import "LooperViewController.h"
#import "Models/BLPPlayer.h"
@class AddSongsViewController;

NS_ASSUME_NONNULL_BEGIN

@interface BLPCoordinator : NSObject
- (instancetype)initWithWindow:(UIWindow*)window;
- (void)start; // kickoff application
- (void)songAdded;
- (void)failedToAddSong;
- (void)showAddSongsView;
- (void)openPlayerWithSongs:(NSArray *)songsForQueue;
- (void)addSongToQueue:(Beat *)song;
- (void)playerViewControllerRequestsDeath;
- (void)openLooperViewForSong:(NSManagedObjectID *)songID isLooping:(BOOL)isLooping;
- (void)dismissLooperViewAndBeginLoopingTimeRange:(CMTimeRange)timeRange;
- (void)dismissLooperViewAndStopLoop;
- (void)clearLooperView;

@end

NS_ASSUME_NONNULL_END

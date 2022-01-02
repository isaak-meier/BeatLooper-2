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

NS_ASSUME_NONNULL_BEGIN

@interface BLPCoordinator : NSObject
- (instancetype)initWithWindow:(UIWindow*)window;
- (void)start; // kickoff application
- (void)songAdded;
- (void)openPlayerWithSongs:(NSArray *)songsForQueue;
- (void)openLooperViewForSong:(NSManagedObjectID *)songID;
- (void)dismissLooperViewAndBeginLoopingTimeRange:(CMTimeRange)timeRange;
- (void)dismissLooperViewAndStopLoop;
- (void)clearLooperView;

@end

NS_ASSUME_NONNULL_END

//
//  PlayerViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <AVFoundation/AVPlayer.h>
#import "BLPCoordinator.h"
@class BLPCoordinator;

NS_ASSUME_NONNULL_BEGIN

@interface PlayerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak) BLPCoordinator *coordinator;

- (id)initWithSongs:(NSArray *)songs coordinator:(BLPCoordinator *)coordinator;
- (void)startLoopWithTimeRange:(CMTimeRange)timeRange;
- (void)stopLooping;

@end

NS_ASSUME_NONNULL_END

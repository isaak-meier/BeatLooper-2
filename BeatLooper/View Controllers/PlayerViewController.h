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

@interface PlayerViewController : UIViewController <UITextFieldDelegate>

@property (weak) BLPCoordinator *coordinator;
- (id)initWithSongID:(NSManagedObjectID *)songID coordinator:(BLPCoordinator *)coordinator;

@end

NS_ASSUME_NONNULL_END

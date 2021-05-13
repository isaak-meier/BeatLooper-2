//
//  PlayerViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <AVFoundation/AVAudioPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerViewController : UIViewController

- (id)initWithSongID:(NSManagedObjectID *)songID;

@end

NS_ASSUME_NONNULL_END

//
//  HomeViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import <UIKit/UIKit.h>
#import "BLPBeatModel.h"
#import "BLPCoordinator.h"
#import <AVFoundation/AVAudioPlayer.h>
#import "Beat+CoreDataClass.h"
@class BLPCoordinator;

@interface HomeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property BLPBeatModel *model;
@property (weak) BLPCoordinator *coordinator;

- (id)initWithCoordinator:(BLPCoordinator *)coordinator;
- (void)refreshSongs;

@end


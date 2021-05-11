//
//  ViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import <UIKit/UIKit.h>
#import "BeatModel.h"
#import "Coordinator.h"
#import <AVFoundation/AVAudioPlayer.h>
#import "Beat+CoreDataClass.h"
@class Coordinator;

@interface HomeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property BeatModel *model;
@property (weak) Coordinator *coordinator;

- (void)refreshSongs;

@end


//
//  ViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import <UIKit/UIKit.h>
#import "BeatModel.h"
#import <AVFoundation/AVAudioPlayer.h>

@interface HomeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property BeatModel *model;

- (void)refreshSongs;

@end


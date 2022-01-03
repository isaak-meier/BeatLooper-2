//
//  HomeViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import <UIKit/UIKit.h>
#import "BLPBeatModel.h"
#import "BLPCoordinator.h"
#import "Beat+CoreDataClass.h"
@class BLPCoordinator;

@interface HomeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property BLPBeatModel *model;
@property (weak) BLPCoordinator *coordinator;

- (id)initWithCoordinator:(BLPCoordinator *)coordinator inAddSongsMode:(BOOL)isAddSongsMode;
- (void)refreshSongsAndReloadData:(BOOL)shouldReloadData;

@end


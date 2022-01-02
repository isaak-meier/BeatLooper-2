//
//  BLPCoordinator.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/4/21.
//

#import "BLPCoordinator.h"

@interface BLPCoordinator ()
@property UIWindow *window;
@property UINavigationController *navigationController;
@property PlayerViewController *playerController;
@property LooperViewController *looperController;

// override songID setter so if we change songs we reload the player
@end

@implementation BLPCoordinator


// MARK: Initializer
- (instancetype)initWithWindow:(UIWindow *)window {
    if (self = [super init]) {
        _window = window;
        _navigationController = [[UINavigationController alloc] init];
        [_window setRootViewController:_navigationController];
    }
    return self;
}

// MARK: Methods
- (void)start {
    // Initialize homeViewController from storyboard
    HomeViewController *homeViewController = [[HomeViewController alloc] initWithCoordinator:self];
    [self.navigationController pushViewController:homeViewController animated:NO];
    [[self window] makeKeyAndVisible];
}

- (void)songAdded {
    [self.navigationController popToRootViewControllerAnimated:YES];
    HomeViewController *vc = (HomeViewController *)[_navigationController visibleViewController];
    [vc refreshSongsAndReloadData:YES];
}

- (void)openPlayerWithSongs:(NSArray *)songsForQueue {
    if (!self.playerController) {
        PlayerViewController *playerViewController = [[PlayerViewController alloc]
                                                      initWithSongs:songsForQueue coordinator:self];
        self.playerController = playerViewController;
    } else {
//        if (self.playerController.songID != songID) {
//            NSLog(@"Switching songs.");
//            self.playerController.songID = songID;
//            self.looperController = nil;
//        }
    }
    // TODO change song if different song & controller already exists
    [[self navigationController] pushViewController:self.playerController animated:YES];
}

- (void)openLooperViewForSong:(NSManagedObjectID *)songID {
    if (!self.looperController) {
        LooperViewController *looperController = [[LooperViewController alloc] initWithSongID:songID];
        looperController.modalPresentationStyle = UIModalPresentationPageSheet;
        looperController.coordinator = self;
        self.looperController = looperController; // retain a reference so the user can stop the loop
    }
    [self.navigationController presentViewController:self.looperController animated:YES completion:nil];
}

- (void)dismissLooperViewAndBeginLoopingTimeRange:(CMTimeRange)timeRange {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.playerController startLoopWithTimeRange:timeRange];
}

- (void)dismissLooperViewAndStopLoop {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self.playerController stopLooping];
}

// if the song changes, we need to clear the looper view.
- (void)clearLooperView {
    if (self.looperController) {
        self.looperController = nil;
    }
}

@end

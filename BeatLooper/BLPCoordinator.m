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

- (void)songTapped:(NSManagedObjectID *)songID {
    if (!self.playerController) {
        PlayerViewController *playerViewController = [[PlayerViewController alloc] initWithSongID:songID coordinator:self];
        self.playerController = playerViewController;
    }
    // TODO change song if different song & controller alraedy exists
    [[self navigationController] pushViewController:self.playerController animated:YES];
}

- (void)openLooperViewForSong:(NSManagedObjectID *)songID {
    LooperViewController *looperController = [[LooperViewController alloc] initWithSongID:songID];
    looperController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.navigationController presentViewController:looperController animated:YES completion:nil];
}

@end

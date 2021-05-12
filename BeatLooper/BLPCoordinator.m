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

@end

@implementation BLPCoordinator


// MARK: Initializer
- (instancetype) initWithWindow:(UIWindow *)window {
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
    [vc refreshSongs];
}

- (void)songTapped:(NSManagedObjectID *)songID {
    NSLog(@"%@ was tapped", songID);
}

@end

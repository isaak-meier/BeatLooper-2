//
//  Coordinator.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/4/21.
//

#import "Coordinator.h"

@interface Coordinator ()
@property UIWindow *window;
@property UINavigationController *navigationController;

@end

@implementation Coordinator


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
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    HomeViewController *homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];
    [self.navigationController pushViewController:homeViewController animated:NO];
    homeViewController.coordinator = self;
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

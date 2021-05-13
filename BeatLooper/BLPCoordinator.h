//
//  BLPCoordinator.h
//  BeatLooper
//
//  Created by Isaak Meier on 4/4/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HomeViewController.h"
#import "PlayerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BLPCoordinator : NSObject
- (instancetype)initWithWindow:(UIWindow*)window;
- (void)start; // kickoff application
- (void)songAdded;
- (void)songTapped:(NSManagedObjectID *)songID;

@end

NS_ASSUME_NONNULL_END

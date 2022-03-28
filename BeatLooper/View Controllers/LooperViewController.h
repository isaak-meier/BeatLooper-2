//
//  LooperViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 12/30/21.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "BLPCoordinator.h"

@interface LooperViewController : UIViewController <UITextFieldDelegate>

@property (weak) BLPCoordinator *coordinator;
- (id)initWithSongID:(NSManagedObjectID *)songID isLooping:(BOOL)isLooping;

@end

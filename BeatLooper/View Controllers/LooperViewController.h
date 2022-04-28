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

@property Beat *song;
@property (weak) BLPCoordinator *coordinator;

- (id)initWithSong:(Beat *)song isLooping:(BOOL)isLooping;

@end

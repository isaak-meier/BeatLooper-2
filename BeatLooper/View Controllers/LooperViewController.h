//
//  LooperViewController.h
//  BeatLooper
//
//  Created by Isaak Meier on 12/30/21.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface LooperViewController : UIViewController <UITextFieldDelegate>

- (id)initWithSongID:(NSManagedObjectID *)songID;

@end

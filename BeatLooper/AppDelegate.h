//
//  AppDelegate.h
//  BeatLooper
//
//  Created by Isaak Meier on 4/2/21.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property NSPersistentContainer *container;

- (void)songAdded;

@end


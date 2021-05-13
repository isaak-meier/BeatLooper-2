//
//  BeatModel.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/7/21.
//

#import "BLPBeatModel.h"
#import "Beat+CoreDataClass.h"

@implementation BLPBeatModel

- (NSArray*)getAllSongs {
    AppDelegate *delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.container.viewContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Beat"];
//    [request setResultType:NSDictionaryResultType];
//    [request setPropertiesToFetch:@[@"title", @"uuid"]];
    
    NSError *error = nil;
    NSArray *songs = [context executeFetchRequest:request error:&error];
    if (!songs) {
        NSLog(@"Error fetching Beat objects: %@\n%@", [error localizedDescription], [error userInfo]);
    }

	return songs;
}

- (NSURL *)getURLForCachedSong:(NSManagedObjectID *)songID {
    AppDelegate *delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.container.viewContext;
    Beat *beatFromSongID = [context objectWithID:songID];
    
    NSData *songData = [beatFromSongID data];
    NSError *error;
    NSString *pathString = [NSString stringWithFormat:@"/temp/song.mp3", NSHomeDirectory()];
    [songData writeToFile:pathString options:NSDataWritingAtomic error:&error];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:pathString];
    NSLog(@"%@", pathString);
    return url;
}

@end

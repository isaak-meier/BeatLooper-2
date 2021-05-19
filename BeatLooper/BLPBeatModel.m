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
    
    NSString *songPath = [beatFromSongID fileUrl];
    NSLog(@"Song Path: %@", songPath);
    NSURL *url = [NSURL fileURLWithPath:songPath];

    return url;
}


// Used in development to clear core data
- (void)deleteAllEntities {
    AppDelegate *delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.container.viewContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Beat"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
    
    NSError *deleteError = nil;
    [context executeRequest:delete error:&deleteError];
    if (deleteError) {
        NSLog(@"%@", deleteError);
    }
}

- (BOOL)saveSongFromURL:(NSURL *)songURL {
    return YES;
}

@end

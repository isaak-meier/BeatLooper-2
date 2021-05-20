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
    NSString *urlStr = songURL.absoluteString;
    NSString *fileTitle = [[urlStr lastPathComponent] stringByDeletingPathExtension];
    NSString *fileExtension = [[urlStr lastPathComponent] pathExtension];
    // create path
    NSString *libraryRootPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    // unique id to ensure songs with same name are saved uniquely
    NSString *guid = [[NSUUID new] UUIDString];
    NSString *fileTitleByAppendingUniqueId = [NSString stringWithFormat:@"%@_%@.%@", fileTitle, guid, fileExtension];
    NSString *newFilePath = [libraryRootPath stringByAppendingPathComponent:fileTitleByAppendingUniqueId];
    NSURL *newFileURL = [NSURL fileURLWithPath:newFilePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
  
    BOOL success = [fileManager copyItemAtURL:songURL toURL:newFileURL error:&error];
    if (success) {
        NSLog(@"The file was successfully saved to path %@", newFileURL);
    } else {
        NSLog(@"Error saving file: %@", error);
    }

    [self saveSongWith:fileTitle url:newFileURL.path];
   
    return YES;
}

- (void)saveSongWith:(NSString *)title url:(NSString *)url {
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.container.viewContext;
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Beat" inManagedObjectContext:context];
    NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    [managedObject setValue:title forKey:@"title"];
    [managedObject setValue:url forKey:@"fileUrl"];

    @try {
        [context save:nil];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
}

@end

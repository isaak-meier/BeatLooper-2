//
//  BeatModel.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/7/21.
//

#import "BLPBeatModel.h"
#import "Beat+CoreDataClass.h"

@implementation BLPBeatModel

- (NSArray *)getAllSongs {
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
    Beat *beatFromSongID = [self getSongForUniqueID:songID];
    NSString *songPath = [beatFromSongID fileUrl];
    NSURL *url = [NSURL fileURLWithPath:songPath];
    return url;
}

- (Beat *)getSongForUniqueID:(NSManagedObjectID *)songID {
    AppDelegate *delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.container.viewContext;
    Beat *beatFromSongID = [context objectWithID:songID];
    return beatFromSongID;
}

- (void)deleteSong:(Beat *)song {
    AppDelegate *delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.container.viewContext;
    [context deleteObject:song];
    
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL fileURLWithPath:song.fileUrl];
    [fileManager removeItemAtURL:url error:&error];
    [context save:&error];
    
    if (error) {
        NSLog(@"There some error deleting: %@", error);
    }
}

// Used in development to clear core data. 
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
    NSURL *newFileURL = [BLPBeatModel uniqueURLFromExistingSongURL:songURL withCafExtension:NO];
    NSString *urlStr = songURL.absoluteString;
    NSString *fileTitle = [[urlStr lastPathComponent] stringByDeletingPathExtension];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
  
    BOOL success = [fileManager copyItemAtURL:songURL toURL:newFileURL error:&error];
    if (success) {
        NSLog(@"The file was successfully saved to path %@", newFileURL);
        [self saveSongWith:fileTitle url:newFileURL.path];
    } else {
        NSLog(@"Error saving file: %@", error);
        return NO;
    }
   
    return YES;
}

- (void)saveSongWith:(NSString *)title url:(NSString *)url {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
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

- (void)saveTempo:(int)tempo forSong:(NSManagedObjectID *)songID {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.container.viewContext;
    
    Beat *beatFromSongID = [context objectWithID:songID];
    beatFromSongID.tempo = tempo;
    
    NSError *error;
    [context save:&error];
    if (error) {
        NSLog(@"There was some error updating: %@", error);
    } else {
        NSLog(@"Saved beat with id %@ named %@ with tempo %d", beatFromSongID.objectID, beatFromSongID.title, beatFromSongID.tempo);
    }
}

// Pass 0.25 for quarter note, 1 for bar, 4 for phrase.
+ (double)secondsFromTempo:(int)tempo withBars:(int)duration {
    return 1.0 / (double)tempo * 60.0 * 4.0 * duration;
}

// time range for loop export cut
+ (CMTimeRange)timeRangeFromBars:(int)startBar to:(int)endBar withTempo:(int)tempo {
    if (startBar < 0) { // can't have negative time range
        startBar = 0;
    }
    NSTimeInterval timeToStartCut = [self secondsFromTempo:tempo withBars:startBar];
    CMTime cmStartTime = CMTimeMakeWithSeconds(timeToStartCut, 1000000);
    int durationBars = endBar - startBar;
    if (durationBars < 0) {
        durationBars = 0;
    }
    NSTimeInterval durationOfCut = [self secondsFromTempo:tempo withBars:durationBars];
    CMTime cmDuration = CMTimeMakeWithSeconds(durationOfCut, 1000000);
    if (CMTIME_IS_INVALID(cmStartTime) || CMTIME_IS_INVALID(cmDuration)) {
        NSLog(@"Start time or duration is invalid");
        NSLog(@"Time range: %f full time %f", CMTimeGetSeconds(cmStartTime), CMTimeGetSeconds(cmDuration));
    }
    
    return CMTimeRangeMake(cmStartTime, cmDuration);
}


+ (NSURL *)uniqueURLFromExistingSongURL:(NSURL *)currentURL withCafExtension:(BOOL)shouldUseCafExtension {
    NSString *urlStr = currentURL.absoluteString;
    NSString *fileTitle = [[urlStr lastPathComponent] stringByDeletingPathExtension];
    NSString *fileExtension;
    if (shouldUseCafExtension) {
        fileExtension = @"caf";
    } else {
        fileExtension = [[urlStr lastPathComponent] pathExtension];
    }
    // create path
    NSString *libraryRootPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    // unique id to ensure songs with same name are saved uniquely
    NSString *guid = [[NSUUID new] UUIDString];
    NSString *fileTitleByAppendingUniqueId = [NSString stringWithFormat:@"%@_%@.%@", fileTitle, guid, fileExtension];
    NSString *newFilePath = [libraryRootPath stringByAppendingPathComponent:fileTitleByAppendingUniqueId];
    return [NSURL fileURLWithPath:newFilePath];
}

@end

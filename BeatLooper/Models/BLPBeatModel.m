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

// TODO: for both delete methods, delete file stored at path before removing object from core data
- (void)deleteSong:(NSManagedObject *)song {
    AppDelegate *delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.container.viewContext;
    [context deleteObject:song];
    
    NSError *error;
    [context save:&error];
    if (error) {
        NSLog(@"There somme error deleting: %@", error);
    }
}

// Used in development to clear core data. would be nice to have a button for this.
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
        [self saveSongWith:fileTitle url:newFileURL.path];
    } else {
        NSLog(@"Error saving file: %@", error);
    }

   
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

// Pass 0.25 for quarter note, 1 for bar, 4 for phrase.
+ (double)secondsFromTempo:(int)tempo withBars:(double)duration {
    return 1.0 / (double)tempo * 60.0 * 4.0 * duration;
}


+ (NSURL *)exportClippedAudioFromBeat:(Beat *)beat withTempo:(int)tempo startingAtTimeInBars:(int)startTime forTimeInBars:(int)duration {
    NSURL *fullSongURL = [NSURL fileURLWithPath:beat.fileUrl];
    AVAsset *asset = [AVAsset assetWithURL:fullSongURL];
    
    NSTimeInterval timeToStartCut = [self secondsFromTempo:tempo withBars:startTime];
    CMTime cmStartTime = CMTimeMakeWithSeconds(timeToStartCut, 1000000);
    NSTimeInterval durationOfCut = [self secondsFromTempo:tempo withBars:duration];
    CMTime cmDuration = CMTimeMakeWithSeconds(durationOfCut, 1000000);
    CMTimeRange timeRangeOfExport = CMTimeRangeMake(cmStartTime, cmDuration);
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    if (nil == exportSession) return nil;
    
    NSURL *exportedFileURL; // TODO: create directory for loops & urls for loops
    [exportSession setOutputURL:exportedFileURL];
    [exportSession setTimeRange:timeRangeOfExport];
    [exportSession setOutputFileType:AVAssetExportPresetAppleM4A];
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"Successfully exported audio to %@", exportedFileURL.absoluteString);
        } else if (exportSession.status == AVAssetExportSessionStatusFailed) {
            // TODO: handle this appropriately
            NSLog(@"Filed to export audio to %@", exportedFileURL.absoluteString);
        } else {
            NSLog(@"Status: %@", exportSession.status);
        }
    }];
    
    // this might not finish before we return, handle this
    return fullSongURL;
}

@end

//
//  BeatModel.m
//  BeatLooper
//
//  Created by Isaak Meier on 4/7/21.
//

#import "BLPBeatModel.h"
#import "Beat+CoreDataClass.h"

@interface BLPBeatModel ()
@property NSPersistentContainer *container;

@end

@implementation BLPBeatModel


// Init with dependency
- (id)initWithContainer:(NSPersistentContainer *)container {
    if (self = [super init]) {
        self.container = container;
        [self.container.viewContext setAutomaticallyMergesChangesFromParent:YES];
    }
    return self;
}

// convenience init
- (id)init {
    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSPersistentContainer *container = delegate.container;
    return [self initWithContainer:container];
}

- (NSArray *)getAllSongs {
    NSManagedObjectContext *context = self.container.viewContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Beat"];
    
    NSError *error = nil;
    NSArray *songs = [context executeFetchRequest:request error:&error];
    if (!songs) {
        NSLog(@"Error fetching Beat objects: %@\n%@", [error localizedDescription], [error userInfo]);
    }

    NSMutableArray *songsReversed = [NSMutableArray new];
    for (long i = songs.count - 1; i >= 0; i--) {
        [songsReversed addObject:songs[i]];
    }
	return songsReversed;
}

- (NSURL *)getURLForCachedSong:(NSManagedObjectID *)songID {
    Beat *beatFromSongID = [self getSongForUniqueID:songID];
    NSString *songPath = [beatFromSongID fileUrl];
    NSURL *url = [NSURL fileURLWithPath:songPath];
    return url;
}

- (Beat *)getSongForUniqueID:(NSManagedObjectID *)songID {
    NSManagedObjectContext *context = self.container.viewContext;
    Beat *beatFromSongID = [context objectWithID:songID];
    return beatFromSongID;
}

- (void)deleteSong:(Beat *)song {
    NSManagedObjectContext *context = self.container.viewContext;
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
    NSManagedObjectContext *context = self.container.viewContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Beat"];
    NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetchRequest];
    
    NSError *deleteError = nil;
    [context executeRequest:delete error:&deleteError];
    if (deleteError) {
        NSLog(@"%@", deleteError);
    }
}

- (BOOL)saveSongFromURL:(NSURL *)songURL {
    /** Here's the deal. When this method is called, it's because a user opened their song in our app.
     That means that for us, we are given a temporary URL so we can access the item and do with it what we will.
     So we create a new url (locally) that will hang around, and then copy our file over to the new url, and then save that url in our database.
     */
    return [self saveSongFromURL:songURL ToURL:nil acc:0];
}

- (BOOL)saveSongFromURL:(NSURL *)originalURL ToURL:(NSURL *)newURL acc:(int)accumulator {
    NSURL *newFileURL;
    NSNumber *fileNumber = accumulator == 0 ? nil : [[NSNumber alloc] initWithInt:accumulator];
    if (newURL) {
        newFileURL = [BLPBeatModel uniqueURLFromExistingSongURL:newURL fileNumber:fileNumber];
    } else {
        newFileURL = [BLPBeatModel uniqueURLFromExistingSongURL:originalURL fileNumber:fileNumber];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success = [fileManager copyItemAtURL:originalURL toURL:newFileURL error:&error];
    
    if (success) {
        NSLog(@"The file was successfully saved to path %@", newFileURL);
        NSString *urlStr = newFileURL.absoluteString;
        NSString *fileTitle = [[urlStr lastPathComponent] stringByDeletingPathExtension];
        [self saveSongWith:[fileTitle stringByRemovingPercentEncoding] url:newFileURL.path];
        return YES;
    } else {
        // error code 516 means we couldn't copy because an item with the same name already exists
        // we only want to recur to handle this error. If there's a different error
        // (i.e. original file cannot be found), we should fail. 
        if (accumulator < 20 && error.code == 516) {
            return [self saveSongFromURL:originalURL ToURL:newFileURL acc:accumulator+1];
        } else {
            NSLog(@"Error saving file: %@", error);
            return NO;
        }
    }
}

- (void)saveSongWith:(NSString *)title url:(NSString *)url {
    NSManagedObjectContext *context = self.container.viewContext;
    
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
    NSManagedObjectContext *context = self.container.viewContext;
    
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

- (void)saveFilePath:(NSString *)filePath forSong:(NSManagedObjectID *)songID {
    NSManagedObjectContext *context = self.container.viewContext;

    Beat *beatFromSongID = [context objectWithID:songID];
    beatFromSongID.fileUrl = filePath;

    NSError *error;
    [context save:&error];
    if (error) {
        NSLog(@"There was some error updating: %@", error);
    } else {
        NSLog(@"Saved beat with id %@ named %@ with filePath %@",
              beatFromSongID.objectID,
              beatFromSongID.title,
              beatFromSongID.fileUrl);
    }
}
// If we reinstall the application, all our songs get moved to a new directory.
// So all the paths we store in core data are now wrong, and point to nothing.
// So we need to update the paths of all the entities so they point to the files
// apple so kindly moved to a new location for us.
- (void)updatePathsOfAllEntities {
    NSArray<Beat *> *allSongs = [self getAllSongs];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *documentRootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSArray<NSString *> *allFilesInDocumentsDirectory = [manager contentsOfDirectoryAtPath:documentRootPath error:nil];
    NSMutableDictionary *fileNames = [NSMutableDictionary new];
    for (NSString *fileName in allFilesInDocumentsDirectory) {
        [fileNames setValue:0 forKey:fileName];
    }
    for (Beat *song in allSongs) {
        NSString *name = song.title;
        // NSString *fileTitleFromFileName = [[fileName lastPathComponent] stringByDeletingPathExtension];
        // if ([fileTitleFromFileName isEqualToString:name]) {
        if ([fileNames valueForKey:name] == 0) {
            NSLog(@"Matched fileName %@\nWith name %@", fileName, name);
            NSString *newFilePath = [documentRootPath stringByAppendingPathComponent:fileName];
            [self saveFilePath:newFilePath forSong:song.objectID];
            [fileNames removeObjectForKey:name];
        }
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


+ (NSURL *)uniqueURLFromExistingSongURL:(NSURL *)currentURL fileNumber:(NSNumber *)fileNumber {
    NSLog(@"Current url: %@", currentURL.absoluteString);
    NSString *urlStr = currentURL.absoluteString;
    NSString *fileExtension = [[urlStr lastPathComponent] pathExtension];
    NSString *fileTitle = [[urlStr lastPathComponent] stringByDeletingPathExtension];
    // create path
    NSString *documentRootPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    // append number to filename to ensure songs with same name are saved uniquely
    NSString *uniqueFileTitle;
    if (fileNumber) {
        if (fileNumber.intValue != 1) {
            fileTitle = [fileTitle substringToIndex:fileTitle.length - 1];
        }
        uniqueFileTitle = [NSString stringWithFormat:@"%@%@.%@", fileTitle, fileNumber, fileExtension];
    } else {
        uniqueFileTitle = [NSString stringWithFormat:@"%@.%@", fileTitle, fileExtension];
    }
    NSString *newFilePath = [documentRootPath stringByAppendingPathComponent:uniqueFileTitle];
    NSLog(@"newFilePath: %@", newFilePath);
    return [NSURL fileURLWithPath:newFilePath];
}

@end

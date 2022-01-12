//
//  BLPModelSongsTests.m
//  BeatLooperTests
//
//  Created by Isaak Meier on 1/9/22.
//

#import <XCTest/XCTest.h>
#import "BLPBeatModel.h"

@interface BLPModelSongsTests : XCTestCase

@property BLPBeatModel *model;
@property NSPersistentContainer *mockContainer;

@end

@implementation BLPModelSongsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // this sets up a mock container that we inject into our model, so we can test core data
    // without affecting the actual application
    NSBundle *testBundle = [NSBundle bundleForClass:[BLPModelSongsTests class]];
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[testBundle]];
    self.mockContainer = [[NSPersistentContainer alloc] initWithName:@"BeatModel" managedObjectModel:managedObjectModel];
    NSPersistentStoreDescription *description = [[NSPersistentStoreDescription alloc] init];
    [description setType:NSInMemoryStoreType];
    [description setShouldAddStoreAsynchronously:NO];
    [self.mockContainer setPersistentStoreDescriptions:@[description]];
    [self.mockContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription * _Nonnull description, NSError * _Nullable error) {
        XCTAssertEqual(description.type, NSInMemoryStoreType);
        XCTAssertNil(error);
        if (error) {
            NSLog(@"Error setting up mock container: %@", error);
        }
    }];
    
    self.model = [[BLPBeatModel alloc] initWithContainer:_mockContainer];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.model = nil;
    self.mockContainer = nil;
    // fun. we need to clear out the documents directory
    // because we are saving files & deleting them there between tests.
    NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSError *error = nil;
    NSArray<NSString *> *filePathsInDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error];
    for (NSString *file in filePathsInDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[folderPath stringByAppendingPathComponent:file] error:&error];
    }
    if (error) {
        NSLog(@"Error clearing documents directory: %@", error);
    }
}

- (void)testAddingAndRemovingSongFromDatabase {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSBundle *main = [NSBundle mainBundle];
    NSString *resourceURL1 = [main pathForResource:@"dunevibes" ofType:@"mp3"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self.model saveSongWith:@"duneVibes" url:resourceURL1];
    
    NSArray<Beat *> *songs = [self.model getAllSongs];
    XCTAssertEqual(songs.count, 1);
    Beat *song = songs[0];
    
    XCTAssertTrue([song.title isEqualToString:@"duneVibes"]);
    NSString *fileName = [song.fileUrl lastPathComponent];
    XCTAssertTrue([fileName isEqualToString:@"dunevibes.mp3"]);
    XCTAssertTrue([fileManager fileExistsAtPath:song.fileUrl]);
    
    [self.model deleteSong:song];
    NSArray<Beat *> *emptySongs = [self.model getAllSongs];
    XCTAssertEqual(emptySongs.count, 0); // no songs
    
    XCTAssertFalse([fileManager fileExistsAtPath:song.fileUrl]);
}

- (void)testWonkySongNamesInDatabase {
    NSURL *stubUrl = [NSURL URLWithString:@"stub"];
    [self.model saveSongWith:@"Name With Spaces" url:stubUrl.absoluteString];

    NSArray<Beat *> *songs = [self.model getAllSongs];
    XCTAssertEqual(songs.count, 1);
    Beat *song = songs[0];
    NSString *songTitle = song.title;
    XCTAssertTrue([songTitle isEqualToString:@"Name With Spaces"]);
    [self.model deleteSong:song];
    
    [self.model saveSongWith:@"Name-With1-Number_!And%20 Some //""weird stuff" url:stubUrl.absoluteString];

    songs = [self.model getAllSongs];
    XCTAssertEqual(songs.count, 1);
    song = songs[0];
    songTitle = song.title;
    XCTAssertTrue([songTitle isEqualToString:@"Name-With1-Number_!And%20 Some //""weird stuff"]);
    [self.model deleteSong:song];
}

- (void)testAddingAndRemovingSongFromUrl {
    NSBundle *testBundle = [NSBundle bundleForClass:[BLPModelSongsTests class]];
    NSString *resourceURL1 = [testBundle pathForResource:@"dunevibes" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:resourceURL1];
    
    [self.model saveSongFromURL:url];

    NSArray<Beat *> *songs = [self.model getAllSongs];
    XCTAssertEqual(songs.count, 1);
    Beat *song = songs[0];
    XCTAssertTrue([song.title isEqualToString:@"dunevibes"]);
    NSString *fileName = [song.fileUrl lastPathComponent];
    XCTAssertTrue([fileName isEqualToString:@"dunevibes1.mp3"]);
    
    [self.model deleteSong:song];
    NSArray<Beat *> *emptySongs = [self.model getAllSongs];
    XCTAssertEqual(emptySongs.count, 0); // no songs
}

- (void)testAddingTheSameSongThrice {
    NSBundle *testBundle = [NSBundle bundleForClass:[BLPModelSongsTests class]];
    NSString *resourceURL1 = [testBundle pathForResource:@"dunevibes" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:resourceURL1];
    
    XCTAssertTrue([self.model saveSongFromURL:url]);
    XCTAssertTrue([self.model saveSongFromURL:url]);
    XCTAssertTrue([self.model saveSongFromURL:url]);
    
    NSArray<Beat *> *songs = [self.model getAllSongs];
    XCTAssertEqual(songs.count, 3);
    Beat *song0 = songs[2];
    Beat *song1 = songs[1];
    Beat *song2 = songs[0];
    XCTAssertTrue([song0.title isEqualToString:@"dunevibes"]);
    XCTAssertTrue([song1.title isEqualToString:@"dunevibes"]);
    XCTAssertTrue([song2.title isEqualToString:@"dunevibes"]);
    NSString *fileName0 = [song0.fileUrl lastPathComponent];
    NSString *fileName1 = [song1.fileUrl lastPathComponent];
    NSString *fileName2 = [song2.fileUrl lastPathComponent];
    XCTAssertTrue([fileName0 isEqualToString:@"dunevibes111.mp3"]);
    XCTAssertTrue([fileName1 isEqualToString:@"dunevibes1.mp3"]);
    XCTAssertTrue([fileName2 isEqualToString:@"dunevibes11.mp3"]);
}

- (void)testSavingInvalidSong {
    NSURL *invalidUrl = [NSURL URLWithString:@""];
    XCTAssertFalse([self.model saveSongFromURL:invalidUrl]);
    
    NSArray<Beat *> *songs = [self.model getAllSongs];
    XCTAssertEqual(songs.count, 0);
}

- (void)testWonkySongNamesFromURL {
    NSBundle *testBundle = [NSBundle bundleForClass:[BLPModelSongsTests class]];
    NSString *resourceURL1 = [testBundle pathForResource:@"life's good (ft. double trouble)" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:resourceURL1];
    
    XCTAssertTrue([self.model saveSongFromURL:url]);
    NSArray<Beat *> *songs = [self.model getAllSongs];
    XCTAssertEqual(songs.count, 1);
    Beat *song = songs[0];
    NSString *songTitle = song.title;
    NSLog(@"Song title: %@", songTitle);
    XCTAssertTrue([songTitle isEqualToString:@"life's good (ft. double trouble)"]);
}
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

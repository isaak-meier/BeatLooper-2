//
//  BLPPlayerStateTests.m
//  BeatLooperTests
//
//  Created by Isaak Meier on 1/6/22.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "BLPPlayer.h"
#import "BLPBeatModel.h"
#import <Foundation/Foundation.h>

@interface BLPPlayerStateTests : XCTestCase
@end

@interface BLPPlayerStateTests()
@property BLPPlayer *player;
@property BLPBeatModel *model;
@end

@implementation BLPPlayerStateTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.model = [[BLPBeatModel alloc] init];
    NSArray *songs = [self.model getAllSongs];
    XCTAssertNotNil(songs);
    XCTAssertEqual(songs.count, 5);
    self.player = [[BLPPlayer alloc] initWithSongs:songs];
    XCTAssertNotNil(self.player);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPaused);
}

- (void)testTogglePlayPause {
    XCTAssertTrue([self.player togglePlayOrPause]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPlaying);
    
    XCTAssertTrue([self.player togglePlayOrPause]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPaused);
    
    XCTAssertTrue([self.player togglePlayOrPause]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPlaying);
    
    XCTAssertTrue([self.player togglePlayOrPause]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPaused);
}

- (void)testSkipForward {
    // double skip
    // playing->playing
    XCTAssertTrue([self.player skipForward]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPlaying);
    XCTAssertTrue([self.player skipForward]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPlaying);
    
    // skip when paused
    // paused->playing
    XCTAssertTrue([self.player togglePlayOrPause]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPaused);
    XCTAssertTrue([self.player skipForward]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPlaying);
    XCTAssertTrue([self.player skipForward]);
    XCTAssertTrue([self.player skipForward]); // skipping 5th song should empty player
    
    // skip when empty: empty->empty
    XCTAssertEqual(self.player.playerState, BLPPlayerEmpty);
    XCTAssertFalse([self.player skipForward]);
    XCTAssertEqual(self.player.playerState, BLPPlayerEmpty);
}

- (void)testLooping {
    CMTimeRange range = [BLPBeatModel timeRangeFromBars:8 to:16 withTempo:150];
    // start then stop
    XCTAssertTrue([self.player startLoopingTimeRange:range]);
    XCTAssertEqual(self.player.playerState, BLPPlayerLoopPlaying);
    XCTAssertTrue([self.player stopLooping]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPaused);
    
    // start then play & pause
    XCTAssertTrue([self.player startLoopingTimeRange:range]);
    XCTAssertEqual(self.player.playerState, BLPPlayerLoopPlaying);
    XCTAssertTrue([self.player togglePlayOrPause]);
    XCTAssertEqual(self.player.playerState, BLPPlayerLoopPaused);
    XCTAssertTrue([self.player togglePlayOrPause]);
    XCTAssertEqual(self.player.playerState, BLPPlayerLoopPlaying);
    
    // skip forward
    XCTAssertTrue([self.player skipForward]);
    XCTAssertEqual(self.player.playerState, BLPPlayerSongPlaying);
    XCTAssertTrue([self.player startLoopingTimeRange:range]);
    XCTAssertEqual(self.player.playerState, BLPPlayerLoopPlaying);
    
    // skip backwards
    XCTAssertTrue([self.player skipBackward]);
    XCTAssertEqual(self.player.playerState, BLPPlayerLoopPlaying);
    XCTAssertTrue([self.player startLoopingTimeRange:range]);
    XCTAssertEqual(self.player.playerState, BLPPlayerLoopPlaying);
    XCTAssertTrue([self.player skipBackward]);
    XCTAssertEqual(self.player.playerState, BLPPlayerLoopPlaying);
    
    [self.player skipForward]; // empty player
    [self.player skipForward];
    [self.player skipForward];
    XCTAssertTrue([self.player skipForward]);
    XCTAssertEqual(self.player.playerState, BLPPlayerEmpty);
    
    // empty start & stop loop
    XCTAssertFalse([self.player startLoopingTimeRange:range]);
    XCTAssertEqual(self.player.playerState, BLPPlayerEmpty);
    XCTAssertFalse([self.player startLoopingTimeRange:range]);
    XCTAssertEqual(self.player.playerState, BLPPlayerEmpty);
    XCTAssertFalse([self.player stopLooping]);
    XCTAssertEqual(self.player.playerState, BLPPlayerEmpty);
}

- (void)test {
    NSArray *songs = [self.model getAllSongs];
    
    XCTAssertTrue([self.player changeCurrentSongTo:songs[0]]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.player = nil;
}


@end

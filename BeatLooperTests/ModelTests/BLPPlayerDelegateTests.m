//
//  BLPPlayerDelegateTests.m
//  BeatLooperTests
//
//  Created by Isaak Meier on 1/11/22.
//

#import <XCTest/XCTest.h>
#import "BLPPlayer.h"
#import "BLPBeatModel.h"

@interface BLPPlayerDelegateTests : XCTestCase <BLPPlayerDelegate>
@property XCTestExpectation *titleExpectation;
@property XCTestExpectation *stateExpectation;
@property BLPPlayer *player;
@property NSString *songTitle;
@property BLPPlayerState playerState;
@end

@implementation BLPPlayerDelegateTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDelegateResponseOnInit {
    self.titleExpectation = [[XCTestExpectation alloc] initWithDescription:@"Song title updates"];
    self.stateExpectation = [[XCTestExpectation alloc] initWithDescription:@"State change expectation"];
    
    BLPBeatModel *model = [[BLPBeatModel alloc] init];
    NSArray *songs = [model getAllSongs];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunused-variable"
    BLPPlayer *player = [[BLPPlayer alloc] initWithDelegates:@[self] andSongs:songs];
    #pragma clang diagnostic pop
    [self waitForExpectations:@[self.titleExpectation] timeout:2.0];
    [self waitForExpectations:@[self.stateExpectation] timeout:2.0];
    
    XCTAssertEqual(self.playerState, BLPPlayerSongPaused);
    XCTAssertTrue([self.songTitle isEqualToString:@"forgetMe"]);
}

- (void)testDelegateOnSkippingAndSuch {
    self.titleExpectation = [[XCTestExpectation alloc] initWithDescription:@"Song title updates"];
    
    BLPBeatModel *model = [[BLPBeatModel alloc] init];
    NSArray *songs = [model getAllSongs];
    BLPPlayer *player = [[BLPPlayer alloc] initWithDelegates:@[self] andSongs:songs];
    XCTAssertTrue([player skipForward]);
    [self waitForExpectations:@[self.titleExpectation] timeout:5.0];
    
    XCTAssertEqual(self.playerState, BLPPlayerSongPlaying);
    XCTAssertTrue([self.songTitle isEqualToString:@"swish"]);
    [player skipForward];
    XCTAssertEqual(self.playerState, BLPPlayerSongPlaying);
    XCTAssertTrue([self.songTitle isEqualToString:@"'84"]);
    [player skipBackward];
    XCTAssertEqual(self.playerState, BLPPlayerSongPlaying);
    XCTAssertTrue([self.songTitle isEqualToString:@"'84"]);
    [player skipForward];
    XCTAssertEqual(self.playerState, BLPPlayerSongPlaying);
    XCTAssertTrue([self.songTitle isEqualToString:@"rise"]);
    [player togglePlayOrPause];
    XCTAssertEqual(self.playerState, BLPPlayerSongPaused);
    XCTAssertTrue([self.songTitle isEqualToString:@"rise"]);
}

- (void)testDelegateOnLooping {
    self.stateExpectation = [[XCTestExpectation alloc] initWithDescription:@"State change expectation"];
    
    
    BLPBeatModel *model = [[BLPBeatModel alloc] init];
    NSArray *songs = [model getAllSongs];
    BLPPlayer *player = [[BLPPlayer alloc] initWithDelegates:@[self] andSongs:songs];

    [player startLoopingTimeRange:[BLPBeatModel timeRangeFromBars:0 to:4 withTempo:150]];
    [self waitForExpectations:@[self.stateExpectation] timeout:1.0];
    
    XCTAssertEqual(self.playerState, BLPPlayerLoopPlaying);
    [player togglePlayOrPause];
    XCTAssertEqual(self.playerState, BLPPlayerLoopPaused);
    [player stopLooping];
    XCTAssertEqual(self.playerState, BLPPlayerSongPaused);
}

- (void)playerDidChangeSongTitle:(nonnull NSString *)songTitle {
    self.songTitle = songTitle;
    [self.titleExpectation fulfill];
}

- (void)playerDidChangeState:(BLPPlayerState)state {
    self.playerState = state;
    [self.stateExpectation fulfill];
}

- (void)currentItemDidChangeStatus:(AVPlayerItemStatus)status {
    return;
}


@end

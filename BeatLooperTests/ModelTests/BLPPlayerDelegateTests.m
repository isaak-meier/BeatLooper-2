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
@property XCTestExpectation *expectation;
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

- (void)testExample {
    BLPBeatModel *model = [[BLPBeatModel alloc] init];
    NSArray *songs = [model getAllSongs];
    BLPPlayer *player = [[BLPPlayer alloc] initWithSongs:songs];
    self.expectation = [[XCTestExpectation alloc] initWithDescription:@"Song title updates"];
    [self waitForExpectations:@[self.expectation] timeout:10.0];
    XCTAssertEqual(self.playerState, BLPPlayerSongPaused);
    XCTAssertTrue([self.songTitle isEqualToString:@"forgetMe"]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)playerDidChangeSongTitle:(nonnull NSString *)songTitle withState:(BLPPlayerState)state {
    self.songTitle = songTitle;
    self.playerState = state;
    [self.expectation fulfill];
}

@end

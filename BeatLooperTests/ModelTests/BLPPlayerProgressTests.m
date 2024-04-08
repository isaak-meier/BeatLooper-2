//
//  BLPPlayerProgressTests.m
//  BeatLooperTests
//
//  Created by Isaak Meier on 1/19/22.
//

#import <XCTest/XCTest.h>
#import "BLPPlayer.h"
#import "BLPBeatModel.h"

@interface BLPPlayerProgressTests : XCTestCase <BLPPlayerDelegate>

@property BLPPlayer *player;
@property BLPBeatModel *model;
@property XCTestExpectation *progressExpectation;

@end

@implementation BLPPlayerProgressTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.progressExpectation = [[XCTestExpectation alloc] initWithDescription:@"Status change"];
    // [self waitForExpectations:@[self.progressExpectation] timeout:1.0];
    self.model = [[BLPBeatModel alloc] init];
    self.player = [[BLPPlayer alloc] initWithDelegates:@[self]
                                             andSongs:[self.model getAllSongs]];
    [self waitForExpectations:@[self.progressExpectation] timeout:1.0];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testBasicProgressBar {
    NSProgress *progress = [self.player getProgressForCurrentItem];
    XCTAssertGreaterThan(progress.totalUnitCount, 0);
    [self.player togglePlayOrPause];
    progress = [self.player getProgressForCurrentItem];
    XCTAssertGreaterThan(progress.totalUnitCount, 0);
}

- (void)currentItemDidChangeStatus:(AVPlayerItemStatus)status {
    NSLog(@"fulfilling");
    [self.progressExpectation fulfill];
}

- (void)playerDidChangeSongTitle:(nonnull NSString *)songTitle {
    return;
}


- (void)playerDidChangeState:(BLPPlayerState)state {
    return;
}


@end

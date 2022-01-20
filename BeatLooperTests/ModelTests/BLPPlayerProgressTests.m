//
//  BLPPlayerProgressTests.m
//  BeatLooperTests
//
//  Created by Isaak Meier on 1/19/22.
//

#import <XCTest/XCTest.h>
#import "BLPPlayer.h"
#import "BLPBeatModel.h"

@interface BLPPlayerProgressTests : XCTestCase

@property BLPPlayer *player;
@property BLPBeatModel *model;

@end

@implementation BLPPlayerProgressTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.model = [[BLPBeatModel alloc] init];
    self.player = [[BLPPlayer alloc] initWithSongs:[self.model getAllSongs]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testBasicProgressBar {
    NSProgress *progress = [self.player getProgressForCurrentItem];
    XCTAssertGreaterThan(0, progress.totalUnitCount);
    [self.player togglePlayOrPause];
    progress = [self.player getProgressForCurrentItem];
    XCTAssertGreaterThan(0, progress.totalUnitCount);
    NSLog(@"");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

//
//  BLPModelTimeRangeTests.m
//  BeatLooperTests
//
//  Created by Isaak Meier on 9/11/21.
//

#import <XCTest/XCTest.h>
#import "BLPBeatModel.h"
#import <Foundation/Foundation.h>

@interface BLPModelTimeRangeTests : XCTestCase
@property BLPBeatModel *model;
@end


@implementation BLPModelTimeRangeTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.model = [[BLPBeatModel alloc] init];
    XCTAssertNotNil(self.model);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.model = nil;
}

- (void)testMakeTimeRangeFromBars {
    int startBar = 0;
    int endBar = 4;
    int tempo = 100;

    CMTimeRange fourBarsAt100 = [BLPBeatModel timeRangeFromBars:startBar to:endBar withTempo:tempo];
    CMTimeRange expectedRange = CMTimeRangeMake(CMTimeMake(0, 10000000), CMTimeMake(96000000, 10000000));

    int startComparison = CMTimeCompare(fourBarsAt100.start, expectedRange.start);
    int durationComparison = CMTimeCompare(fourBarsAt100.duration, expectedRange.duration);

    // Use these logs to debug these tests
    NSLog(@"Time duration: %f expected duration %f", CMTimeGetSeconds(fourBarsAt100.duration), CMTimeGetSeconds(expectedRange.duration));
    NSLog(@"Time start: %f expected start: %f", CMTimeGetSeconds(fourBarsAt100.start), CMTimeGetSeconds(expectedRange.start));

    XCTAssertEqual(startComparison, 0);
    XCTAssertEqual(durationComparison, 0);
}

- (void)testMakeTimeRangeFromZeroBars {
    // zero case
    int startBar = 0;
    int endBar = 0;
    int tempo = 100;

    CMTimeRange zeroBarsAt100 = [BLPBeatModel timeRangeFromBars:startBar to:endBar withTempo:tempo];
    CMTimeRange expectedRange = CMTimeRangeMake(CMTimeMake(0, 10000000), CMTimeMake(0, 10000000));

    int startComparison = CMTimeCompare(zeroBarsAt100.start, expectedRange.start);
    int durationComparison = CMTimeCompare(zeroBarsAt100.duration, expectedRange.duration);

    XCTAssertEqual(startComparison, 0);
    XCTAssertEqual(durationComparison, 0);
}

- (void)testMakeTimeRangeFromDifferentBars {
    int startBar = 8;
    int endBar = 12;
    int tempo = 140;

    CMTimeRange fourBarsInMiddle = [BLPBeatModel timeRangeFromBars:startBar to:endBar withTempo:tempo];

    CMTimeRange expectedRange = CMTimeRangeMake(CMTimeMake(137142850, 10000000), CMTimeMake(68571420, 10000000));

    NSLog(@"Time duration: %f expected duration %f", CMTimeGetSeconds(fourBarsInMiddle.duration), CMTimeGetSeconds(expectedRange.duration));
    NSLog(@"Time start: %f expected start: %f", CMTimeGetSeconds(fourBarsInMiddle.start), CMTimeGetSeconds(expectedRange.start));

    int startComparison = CMTimeCompare(fourBarsInMiddle.start, expectedRange.start);
    int durationComparison = CMTimeCompare(fourBarsInMiddle.duration, expectedRange.duration);

    XCTAssertEqual(startComparison, 0);
    XCTAssertEqual(durationComparison, 0);
}

- (void)testMakeTimeRangeFromBarsNegative {
    // negative case
    int startBar = 0;
    int endBar = -4;
    int tempo = 100;

    CMTimeRange zeroBarsAt100 = [BLPBeatModel timeRangeFromBars:startBar to:endBar withTempo:tempo];
    // we expect potential negative time ranges to be zero
    CMTimeRange expectedRange = CMTimeRangeMake(CMTimeMake(0, 10000000), CMTimeMake(0, 10000000));

    int startComparison = CMTimeCompare(zeroBarsAt100.start, expectedRange.start);
    int durationComparison = CMTimeCompare(zeroBarsAt100.duration, expectedRange.duration);

    XCTAssertEqual(startComparison, 0);
    XCTAssertEqual(durationComparison, 0);

    startBar = -4;
    endBar = 0;

    CMTimeRange fourBarsAt100 = [BLPBeatModel timeRangeFromBars:startBar to:endBar withTempo:tempo];

    startComparison = CMTimeCompare(fourBarsAt100.start, expectedRange.start);
    durationComparison = CMTimeCompare(fourBarsAt100.duration, expectedRange.duration);

    XCTAssertEqual(startComparison, 0);
    XCTAssertEqual(durationComparison, 0);

}

@end

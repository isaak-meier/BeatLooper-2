//
//  BLPModelBeatLooperTests.m
//  BeatLooperTests
//
//  Created by Isaak Meier on 9/11/21.
//

#import <XCTest/XCTest.h>
#import "BLPBeatModel.h"
#import <Foundation/Foundation.h>

@interface BLPModelBeatLooperTests : XCTestCase
@end

@interface BLPModelBeatLooperTests ()
@property BLPBeatModel *model;

@end

@implementation BLPModelBeatLooperTests

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
    
    CMTimeRange expectedRange = CMTimeRangeMake(CMTimeMake(0, 10000000), CMTimeMake(9.6, 10000000));
    int startComparison = CMTimeCompare(fourBarsAt100.start, expectedRange.start);
    int durationComparison = CMTimeCompare(fourBarsAt100.duration, expectedRange.duration);
    
    NSLog(@"Time start: %f duration %f", CMTimeGetSeconds(fourBarsAt100.start), CMTimeGetSeconds(fourBarsAt100.duration));

    XCTAssertEqual(startComparison, 0);
    XCTAssertEqual(durationComparison, 0);

}

@end

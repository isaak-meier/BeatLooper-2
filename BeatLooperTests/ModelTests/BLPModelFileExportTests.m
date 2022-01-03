//
//  BLPModelFileExportTests.m
//  BeatLooperTests
//
//  Created by Isaak Meier on 9/14/21.
//

#import <XCTest/XCTest.h>
#import "BLPBeatModel.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVAsset.h>

@interface BLPModelFileExportTests : XCTestCase

@end

@implementation BLPModelFileExportTests

// TODO:
- (void)testBasicFileExport {
    NSURL *songUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"dunevibes" ofType:@"mp3"]];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Fulfilled export expectation."];
    CMTimeRange expectedRange = [BLPBeatModel timeRangeFromBars:0 to:4 withTempo:100];
    
    
    void (^testingCompletion)(BOOL, NSURL *) = ^void(BOOL success, NSURL *exportedSongUrl) {
        XCTAssertTrue(success);
        XCTAssertNotNil(exportedSongUrl);
        
        // create AVAsset to test duration
        AVAsset *assetFromExport = [AVAsset assetWithURL:exportedSongUrl];
        CMTime durationOfExport = assetFromExport.duration;
        int comparison = CMTimeCompare(durationOfExport, expectedRange.duration);
        if (comparison != 0) {
            NSLog(@"Exported song duration: %f expected duration %f", CMTimeGetSeconds(durationOfExport), CMTimeGetSeconds(expectedRange.duration));
        }
        XCTAssertEqual(comparison, 0); // CMTimes are equal
        [expectation fulfill];
    };
    
    [BLPBeatModel exportClippedAudioFromSongURL:songUrl withTempo:100 startingAtTimeInBars:0 endingAtTimeInBars:4 withCompletion:testingCompletion];
    
    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end

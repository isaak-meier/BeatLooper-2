//
//  BLPAudioEngine.m
//  BeatLooper
//
//  Created by Isaak Meier on 7/22/21.
//

#import <AVFoundation/AVFoundation.h>
#import "BLPAudioEngine.h"

@interface BLPAudioEngine() {
    AVAudioEngine *engine;
    AVAudioPlayerNode *playerNode;
    AVAudioPCMBuffer *playerLoopBuffer;
}

@end

@implementation BLPAudioEngine

- (instancetype)initWithSongUrl:(NSURL *)songToLoop {
    self = [super init];
    if (self) {
        [self setupAudioSession];
        [self setupPlayerNodeWithUrl:songToLoop];
        [self setupEngine];
    }
    return self;
}

- (void)setupAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *error;
    BOOL success = [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    double hwSampleRate = 44100.0;
    success = [session setPreferredSampleRate:hwSampleRate error:&error];
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [session setPreferredIOBufferDuration:ioBufferDuration error:&error];
    success = [session setActive:YES error:&error];
    if(!success) {
        NSLog(@"Error setting up audio session with error: %@", [error localizedDescription]);
    }
    //TODO: Handle interruptions and setActive when playing
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)setupPlayerNodeWithUrl:(NSURL *)songUrl {
    playerNode = [[AVAudioPlayerNode alloc] init];
    NSError *error;
    
    AVAudioFile *loopFile = [[AVAudioFile alloc] initForReading:songUrl error:&error];
    
    playerLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[loopFile processingFormat] frameCapacity:(AVAudioFrameCount)[loopFile length]];
    BOOL success = [loopFile readIntoBuffer:playerLoopBuffer error:&error];
    NSAssert(success, @"couldn't read file into buffer, %@", [error localizedDescription]);
}

- (void)setupEngine {
    engine = [[AVAudioEngine alloc] init];
    [engine attachNode:playerNode];
    AVAudioMixerNode *mixerNode = [engine mainMixerNode];
    [engine connect:playerNode to:mixerNode fromBus:0 toBus:0 format:playerLoopBuffer.format];

}

- (void)playLoop {
    // start engine
    if (!engine.isRunning) {
        NSError *error;
        BOOL success;
        success = [engine startAndReturnError:&error];
        NSAssert(success, @"couldn't start engine, %@", [error localizedDescription]);
        NSLog(@"Started Engine");
    }
    [engine prepare];
    [playerNode scheduleBuffer:playerLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
    [playerNode setVolume:1.0f];
    [playerNode play];

}

@end

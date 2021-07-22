//
//  BLPAudioEngine.m
//  BeatLooper
//
//  Created by Isaak Meier on 7/22/21.
//

#import <Foundation/Foundation.h>
#import "BLPAudioEngine.h"

@implementation BLPAudioEngine

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupAudioSession];
        [self setupEngineAndNodes];
    }
    return self;
}

- (void)setupAudioSession {
    
}

- (void)setupEngineAndNodes {
    
}

@end

//
//  BLPAudioEngine.h
//  BeatLooper
//
//  Created by Isaak Meier on 7/22/21.
//

#ifndef BLPAudioEngine_h
#define BLPAudioEngine_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface BLPAudioEngine : NSObject

- (id)initWithSongUrl:(NSURL *)songToLoop;

- (void)playLoop;

@end

NS_ASSUME_NONNULL_END

#endif /* BLPAudioEngine_h */

//
//  BLPPlayer.m
//  BeatLooper
//
//  Created by Isaak Meier on 1/4/22.
//

#import "BLPPlayer.h"
#import "BLPBeatModel.h"
#import <AVFoundation/AVPlayer.h>
@import AVFoundation;
@import AVFAudio.AVAudioSession;
@import MediaPlayer;

@interface BLPPlayer()

@property BLPBeatModel *model;
// this should be the same as above, without the currently playing song
@property NSMutableArray *songsInQueue;
@property NSMutableArray<NSNumber *> *selectedIndexes; // songs selected from queue
@property AVQueuePlayer *player;
@property AVPlayerLooper *beatLooper;

@end

@implementation BLPPlayer

- (instancetype)initWithSongs:(NSArray *)songs {
    if (self = [super init]) {
        if (songs.count > 0) {
            _selectedIndexes = [NSMutableArray new];
            NSMutableArray<AVPlayerItem *> *playerItems = [self setupPlayerItems:songs];
            [self loadPlayerWithItems:playerItems];
            [self configureAudioSession];
            [self setupRemoteTransportControls];
            _playerState = BLPPlayerSongPaused;
        } else {
            self = nil;
        }
    }
    return self;
}

// Sets properties playerItems, currentPlayerItem, and songsInQueue
- (NSMutableArray<AVPlayerItem *> *)setupPlayerItems:(NSArray *)songs {
    NSMutableArray<AVPlayerItem *> *playerItems = [NSMutableArray new];
    _songsInQueue = [NSMutableArray new];
    for (int i = 0; i < songs.count; i++) {
        Beat *currentSong = songs[i];
        NSURL *songURL = [_model getURLForCachedSong:currentSong.objectID];
        AVAsset *songAsset = [AVAsset assetWithURL:songURL];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:songAsset automaticallyLoadedAssetKeys:@[@"playable"]];
        if (i == 0) {
            [playerItems addObject:playerItem];
            // _currentSong = currentSong;
        } else {
            [playerItems addObject:playerItem];
            [_songsInQueue addObject:currentSong];
        }
    }
    return playerItems;
}

- (void)configureAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *error;
    BOOL success = [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    double hwSampleRate = 44100.0;
    success = [session setPreferredSampleRate:hwSampleRate error:&error];
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [session setPreferredIOBufferDuration:ioBufferDuration error:&error];
    success = [session setActive:YES error:&error];
    if(!success) {
        NSLog(@"Error setting up audio session, log all the errors. %@", [error localizedDescription]);
    }
}


- (void)setupRemoteTransportControls {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if ([self togglePlayOrPause]) {
            return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }];
    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if ([self skipForward]) {
            return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }];
    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if ([self skipBackward]) {
            return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }];
}


- (void)loadPlayerWithItems:(NSMutableArray<AVPlayerItem *> *)playerItems {
    self.player = nil;
    self.player = [AVQueuePlayer queuePlayerWithItems:playerItems];
    // KVO
//    [self.player addObserver:self forKeyPath:@"currentItem" options:0 context:nil];
}

#pragma mark - Interface Methods

// Mutates Player State
- (BOOL)togglePlayOrPause {
    switch (self.playerState) {
        case BLPPlayerSongPaused:
            [self.player play];
            self.playerState = BLPPlayerSongPlaying;
            return YES;
        case BLPPlayerLoopPaused:
            [self.player play];
            self.playerState = BLPPlayerLoopPlaying;
            return YES;
        case BLPPlayerSongPlaying:
            [self.player pause];
            self.playerState = BLPPlayerSongPaused;
            return YES;
        case BLPPlayerLoopPlaying:
            [self.player pause];
            self.playerState = BLPPlayerLoopPaused;
            return YES;
        case BLPPlayerEmpty:
            return NO;
    }
//        if (!self.progress) {
//            // need to set up progress bar after play, but only once
//            [self setupProgressBar];
//        }
}

- (BOOL)skipForward {
    BLPPlayerState state = self.playerState;
    if (state == BLPPlayerSongPaused || state == BLPPlayerSongPlaying) {
        [self advanceToNextSong];
        return YES;
    }
    if (state == BLPPlayerLoopPaused || state == BLPPlayerLoopPlaying) {
        [self stopLooping];
        [self advanceToNextSong];
        return YES;
    }
    // else state == BLPPlayerEmpty
    return NO;
}

- (BOOL)skipBackward {
    if (self.playerState != BLPPlayerEmpty) {
        [self.player seekToTime:CMTimeMake(0, 1)];
        return YES;
    } else {
        return NO;
    }
}

- (void)removeSelectedSongs {
    
}

# pragma mark - Private Methods

- (void)advanceToNextSong {
    if (self.playerState != BLPPlayerSongPlaying
        || self.playerState != BLPPlayerSongPaused) {
        NSLog(@"Error: cannot advance songs while looping or empty");
        return;
    }
    BOOL isItemToSkipTo = self.player.items.count > 1;
    if (isItemToSkipTo) {
        [self.player advanceToNextItem];
        // this should never happen, but lets make sure
        if (self.songsInQueue.count != 0) {
            [self.songsInQueue removeObjectAtIndex:0];
        }
        if (self.playerState == BLPPlayerSongPaused) {
            [self togglePlayOrPause];
        }
    } else {
        [self.player removeAllItems];
        self.playerState = BLPPlayerEmpty;
    }
}

- (void)stopLooping {
    if (self.playerState == BLPPlayerLoopPlaying) {
        [self togglePlayOrPause];
        [self stopLooping]; // recurr to hit LoopPaused case
    } else if (self.playerState == BLPPlayerLoopPaused) {
        self.beatLooper = nil;
        [self skipBackward]; // restart song
        self.playerState = BLPPlayerSongPaused;
    } else {
        NSLog(@"Error: Cannot stop looping if we aren't looping.");
        return;
    }
}

#pragma mark - UITableView Datasource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // UITableViewCell *cell = [self.queueTableView dequeueReusableCellWithIdentifier:@"SongQueueCell"];
    UITableViewCell *cell = [[UITableViewCell alloc] init]; // TODO possible point of contention
    Beat *songForCell = self.songsInQueue[indexPath.row];
    cell.textLabel.text = songForCell.title;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.songsInQueue.count;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // [self.removeButton setTitle:@"Remove" forState:UIControlStateNormal]; TODO delegate
    [self.selectedIndexes addObject:[NSNumber numberWithInt:(int)indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    for (int i = 0; i < self.selectedIndexes.count; i++) {
        NSNumber *number = self.selectedIndexes[i];
        if (number.intValue == indexPath.row) {
            [self.selectedIndexes removeObjectAtIndex:i];
        }
    }
    if (self.selectedIndexes.count == 0) {
        // [self.removeButton setTitle:@"Add Songs" forState:UIControlStateNormal];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (sourceIndexPath.row != destinationIndexPath.row) {
        [self moveRowInTableViewAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
        [self moveSongInQueueAtIndex:(sourceIndexPath.row + 1) toIndex:(destinationIndexPath.row + 1)];
    }
}

- (void)moveRowInTableViewAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex {
    if (sourceIndex <= self.songsInQueue.count) {
        Beat *songToMove = self.songsInQueue[sourceIndex];
        [self.songsInQueue removeObjectAtIndex:sourceIndex];
        [self.songsInQueue insertObject:songToMove atIndex:destinationIndex];
    }
}

- (void)moveSongInQueueAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex {
    NSMutableArray<AVPlayerItem *> *items = [NSMutableArray arrayWithArray:self.player.items];
    if (sourceIndex <= items.count && destinationIndex <= items.count) {
        AVPlayerItem *itemToMove = items[sourceIndex];
        [items removeObjectAtIndex:sourceIndex];
        AVPlayerItem *itemToInsertAfter = items[destinationIndex - 1];
        [self.player removeItem:itemToMove];
        [self.player insertItem:itemToMove afterItem:itemToInsertAfter];
    }
}
@end

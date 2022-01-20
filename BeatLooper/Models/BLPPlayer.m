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
@property NSMutableArray *songsInQueue;
@property NSMutableArray<NSNumber *> *selectedIndexes; // songs selected from queue
@property AVQueuePlayer *player;
@property AVPlayerLooper *beatLooper;
// progress bar
@property NSProgress *progress;
@property NSTimer *timer;

@property (nonatomic) BLPPlayerState playerState;
// need to maintain this to provide title for PlayerVC
@property (nonatomic) Beat *currentSong;
@property (weak) id <BLPPlayerDelegate> delegate;
@end

@implementation BLPPlayer

- (void)setCurrentSong:(Beat *)currentSong {
    if (currentSong != _currentSong) {
        NSString *title = currentSong.title ? currentSong.title : @"";
        if ([self.delegate respondsToSelector:@selector(playerDidChangeSongTitle:)]) {
            [self.delegate playerDidChangeSongTitle:title];
        }
    }
}

- (void)setPlayerState:(BLPPlayerState)playerState {
    if (_playerState != playerState) {
        if ([self.delegate respondsToSelector:@selector(playerDidChangeState:)]) {
            [self.delegate playerDidChangeState:playerState];
        }
        _playerState = playerState;
    }
}

#pragma mark - Initialization
- (instancetype)initWithDelegate:(nullable id<BLPPlayerDelegate>)delegate andSongs:(NSArray *)songs {
    if (self = [super init]) {
        if (songs.count > 0) {
            _selectedIndexes = [NSMutableArray new];
            _model = [[BLPBeatModel alloc] init];
            _delegate = delegate;
            NSMutableArray<AVPlayerItem *> *playerItems = [self setupPlayerItems:songs];
            [self loadPlayerWithItems:playerItems];
            [self configureAudioSession];
            [self setupRemoteTransportControls];
        } else {
            self = nil;
        }
    }
    return self;
}

- (instancetype)initWithSongs:(NSArray *)songs {
    return [self initWithDelegate:nil andSongs:songs];
}

- (NSMutableArray<AVPlayerItem *> *)setupPlayerItems:(NSArray *)songs {
    NSMutableArray<AVPlayerItem *> *playerItems = [NSMutableArray new];
    _songsInQueue = [NSMutableArray new];
    for (int i = 0; i < songs.count; i++) {
        Beat *currentSong = songs[i];
        NSURL *songURL = [_model getURLForCachedSong:currentSong.objectID];
        AVAsset *songAsset = [AVAsset assetWithURL:songURL];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:songAsset automaticallyLoadedAssetKeys:@[@"playable"]];
        if (!playerItem) {
            NSLog(@"Couldn't load asset... should error here");
            continue;
        }
        if (i == 0) {
            [playerItems addObject:playerItem];
            [self setCurrentSong:currentSong];
            // [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didAdvanceToNextSong) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
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
    if (self.player) {
        [self setPlayerState:BLPPlayerSongPaused];
    }
    // KVO
    [self.player addObserver:self forKeyPath:@"currentItem"
                     options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                     context:nil];
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
//        CMTime duration = [self.player.currentItem duration];
//        CMTime subtract = CMTimeMakeWithSeconds(2, duration.timescale);
//        [self.player seekToTime:CMTimeSubtract(duration, subtract)];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)startLoopingTimeRange:(CMTimeRange)timeRange {
    if (self.playerState == BLPPlayerEmpty) {
        NSLog(@"Bruh, there's nothing to loop. Error starting loop");
        return NO;
    }
    
    if (self.playerState == BLPPlayerLoopPlaying
        || self.playerState == BLPPlayerLoopPaused) {
        [self stopLooping];
    }
    if (self.playerState == BLPPlayerSongPlaying) {
        [self togglePlayOrPause];
    }
    if (self.playerState == BLPPlayerSongPaused) {
        AVPlayerItem *currentPlayerItem = self.player.currentItem;
        AVPlayerLooper *beatLooper = [[AVPlayerLooper alloc] initWithPlayer:self.player templateItem:currentPlayerItem timeRange:timeRange];
        self.beatLooper = beatLooper;
        self.playerState = BLPPlayerLoopPaused;
        [self togglePlayOrPause];
        return YES;
    }
    NSLog(@"Couldn't loop due to unknown reason (read \"mistake\".");
    return NO;
}

- (BOOL)changeCurrentSongTo:(Beat *)song {
    BOOL success = [self addSongToQueue:song];
    if (success) {
        [self skipForward];
    } else {
        [self togglePlayOrPause];
    }
    return YES; // this should succeed no matter the state
}

- (BOOL)addSongToQueue:(Beat *)song {
    NSArray *items = self.player.items;
    NSURL *songURL = [_model getURLForCachedSong:song.objectID];
    AVAsset *songAsset = [AVAsset assetWithURL:songURL];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:songAsset automaticallyLoadedAssetKeys:@[@"playable"]];
    if (self.playerState != BLPPlayerEmpty && items.count != 0) {
        [self.player insertItem:playerItem afterItem:items[0]];
        [self.songsInQueue insertObject:song atIndex:0];
        return YES;
    } else {
        // if the player has no items, we need to recreate it.
        self.currentSong = song;
        [self loadPlayerWithItems:[NSMutableArray arrayWithObject:playerItem]];
        // NO because we didn't actually add it to the queue
        return NO;
    }
}

// TODO test this
- (void)removeSelectedSongs {
    NSArray<AVPlayerItem *> *items = self.player.items;
    NSMutableArray<AVPlayerItem *> *itemsToRemove = [NSMutableArray new];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];
    for (int i = 0; i < self.selectedIndexes.count; i++) {
        int indexToRemoveAt = self.selectedIndexes[i].intValue;
        AVPlayerItem *itemToRemove = items[indexToRemoveAt + 1]; // items has a 'hidden' 0 element, currently playing
        [itemsToRemove addObject:itemToRemove];
        [indexesToRemove addIndex:indexToRemoveAt];
    }
    [self.songsInQueue removeObjectsAtIndexes:indexesToRemove];
    for (AVPlayerItem *item in itemsToRemove) {
        [self.player removeItem:item];
    }
    [self.selectedIndexes removeAllObjects];
}

- (NSProgress *)getProgressForCurrentItem {
    NSProgress *progress = [[NSProgress alloc] init];
    CMTime songDuration = [self.player.currentItem duration];
    int durationInSeconds = (int)(songDuration.value / songDuration.timescale);
    [progress setTotalUnitCount:durationInSeconds];
    self.progress = progress;
    // set refresh timer so progress is updated
    NSTimer *progressBarRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(incrementProgress) userInfo:nil repeats:YES];
    self.timer = progressBarRefreshTimer;
    return self.progress;
}

# pragma mark - Private Methods

- (void)advanceToNextSong {
    if (self.playerState == BLPPlayerLoopPaused
        || self.playerState == BLPPlayerLoopPlaying
        || self.playerState == BLPPlayerEmpty) {
        NSLog(@"Error: cannot advance songs while looping or empty. State: %d", (int)self.playerState);
        return;
    }
    BOOL isItemToSkipTo = self.player.items.count > 1;
    if (isItemToSkipTo) {
        [self.player advanceToNextItem];
    } else {
        [self.player removeAllItems];
    }
    [self didAdvanceToNextSong];
}

- (void)didAdvanceToNextSong {
    BOOL queueHasItems = self.songsInQueue.count != 0;
    if (queueHasItems) {
        self.currentSong = self.songsInQueue[0];
        [self.songsInQueue removeObjectAtIndex:0];
        if (self.playerState == BLPPlayerSongPaused) {
            [self togglePlayOrPause];
        }
    } else {
        self.playerState = BLPPlayerEmpty;
        self.currentSong = nil;
    }
}

// Sets playerState to SongPaused as long as we're looping
- (BOOL)stopLooping {
    if (self.playerState == BLPPlayerLoopPlaying) {
        [self togglePlayOrPause];
    }
    if (self.playerState == BLPPlayerLoopPaused) {
        self.beatLooper = nil;
        [self skipBackward]; // restart song... might not be ness
        self.playerState = BLPPlayerSongPaused;
        return YES;
    } else {
        NSLog(@"Error: Cannot stop looping if we aren't looping.");
        return NO;
    }
}

- (void)incrementProgress {
    if (self.playerState == BLPPlayerSongPlaying || BLPPlayerLoopPlaying) {
        CMTime currentTime = [self.player.currentItem currentTime];
        int timeInSeconds = (int)(currentTime.value / currentTime.timescale);
        [self.progress setCompletedUnitCount:timeInSeconds];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.player && [keyPath isEqualToString:@"currentItem"]) {
        
        AVPlayerItem *oldItem = change[NSKeyValueChangeOldKey];
        AVPlayerItem *newItem = change[NSKeyValueChangeNewKey];
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        if (oldItem) {
            [defaultCenter removeObserver:self
                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                   object:oldItem];
        }
        if (newItem) {
            [defaultCenter addObserver:self
                              selector:@selector(didAdvanceToNextSong)
                                  name:AVPlayerItemDidPlayToEndTimeNotification
                                object:newItem];
        }
        if (self.playerState == BLPPlayerSongPaused
            || self.playerState == BLPPlayerSongPlaying
            || self.playerState == BLPPlayerEmpty) {
            if (self.player.items.count == self.songsInQueue.count) {
//                [self didAdvanceToNextSong];
            }
        }
//        if (self.player.items.count == self.songsInQueue.count) {
//            if (self.songsInQueue.count != 0) {
//                self.currentSong = self.songsInQueue[0];
//                [self.songsInQueue removeObjectAtIndex:0];
//            }
//            [self.coordinator clearLooperView];
//        }
//        [self refreshVisibleText];
//        [self.queueTableView reloadData];
    }
}

#pragma mark - UITableView Datasource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // UITableViewCell *cell = [self.queueTableView dequeueReusableCellWithIdentifier:@"SongQueueCell"];
    UITableViewCell *cell = [[UITableViewCell alloc] init]; 
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

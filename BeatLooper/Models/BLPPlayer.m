//
//  BLPPlayer.m
//  BeatLooper
//
//  Created by Isaak Meier on 1/4/22.
//

#import "BLPPlayer.h"
#import "BLPBeatModel.h"
@import MediaPlayer;

@interface BLPPlayer()

@property BLPBeatModel *model;
@property (nonatomic, readonly, getter=getSongNames) NSMutableArray *songNames;
@property NSMutableArray<NSNumber *> *selectedIndexes; // songs selected from queue
@property AVQueuePlayer *player;
@property AVPlayerLooper *beatLooper;
// progress bar
@property NSProgress *progress;
@property NSTimer *timer;

@property (nonatomic) BLPPlayerState playerState;
@property (weak) id <BLPPlayerDelegate> delegate;
@end

@implementation BLPPlayer

#pragma mark - Getters n Setters

-  (NSArray<NSString *> *)getSongNames {
    NSMutableArray<NSString *> *currentPlayerItemsAsSongNames = [NSMutableArray<NSString *> new];

    if (self.player && self.player.items) {
        for (int i = 0; i < self.player.items.count; i++) {
            NSString *songName = [BLPBeatModel getSongNameFrom:self.player.items[i]];
            if (i == 0) {
                [self setCurrentSong:songName];
            } else {
                [currentPlayerItemsAsSongNames addObject:songName];
            }
        }
    }
    return currentPlayerItemsAsSongNames;
}

- (void)setCurrentSong:(NSString *)currentSong {
    if ([self.delegate respondsToSelector:@selector(playerDidChangeSongTitle:)]) {
        [self.delegate playerDidChangeSongTitle:currentSong];
    }
    if ([self.delegate respondsToSelector:@selector(didUpdateCurrentProgressTo:)]) {
        [self.delegate didUpdateCurrentProgressTo:0];
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

- (BOOL)isPlayerLooping {
    return self.playerState == BLPPlayerLoopPlaying || self.playerState == BLPPlayerLoopPaused;
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
            [self setupNotifications];
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
            [self addObseversToPlayerItem:playerItem];
        } else {
            [playerItems addObject:playerItem];
        }
    }
    return playerItems;
}

- (void)configureAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    NSError *error;
    BOOL success = [session setCategory:AVAudioSessionCategoryPlayback
                            withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                  error:&error];
    double hwSampleRate = 44100.0;
    success = [session setPreferredSampleRate:hwSampleRate error:&error];
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [session setPreferredIOBufferDuration:ioBufferDuration error:&error];
    success = [session setActive:YES error:&error];
    if(!success) {
        NSLog(@"Error setting up audio session, log all the errors. %@", [error localizedDescription]);
    }
}

- (void)setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    AVAudioSession *session = [AVAudioSession sharedInstance];

    [center addObserver:self selector:@selector(handleInterruptionNotification:)
                   name:AVAudioSessionInterruptionNotification
                 object:session];
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
    } else {
        NSLog(@"Failed to load player");
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
}

- (BOOL)skipForward {
    if (self.playerState == BLPPlayerSongPaused || self.playerState == BLPPlayerSongPlaying) {
        [self advanceToNextSong];
        return YES;
    }
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

- (BOOL)startLoopingTimeRange:(CMTimeRange)timeRange {
    if (self.playerState == BLPPlayerEmpty) {
        NSLog(@"Bruh, there's nothing to loop. Error starting loop");
        return NO;
    }
    
    if (self.isPlayerLooping) {
        [self stopLooping];
    }
    if (self.playerState == BLPPlayerSongPlaying) {
        [self togglePlayOrPause];
    }
    if (self.playerState == BLPPlayerSongPaused) {
        // make sure the time range provided is a subset of the current song
        CMTimeRange totalSongRange = CMTimeRangeMake(CMTimeMake(0, self.player.currentTime.timescale), self.player.currentItem.duration);
        if (CMTimeRangeContainsTimeRange(totalSongRange, timeRange)) {
            AVPlayerItem *currentPlayerItem = self.player.currentItem;
            AVPlayerLooper *beatLooper = [[AVPlayerLooper alloc] initWithPlayer:self.player
                                                                   templateItem:currentPlayerItem
                                                                      timeRange:timeRange];
            self.beatLooper = beatLooper;
            [self setPlayerState:BLPPlayerLoopPaused];
            [self togglePlayOrPause];
            return YES;
        }
    }
    NSLog(@"Couldn't loop due to unknown reason, likely invalid time range.");
    return NO;
}

- (BOOL)changeCurrentSongTo:(Beat *)song {
    if (self.isPlayerLooping) {
        return NO;
    }
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
        return YES;
    } else {
        // if the player has no items, we need to recreate it.
        [self loadPlayerWithItems:[NSMutableArray arrayWithObject:playerItem]];
        // NO because we didn't actually add it to the queue
        return NO;
    }
}

// TODO test this
- (void)removeSelectedSongs {
    NSArray<AVPlayerItem *> *items = self.player.items;
    if (items.count == 0) {
        // saw this happen once
        return;
    }
    NSMutableArray<AVPlayerItem *> *itemsToRemove = [NSMutableArray new];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];
    for (int i = 0; i < self.selectedIndexes.count; i++) {
        int indexToRemoveAt = self.selectedIndexes[i].intValue;
        // items has a 'hidden' 0 element, currently playing
        AVPlayerItem *itemToRemove = items[indexToRemoveAt + 1];
        [itemsToRemove addObject:itemToRemove];
        [indexesToRemove addIndex:indexToRemoveAt];
    }
    for (AVPlayerItem *item in itemsToRemove) {
        [self.player removeItem:item];
    }
    [self.selectedIndexes removeAllObjects];
    [self.delegate requestTableViewUpdate];
}

// Sets up a refresh timer so the progress is updated
- (NSProgress *)getProgressForCurrentItem {
    NSProgress *progress = [[NSProgress alloc] init];
    NSLog(@"creating progress for %@", self.player.currentItem);
    CMTime songDuration = [self.player.currentItem duration];
    int durationInSeconds = (int)(songDuration.value / songDuration.timescale);
    [progress setTotalUnitCount:durationInSeconds];
    self.progress = progress;
    // set refresh timer so progress is updated
    NSTimer *progressBarRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                        target:self
                                                                      selector:@selector(incrementProgress)
                                                                      userInfo:nil
                                                                       repeats:YES];
    self.timer = progressBarRefreshTimer;
    return self.progress;
}

- (BOOL)seekToProgressValue:(float)value {
    if (self.isPlayerLooping) {
        // for now don't let player slide around while looping
        return NO;
    }
    // gotta get CMTIme from progress here
    CMTime duration = self.player.currentItem.duration;
    CMTime requestedTime = CMTimeMultiplyByFloat64(duration, value);
    if (CMTIME_IS_VALID(requestedTime)) {
        [self.player seekToTime:requestedTime];
    }
    return YES;
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
    if (self.playerState == BLPPlayerLoopPaused
        || self.playerState == BLPPlayerLoopPlaying
        || self.playerState == BLPPlayerEmpty) {
        NSLog(@"Did not really advance if we are looping");
        return;
    }
    BOOL queueHasItems = self.songNames.count != 0;
    if (queueHasItems) {
        if (self.playerState == BLPPlayerSongPaused) {
            [self togglePlayOrPause];
        }
        // if we had the any songs selected and the current one skipped,
        // we need to deselect them all.
        if (self.selectedIndexes.count != 0) {
            [self.selectedIndexes removeAllObjects];
            [self.delegate selectedIndexesChanged:self.selectedIndexes.count];
        }
    }
    [self.delegate requestTableViewUpdate];
}

// Sets playerState to SongPaused as long as we're looping
- (BOOL)stopLooping {
    if (self.isPlayerLooping) {
        [self.beatLooper disableLooping];
        self.beatLooper = nil;
        [self skipBackward]; // restart song... might not be ness
        [self.player pause];
        [self setPlayerState:BLPPlayerSongPaused];
        return YES;
    } else {
        NSLog(@"Error: Cannot stop looping if we aren't looping.");
        return NO;
    }
}

- (void)incrementProgress {
    if (self.playerState == BLPPlayerSongPlaying || self.playerState == BLPPlayerLoopPlaying) {
        CMTime currentTime = [self.player.currentItem currentTime];
        int timeInSeconds = (int)(currentTime.value / currentTime.timescale);
        [self.progress setCompletedUnitCount:timeInSeconds];
        if ([self.delegate respondsToSelector:@selector(didUpdateCurrentProgressTo:)]) {
            [self.delegate didUpdateCurrentProgressTo:self.progress.fractionCompleted];
        }
    }
}

- (void)handleInterruptionNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        NSNumber *typeValue = userInfo[AVAudioSessionInterruptionTypeKey];
        AVAudioSessionInterruptionType type = typeValue.unsignedIntValue;
        switch (type) {
            case AVAudioSessionInterruptionTypeBegan:
                NSLog(@"Interrupt began");
                [self setPlayerState:BLPPlayerSongPaused];
                break;
            case AVAudioSessionInterruptionTypeEnded:
                NSLog(@"Interrupt ended");
                [self togglePlayOrPause];
                NSNumber *typeValue = userInfo[AVAudioSessionInterruptionTypeKey];
                AVAudioSessionInterruptionOptions options = typeValue.unsignedIntValue;
                if (options == AVAudioSessionInterruptionOptionShouldResume) {
                    NSLog(@"Should resume");
                }
                break;
        }
    }
}

#pragma mark KVO

- (void)addObseversToPlayerItem:(AVPlayerItem *)item {
    if (item) {
        NSLog(@"Adding observers to item %@", item.description);
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(didAdvanceToNextSong)
                                                   name:AVPlayerItemDidPlayToEndTimeNotification
                                                 object:item];
        [item addObserver:self forKeyPath:@"status" options:0 context:nil];
    }
}

- (void)removeObseversFromPlayerItem:(AVPlayerItem *)item {
    @try {
        if (item) {
            NSLog(@"Removing observer from item %@", item.description);
            [NSNotificationCenter.defaultCenter removeObserver:self
                                                          name:AVPlayerItemDidPlayToEndTimeNotification
                                                        object:item];
            [item removeObserver:self forKeyPath:@"status"];
        }
    } @catch (NSException *exception) {
        NSLog(@"Error there was, hmm, trying to remove observers from objects that have no observers, you are. Exception: %@", exception);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {

    if (!self.isPlayerLooping) {
        if (object == self.player && [keyPath isEqualToString:@"currentItem"]) {
            AVPlayerItem *oldItem = change[NSKeyValueChangeOldKey];
            AVPlayerItem *newItem = change[NSKeyValueChangeNewKey];
            if (oldItem != (AVPlayerItem *) [NSNull null]) {
                [self removeObseversFromPlayerItem:oldItem];
            }
            if (newItem != (AVPlayerItem *) [NSNull null]) {
                [self addObseversToPlayerItem:newItem];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate requestTableViewUpdate];
                    [self.delegate requestProgressBarUpdate];
                });
            } else {
                [self setCurrentSong:@""];
                [self setPlayerState:BLPPlayerEmpty];
            }
        }

        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerItem *itemWithStatusChange = (AVPlayerItem *)object;
            if (!object) {
                NSLog(@"Error casting, returning before crash");
                return;
            }
            AVPlayerItemStatus status = itemWithStatusChange.status;
            // let our view controller handle this
            if ([self.delegate respondsToSelector:@selector(currentItemDidChangeStatus:)]) {
                [self.delegate currentItemDidChangeStatus:status];
            }
        }
    }
}


#pragma mark - UITableView Datasource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSArray<NSString *> *names = [self getSongNames];
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    if (indexPath.row < names.count) {
        cell.textLabel.text = names[indexPath.row];
    }
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray<NSString *> *names = [self getSongNames];
    return names.count;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.selectedIndexes addObject:[NSNumber numberWithInt:(int)indexPath.row]];

    if ([self.delegate respondsToSelector:@selector(selectedIndexesChanged:)]) {
        [self.delegate selectedIndexesChanged:self.selectedIndexes.count];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    for (int i = 0; i < self.selectedIndexes.count; i++) {
        NSNumber *number = self.selectedIndexes[i];
        if (number.intValue == indexPath.row) {
            [self.selectedIndexes removeObjectAtIndex:i];
        }
    }

    if ([self.delegate respondsToSelector:@selector(selectedIndexesChanged:)]) {
        [self.delegate selectedIndexesChanged:self.selectedIndexes.count];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (sourceIndexPath.row != destinationIndexPath.row) {
        [self moveSongInQueueAtIndex:(sourceIndexPath.row + 1) toIndex:(destinationIndexPath.row + 1)];
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

- (void)dealloc {
    [self.player removeObserver:self forKeyPath:@"currentItem"];
    if (self.player.currentItem) {
        [self removeObseversFromPlayerItem:self.player.currentItem];
    }
}

@end

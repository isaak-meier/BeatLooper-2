//
//  PlayerViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import "PlayerViewController.h"
#import "BLPBeatModel.h"
@import MediaPlayer;
@import AVFAudio.AVAudioSession;
@import AVFoundation;

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIProgressView *songProgressBar;
@property (weak, nonatomic) IBOutlet UIButton *loopButton;
@property (weak, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerStatusLabel;
@property (weak, nonatomic) IBOutlet UITableView *queueTableView;
@property (weak, nonatomic) IBOutlet UIButton *skipForwardButton;
@property (weak, nonatomic) IBOutlet UIButton *skipBackButton;
@property (weak, nonatomic) IBOutlet UIButton *removeButton; // also addSongButton

@property BLPBeatModel *model;

@property NSMutableArray<AVPlayerItem *> *playerItems;
// this should be the same as above, without the currently playing song
@property NSMutableArray *songsInQueue;
@property AVQueuePlayer *player;
@property AVPlayerLooper *beatLooper;

@property NSProgress *progress;
@property NSTimer *timer;

@property BOOL isPlaying;
@property BOOL isLooping;

@property NSMutableArray<NSNumber *> *selectedIndexes;

- (void)loadPlayer;
- (void)setupProgressBar;
- (void)incrementProgress;

@end

@implementation PlayerViewController

- (id)initWithSongs:(NSArray *)songs coordinator:coordinator {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"PlayerViewController"])) {
        // assign properties
        _model = [[BLPBeatModel alloc] init];
        _coordinator = coordinator;
        [self setupPlayerItems:songs];
        _selectedIndexes = [NSMutableArray new];
    }
    return self;
}

// Sets properties playerItems, currentPlayerItem, and songsInQueue
- (void)setupPlayerItems:(NSArray *)songs {
    _playerItems = [NSMutableArray new];
    _songsInQueue = [NSMutableArray new];
    for (int i = 0; i < songs.count; i++) {
        Beat *currentSong = songs[i];
        NSURL *songURL = [_model getURLForCachedSong:currentSong.objectID];
        AVAsset *songAsset = [AVAsset assetWithURL:songURL];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:songAsset automaticallyLoadedAssetKeys:@[@"playable"]];
        if (i == 0) {
            [_playerItems addObject:playerItem];
            _currentSong = currentSong;
        } else {
            [_playerItems addObject:playerItem];
            [_songsInQueue addObject:currentSong];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.queueTableView.delegate = self;
    self.queueTableView.dataSource = self;
    [self.queueTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SongQueueCell"];
    [self.queueTableView setEditing:YES];
    [self.queueTableView setAllowsMultipleSelectionDuringEditing:YES];
    
    [self loadPlayer];
    
    [self configureAudioSession];

    [self setupRemoteTransportControls];
}


- (void)viewDidAppear:(BOOL)animated {
    [self refreshVisibleText];
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
        if (self.player.items.count != 0) {
            [self playOrPauseSong:nil];
            return MPRemoteCommandHandlerStatusSuccess;
        } else {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }];
    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self skipForwardButtonTapped:nil];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [self skipBackButtonTapped:nil];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

- (void)updateNowPlayingInfoCenterWithTitle:(NSString *)title {
    MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSDictionary<NSString *, id> *nowPlayingInfo = @{MPMediaItemPropertyTitle : title};
    infoCenter.nowPlayingInfo = nowPlayingInfo;
}

- (void)loadPlayer {
    self.player = nil;
    self.player = [AVQueuePlayer queuePlayerWithItems:self.playerItems];
    // KVO
    [self.player addObserver:self forKeyPath:@"currentItem" options:0 context:nil];
}

- (void)handleExistenceError {
    UIAlertController *alert = [UIAlertController
                                     alertControllerWithTitle:@"Error"
                                     message:@"Sorry, we lost this file. Shittisgone. Please delete and re-add."
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                                    actionWithTitle:@"Haha, Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //Handle your yes please button action here
                                        [[self navigationController] popViewControllerAnimated:YES];
                                        return;
                                    }];
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}


- (IBAction)playOrPauseSong:(id)sender {
    if (!self.isPlaying) {
        if (self.player.items.count == 0) {
            [self animateButtonToPlayIcon:YES];
            return;
        }
        [self.player play];
        [self animateButtonToPlayIcon:NO];
        self.isPlaying = YES;
        if (!self.progress) {
            // need to set up progress bar after play, but only once
            [self setupProgressBar];
        }
    } else {
        [self.player pause];
        [self animateButtonToPlayIcon:YES];
        self.isPlaying = NO;
    }
    [self refreshVisibleText];
}

- (IBAction)skipBackButtonTapped:(id)sender {
    [self.player seekToTime:CMTimeMake(0, 1)];
    if (!self.isPlaying) {
        [self playOrPauseSong:nil];
    }
}

- (IBAction)skipForwardButtonTapped:(id)sender {
    if (self.player.items.count > 1) {
        // this will kick off our KVO method
        if (self.isLooping) {
            [self stopLooping];
        }
        [self.player advanceToNextItem];
    } else {
        self.currentSong = nil;
        self.isPlaying = NO;
        [self animateButtonToPlayIcon:YES];
        // this too kicks off KVO
        [self.player removeAllItems];
    }
}


- (IBAction)loopButtonTapped:(id)sender {
    if (self.currentSong) {
        [self.coordinator openLooperViewForSong:self.currentSong.objectID];
    }
}

- (IBAction)removeButtonTapped:(id)sender {
    if ([self.removeButton.currentTitle isEqualToString:@"Remove"]) {
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
        [self.queueTableView reloadData];
        [self.removeButton setTitle:@"Add Songs" forState:UIControlStateNormal];
    } else {
        [self.coordinator showAddSongsView];
    }
    
}


- (void)startLoopWithTimeRange:(CMTimeRange)timeRange {
    if (self.beatLooper) {
        self.beatLooper = nil;
    }
    
    if (self.isPlaying) {
        [self.player pause];
    }
    
    if (!self.player) {
        [self loadPlayer];
    }
    
    AVPlayerItem *currentPlayerItem = self.player.currentItem;
    AVPlayerLooper *beatLooper = [[AVPlayerLooper alloc] initWithPlayer:self.player templateItem:currentPlayerItem timeRange:timeRange];
    self.beatLooper = beatLooper;
    self.isLooping = YES;
    [self refreshVisibleText];
    if (!self.isPlaying) {
        [self playOrPauseSong:nil];
    } else {
        [self playOrPauseSong:nil];
        [self playOrPauseSong:nil];
    }
}

- (void)stopLooping {
    self.isLooping = NO;
    if (self.beatLooper) {
        self.beatLooper = nil;
    }
    if (self.isPlaying) {
        [self playOrPauseSong:nil];
    }
    [self refreshVisibleText];
}

- (void)changeCurrentSongTo:(Beat *)newSong {
    [self addSongToQueue:newSong];
    if (self.player.items.count >= 1) {
        [self.player advanceToNextItem];
    }
}

- (void)addSongToQueue:(Beat *)song {
    NSArray *items = self.player.items;
    NSURL *songURL = [_model getURLForCachedSong:song.objectID];
    AVAsset *songAsset = [AVAsset assetWithURL:songURL];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:songAsset automaticallyLoadedAssetKeys:@[@"playable"]];
    if (items.count != 0) {
        [self.player insertItem:playerItem afterItem:items[0]];
        [self.songsInQueue insertObject:song atIndex:0];
    } else {
        [self.playerItems removeAllObjects];
        [self.playerItems addObject:playerItem];
        self.currentSong = song;
        [self loadPlayer];
        [self refreshVisibleText];
    }
    [self.queueTableView reloadData];
}

- (void)setupProgressBar {
    NSProgress *progress = [[NSProgress alloc] init];
    CMTime songDuration = [self.player.currentItem duration];
    int durationInSeconds = (int)(songDuration.value / songDuration.timescale);
    [progress setTotalUnitCount:durationInSeconds];
    self.progress = progress;
    [self.songProgressBar setObservedProgress:progress];
    
    // set refresh timer so progress is updated
    NSTimer *progressBarRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(incrementProgress) userInfo:nil repeats:YES];
    self.timer = progressBarRefreshTimer;
}

- (void)incrementProgress {
    if (self.isPlaying) {
        CMTime currentTime = [self.player.currentItem currentTime];
        int timeInSeconds = (int)(currentTime.value / currentTime.timescale);
        [self.progress setCompletedUnitCount:timeInSeconds];
    }
}

- (void)animateButtonToPlayIcon:(BOOL)shouldAnimateToPlayIcon {
    [UIView transitionWithView:self.playButton
                      duration:0.1
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        if (shouldAnimateToPlayIcon) {
            [self.playButton setImage:[UIImage imageNamed:@"icons8-play-button-100"] forState:UIControlStateNormal];
        } else {
            [self.playButton setImage:[UIImage imageNamed:@"icons8-pause-button-100"] forState:UIControlStateNormal];
        }
    }
    completion:nil];

}

- (void)refreshVisibleText {
    NSString *songTitle;
    if (self.currentSong) {
        Beat *song = [self.model getSongForUniqueID:self.currentSong.objectID];
        songTitle = song.title;
    } else {
        songTitle = @"";
        self.isPlaying = NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.songTitleLabel setText:songTitle];
        [self updateNowPlayingInfoCenterWithTitle:songTitle];
        if (self.isLooping) {
            [self.playerStatusLabel setText:@"Now Looping"];
        } else if (self.isPlaying) {
            [self.playerStatusLabel setText:@"Now Playing"];
        } else {
            [self.playerStatusLabel setText:@"Just chillin..."];
        }
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.player && [keyPath isEqualToString:@"currentItem"]) {
        // we need to check if we've advanced the song, or just changed it.
        // if we've advanced the song, the player items will have one less than usual,
        // and we need to remove an item from the tableView
        if (self.player.items.count == self.songsInQueue.count) {
            if (self.songsInQueue.count != 0) {
                self.currentSong = self.songsInQueue[0];
                [self.songsInQueue removeObjectAtIndex:0];
            }
            [self.coordinator clearLooperView];
        }
        [self refreshVisibleText];
        [self.queueTableView reloadData];
    }
}

#pragma mark - UITableView Datasource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.queueTableView dequeueReusableCellWithIdentifier:@"SongQueueCell"];
    Beat *songForCell = self.songsInQueue[indexPath.row];
    cell.textLabel.text = songForCell.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.removeButton setTitle:@"Remove" forState:UIControlStateNormal];
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
        [self.removeButton setTitle:@"Add Songs" forState:UIControlStateNormal];
    }
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.songsInQueue.count;
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

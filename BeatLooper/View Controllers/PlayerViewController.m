//
//  PlayerViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import "PlayerViewController.h"
#import "BLPPlayer.h"
@import MediaPlayer;

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
@property BLPPlayer *playerModel;

@property NSProgress *progress;
@property NSTimer *timer;

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
        _playerModel = [[BLPPlayer alloc] initWithSongs:songs];
    }
    return self;
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
}


- (void)viewDidAppear:(BOOL)animated {
    [self refreshVisibleText];
}



- (void)updateNowPlayingInfoCenterWithTitle:(NSString *)title {
    MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSDictionary<NSString *, id> *nowPlayingInfo = @{MPMediaItemPropertyTitle : title};
    infoCenter.nowPlayingInfo = nowPlayingInfo;
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
    BOOL success = [self.playerModel togglePlayOrPause];
    if (success) {
        BLPPlayerState state = self.playerModel.playerState;
        if (state == BLPPlayerSongPaused || state == BLPPlayerLoopPaused) {
            [self animateButtonToPlayIcon:YES];
        } else if (state == BLPPlayerSongPlaying || state == BLPPlayerLoopPlaying) {
            [self animateButtonToPlayIcon:NO];
        }
        [self refreshVisibleText];
    } else {
        NSLog(@"Play/pause failed on empty player");
    }
}

- (IBAction)skipBackButtonTapped:(id)sender {
    BOOL success = [self.playerModel skipBackward];
    if (!success) {
        NSLog(@"Skipping backward failed");
    }
}

- (IBAction)skipForwardButtonTapped:(id)sender {
    BOOL success = [self.playerModel skipForward];
    if (!success) {
        NSLog(@"Skipping forward failed");
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


@end

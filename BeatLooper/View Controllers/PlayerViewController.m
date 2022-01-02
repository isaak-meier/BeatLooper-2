//
//  PlayerViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import "PlayerViewController.h"
#import "BLPBeatModel.h"
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

@property BLPBeatModel *model;

@property NSMutableArray<AVPlayerItem *> *playerItems;
// this should be the same as above, without the currently playing song
@property NSMutableArray *songsInQueue;
@property Beat *currentSong;
@property AVQueuePlayer *player;
@property AVPlayerLooper *beatLooper;

@property NSProgress *progress;
@property NSTimer *timer;

@property BOOL isPlaying;
@property BOOL isLooping;

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
    
    [self loadPlayer];
    
    [self configureAudioSession];
    
//    [self playOrPauseSong:nil];

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

- (void)loadPlayer {
    self.player = [AVQueuePlayer queuePlayerWithItems:self.playerItems];
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
        [self.player advanceToNextItem];
        self.currentSong = self.songsInQueue[0];
        [self.songsInQueue removeObjectAtIndex:0];
    } else {
        [self.player removeAllItems];
        self.currentSong = nil;
        self.isPlaying = NO;
    }
    
    [self.queueTableView reloadData];
    [self refreshVisibleText];
    
    // TODO nil out looperViewController
}


- (IBAction)loopButtonTapped:(id)sender {
    [self.coordinator openLooperViewForSong:self.currentSong.objectID];
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
        if (self.isLooping) {
            [self.playerStatusLabel setText:@"Now Looping"];
        } else if (self.isPlaying) {
            [self.playerStatusLabel setText:@"Now Playing"];
        } else {
            [self.playerStatusLabel setText:@"Just chillin..."];
        }
    });
}


#pragma mark - UITableView Datasource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.queueTableView dequeueReusableCellWithIdentifier:@"SongQueueCell"];
    Beat *songForCell = self.songsInQueue[indexPath.row];
    cell.textLabel.text = songForCell.title;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.songsInQueue.count;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
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
    Beat *songToMove = self.songsInQueue[sourceIndex];
    [self.songsInQueue removeObjectAtIndex:sourceIndex];
    [self.songsInQueue insertObject:songToMove atIndex:destinationIndex];
}

- (void)moveSongInQueueAtIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex {
    NSMutableArray<AVPlayerItem *> *items = [NSMutableArray arrayWithArray:self.player.items];
    AVPlayerItem *itemToMove = items[sourceIndex];
    [items removeObjectAtIndex:sourceIndex];
    AVPlayerItem *itemToInsertAfter = items[destinationIndex - 1];
    [self.player removeItem:itemToMove];
    [self.player insertItem:itemToMove afterItem:itemToInsertAfter];
}

@end

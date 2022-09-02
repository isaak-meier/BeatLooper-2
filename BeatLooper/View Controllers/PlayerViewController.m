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
@property (weak, nonatomic) IBOutlet UISlider *songProgressSlider;

@property BOOL userIsHoldingSlider;
@property int sliderUpdatesToIgnoreCount;
@property NSArray *songsForPlayer; // need to delay playerModel init until viewDidLoad

@end

@implementation PlayerViewController

- (id)initWithSongs:(NSArray *)songs coordinator:coordinator {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"PlayerViewController"])) {
        // assign properties
        _coordinator = coordinator;
        _songsForPlayer = songs;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!self.playerModel) {
        NSLog(@"timing issue");
    }

    self.queueTableView.delegate = self.playerModel;
    self.queueTableView.dataSource = self.playerModel;
    [self.queueTableView setEditing:YES];
    [self.queueTableView setAllowsMultipleSelectionDuringEditing:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)updateNowPlayingInfoCenterWithTitle:(NSString *)title {
    MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
    if (title) {
        NSDictionary<NSString *, id> *nowPlayingInfo = @{MPMediaItemPropertyTitle : title};
        infoCenter.nowPlayingInfo = nowPlayingInfo;
    }
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    BLPPlayerState state = self.playerModel.playerState;
    NSLog(@"view will appear");
    [self playerDidChangeState:state];
}


- (IBAction)playOrPauseSong:(id)sender {
    BOOL success = [self.playerModel togglePlayOrPause];
    if (success) {
        BLPPlayerState state = self.playerModel.playerState;
        [self updatePlayButtonFromState:state];
    } else {
        NSLog(@"Play/pause failed on empty player");
    }
}

- (void)updatePlayButtonFromState:(BLPPlayerState)state {
    if (state == BLPPlayerSongPaused || state == BLPPlayerLoopPaused) {
        [self animateButtonToPlayIcon:YES];
    } else if (state == BLPPlayerSongPlaying || state == BLPPlayerLoopPlaying) {
        [self animateButtonToPlayIcon:NO];
    }
}

- (void)updateButtonsWithState:(BLPPlayerState)state {
    if (state == BLPPlayerLoopPlaying || state == BLPPlayerLoopPaused) {
        [self.skipForwardButton setHidden:YES];
        [self.removeButton setHidden:YES];
        [self.queueTableView setEditing:NO];
    } else {
        [self.skipForwardButton setHidden:NO];
        [self.removeButton setHidden:NO];
        [self.queueTableView setEditing:YES];
    }
}

- (void)updateSongSubtitleWithState:(BLPPlayerState)state {
    switch (state) {
        case BLPPlayerSongPlaying:
            [self.playerStatusLabel setText:@"Now Playing"];
            return;
        case BLPPlayerSongPaused:
            [self.playerStatusLabel setText:@"Song Paused"];
            return;
        case BLPPlayerLoopPaused:
            [self.playerStatusLabel setText:@"Loop Paused"];
            return;
        case BLPPlayerLoopPlaying:
            [self.playerStatusLabel setText:@"Now Looping"];
            return;
        case BLPPlayerEmpty:
            [self.playerStatusLabel setText:@"Just chillin'"];
            return;
    }
}

- (IBAction)skipBackButtonTapped:(id)sender {
    BOOL success = [self.playerModel skipBackward]; if (!success) {
        NSLog(@"Skipping backward failed");
    }
}

- (IBAction)skipForwardButtonTapped:(id)sender {
    BOOL success = [self.playerModel skipForward];
    if (!success) {
        NSLog(@"Skipping forward failed");
    }
    [self.queueTableView reloadData];
}

- (IBAction)loopButtonTapped:(id)sender {
    if (self.playerModel.playerState != BLPPlayerEmpty) {
        Beat *songToLoop = [[BLPBeatModel new] getSongFromSongName:self.songTitleLabel.text];
        if (songToLoop) {
            BOOL playerIsLooping = self.playerModel.playerState == BLPPlayerLoopPlaying
            || self.playerModel.playerState == BLPPlayerLoopPaused;
            [self.coordinator openLooperViewForSong:songToLoop
                                          isLooping:playerIsLooping];
        } else {
            NSLog(@"ok");
        }
    } else {
        NSLog(@"Player state empty");
    }
}

- (IBAction)removeButtonTapped:(id)sender {
    if ([self.removeButton.currentTitle isEqualToString:@"Remove"]) {
        [self.queueTableView reloadData];
        [self.removeButton setTitle:@"Add Songs" forState:UIControlStateNormal];
        [self.playerModel removeSelectedSongs];
    } else {
        [self.coordinator showAddSongsView];
    }
}
- (IBAction)songSliderDidTouchDown:(id)sender {
    self.userIsHoldingSlider = YES;
}

- (IBAction)songSliderWasReleased:(id)sender {
    if (self.playerModel.playerState == BLPPlayerEmpty) {
        [self.playerStatusLabel setText:@"Just chillin' ;)"];
    } else {
        [self.playerModel seekToProgressValue:self.songProgressSlider.value];
        self.sliderUpdatesToIgnoreCount = 5;
    }
    self.userIsHoldingSlider = NO;
}

- (void)startLoopWithTimeRange:(CMTimeRange)timeRange {
    BOOL success = [self.playerModel startLoopingTimeRange:timeRange];
    if (!success) {
        NSLog(@"Loop failed.");
        [self handleErrorStartingLoop];
    }
}

- (void)handleErrorStartingLoop {
    UIAlertController *alert = [UIAlertController
                                     alertControllerWithTitle:@"Ay va voi"
                                     message:@"Hey Buddy, we couldn't start the loop for some reason. If I had to make an educated guess, it's because you tried to loop what couldn't be looped. That is, the song probably couldn't be looped between the bars that you provided."
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                                    actionWithTitle:@"Haha, Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        //Handle your yes please button action here
                                        return;
                                    }];
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)stopLooping {
    [self.playerModel stopLooping];
}

- (void)changeCurrentSongTo:(Beat *)newSong {
    if (self.playerModel.currentSong != newSong.title) {
        [self.playerModel changeCurrentSongTo:newSong];
    }
}

- (void)addSongToQueue:(Beat *)song {
    [self.playerModel addSongToQueue:song];
    [self.queueTableView reloadData];
}

- (void)setupProgressBar {
    NSLog(@"Setting up progress bar");
    NSProgress *progress = [self.playerModel getProgressForCurrentItem];
    [self.songProgressBar setObservedProgress:progress];
    [self.songProgressSlider setValue:0];
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

#pragma mark BLPPlayerDelegate
- (void)playerDidChangeSongTitle:(NSString *)songTitle {
    [self.songTitleLabel setText:songTitle];
    [self updateNowPlayingInfoCenterWithTitle:songTitle];
}

- (void)playerDidChangeState:(BLPPlayerState)state {
    [self updatePlayButtonFromState:state];
    [self updateSongSubtitleWithState:state];
    [self updateButtonsWithState:state];
    
    if (state == BLPPlayerEmpty) {
        // please kill me
        [self.coordinator playerViewControllerRequestsDeath];
    }
}

- (void)currentItemDidChangeStatus:(AVPlayerItemStatus)status {
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
                // Ready to Play
                NSLog(@"Item ready to play");
                [self setupProgressBar];
                break;
            // TODO handle these cases for the user
            // the songs usually load instantly but there could be a problem
            case AVPlayerItemStatusFailed:
                // Failed. Examine AVPlayerItem.error
                [self.playerStatusLabel setText:@"Failed to load song. Please delete & re-add."];
                NSLog(@"Failed. Examine AVPlayerItem.error");
                break;
            case AVPlayerItemStatusUnknown:
                // Not ready
                NSLog(@"Not ready");
                break;
        }
}

- (void)didUpdateCurrentProgressTo:(double)fractionCompleted {
    if (!self.userIsHoldingSlider) {
        [self.songProgressBar setProgress:fractionCompleted];
        // we ignore a few updates when we seek to a new time because
        // theres a gross visual glitch otherwise
        if (self.sliderUpdatesToIgnoreCount == 0) {
            [self.songProgressSlider setValue:fractionCompleted];
        } else {
            self.sliderUpdatesToIgnoreCount--;
        }
    }
}

// also updates progress bar
- (void)requestTableViewUpdate {
    [self.queueTableView reloadData];
}

- (void)requestProgressBarUpdate {
    [self.songProgressSlider setValue:0.0];
    [self.songProgressBar setProgress:0.0];
    [self setupProgressBar];
}

- (void)selectedIndexesChanged:(NSUInteger)count {
    if (count == 0) {
        [self.removeButton setTitle:@"Add Songs" forState:UIControlStateNormal];
    } else {
        [self.removeButton setTitle:@"Remove" forState:UIControlStateNormal];
    }
}


@end

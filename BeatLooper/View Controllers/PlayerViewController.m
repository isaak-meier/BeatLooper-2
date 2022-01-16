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
@property NSArray *songsForPlayer; // need to delay playerModel init until viewDidLoad

@end

@implementation PlayerViewController

- (id)initWithSongs:(NSArray *)songs coordinator:coordinator {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"PlayerViewController"])) {
        // assign properties
        _model = [[BLPBeatModel alloc] init];
        _coordinator = coordinator;
        _songsForPlayer = songs;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!self.playerModel) {
        self.playerModel = [[BLPPlayer alloc] initWithDelegate:(id<BLPPlayerDelegate>)self andSongs:self.songsForPlayer];
    }

    self.queueTableView.delegate = self.playerModel;
    self.queueTableView.dataSource = self.playerModel;
    [self.queueTableView setEditing:YES];
    [self.queueTableView setAllowsMultipleSelectionDuringEditing:YES];
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
    } else {
        [self.queueTableView reloadData];
    }
}


- (IBAction)loopButtonTapped:(id)sender {
    if (self.playerModel.playerState != BLPPlayerEmpty) {
        [self.coordinator openLooperViewForSong:self.playerModel.currentSong.objectID];
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

- (void)startLoopWithTimeRange:(CMTimeRange)timeRange {
    BOOL success = [self.playerModel startLoopingTimeRange:timeRange];
    if (!success) {
        NSLog(@"Loop failed.");
    }
}

- (void)stopLooping {
    [self.playerModel stopLooping];
}

- (void)changeCurrentSongTo:(Beat *)newSong {
    if (self.playerModel.currentSong.objectID != newSong.objectID) {
        [self.playerModel changeCurrentSongTo:newSong];
    }
}

- (void)addSongToQueue:(Beat *)song {
    [self.playerModel addSongToQueue:song];
    [self.queueTableView reloadData];
}

- (void)setupProgressBar {
    NSProgress *progress = [self.playerModel getProgressForCurrentItem];
    [self.songProgressBar setObservedProgress:progress];
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
- (void)playerDidChangeSongTitle:(NSString *)songTitle withState:(BLPPlayerState)state {
    [self.songTitleLabel setText:songTitle];
    [self playerDidChangeState:state];
    [self setupProgressBar];
    [self updateNowPlayingInfoCenterWithTitle:songTitle];
}

- (void)playerDidChangeState:(BLPPlayerState)state {
    [self updatePlayButtonFromState:state];
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


@end

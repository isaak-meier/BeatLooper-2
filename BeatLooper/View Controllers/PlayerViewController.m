//
//  PlayerViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import "PlayerViewController.h"
#import "BLPBeatModel.h"
#import "BLPAudioEngine.h"
@import AVFAudio.AVAudioSession;
@import AVFoundation;

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIProgressView *songProgressBar;

@property (weak, nonatomic) IBOutlet UITextField *tempoTextField;
@property (weak, nonatomic) IBOutlet UITextField *startBarTextField;
@property (weak, nonatomic) IBOutlet UITextField *endBarTextField;

@property (weak, nonatomic) IBOutlet UIButton *loopButton;
@property (weak, nonatomic) IBOutlet UILabel *songTitleLabel;

@property BLPBeatModel *model;
@property BLPAudioEngine *audioEngine;
@property NSManagedObjectID *songID;
@property AVQueuePlayer *player;
@property AVPlayerItem *playerItem;
@property AVPlayerLooper *beatLooper;
@property NSOperationQueue *loopOperationQueue;
@property NSProgress *progress;
@property NSTimer *timer;
@property int tempo;
@property BOOL isPlaying;

- (void)loadPlayer;
- (void)setupProgressBar;
- (void)incrementProgress;

@end

@implementation PlayerViewController

- (id)initWithSongID:(id)songID {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ((self = [storyboard instantiateViewControllerWithIdentifier:@"PlayerViewController"])) {
        // assign properties
        _model = [[BLPBeatModel alloc] init];
        _songID = songID;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self loadPlayer];
    
    [self setupVisibleText];
//    [self configureAudioSession];
    
    [self setTempo:150];
//    [self playOrPauseSong:nil];

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
    NSURL *songURL = [[self model] getURLForCachedSong:[self songID]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:songURL.path];

    if (!exists) {
        [self handleExistenceError];
    } else {
        NSError *error;
        AVAsset *songAsset = [AVAsset assetWithURL:songURL];
        NSLog(@"Provies precise timing?-> %d", songAsset.providesPreciseDurationAndTiming);
        self.playerItem = [AVPlayerItem playerItemWithAsset:songAsset automaticallyLoadedAssetKeys:@[@"playable"]];
        self.player = [AVQueuePlayer playerWithPlayerItem:self.playerItem];
        if (error) {
            NSLog(@"Error creating AVAudioPlayer: %@", error);
        }
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
                                        return;
                                    }];
    [alert addAction:okButton];
    [[self navigationController] popViewControllerAnimated:YES];
}


- (IBAction)playOrPauseSong:(id)sender {
    if (!self.isPlaying) {
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
}

- (void)initAudioEngine {
    NSURL *songUrl = [[self model] getURLForCachedSong:[self songID]];
    __block BLPAudioEngine *engine;
    void (^completionHandler)(BOOL, NSURL *) = ^void(BOOL success, NSURL *loopFileUrl) {
        if (success) {
            engine = [[BLPAudioEngine alloc] initWithSongUrl:loopFileUrl];
            [engine playLoop];
            self.audioEngine = engine;
        } else {
            NSLog(@"Export failed.");
        }
    };
    int startBar = 8;
    int endBar = 12;
    self.tempo = 140;
    [BLPBeatModel exportClippedAudioFromSongURL:songUrl withTempo:self.tempo startingAtTimeInBars:startBar endingAtTimeInBars:endBar withCompletion:completionHandler];
}

- (IBAction)loopButtonTapped:(id)sender {
    
    CMTimeRange timeRangeOfLoop = [BLPBeatModel timeRangeFromBars:8 to:12 withTempo:143];
    AVPlayerLooper *beatLooper = [[AVPlayerLooper alloc] initWithPlayer:self.player templateItem:self.playerItem timeRange:timeRangeOfLoop];
    self.beatLooper = beatLooper;
    [self.player play];
    
//    if ([self.loopButton.currentTitle isEqual: @"Looping"]) {
//        if (self.loopOperationQueue) { // assert operation queue exists
//            [self.loopOperationQueue cancelAllOperations];
//        }
//        [self.loopButton setTitle:@"Loop" forState:UIControlStateNormal];
//
//    } else {
//        [self.player setCurrentTime:0];
//        [self.player play];
//
//        [self.loopButton setTitle:@"Looping" forState:UIControlStateNormal];
//        [self.loopButton sizeToFit];
//        [self addLoopingOperationToQueue];
//    }

}

- (void)setupProgressBar {
    NSProgress *progress = [[NSProgress alloc] init];
    CMTime songDuration = [self.player.currentItem duration];
    int durationInSeconds = (int)(songDuration.value / songDuration.timescale);
    [progress setTotalUnitCount:durationInSeconds];
    self.progress = progress;
    [self.songProgressBar setObservedProgress:progress];
    
    // set refresh timer so progress is updated
    NSTimer *progressBarRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(incrementProgress) userInfo:nil repeats:YES];
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
                      duration:0.2
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

- (void)setupVisibleText {
    Beat *song = [self.model getSongForUniqueID:self.songID];
    [self.songTitleLabel setText:song.title];    
}

//- (void)viewWillDisappear:(BOOL)animated {
//    [self.player stop];
//    [[AVAudioSession sharedInstance] setActive:NO error:nil];
//}


// Pass 0.25 for quarter note, 1 for bar, 4 for phrase.
- (double)secondsFromTempoWithBars:(int)duration {
    return 1.0 / (double)self.tempo * 60.0 * 4.0 * duration;
}

// MARK: UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.tempoTextField) {
        [textField resignFirstResponder];
        NSString *tempoStr = [textField text];
        [self setTempo:[tempoStr intValue]];
        return NO;
    }
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  PlayerViewController.m
//  BeatLooper
//
//  Created by Isaak Meier on 5/6/21.
//

#import "PlayerViewController.h"
#import "BLPBeatModel.h"

@interface PlayerViewController ()

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIProgressView *songProgressBar;
@property (weak, nonatomic) IBOutlet UITextField *tempoTextField;
@property BLPBeatModel *model;
@property NSManagedObjectID *songID;
@property AVAudioPlayer *player;
@property NSProgress *progress;
@property NSTimer *timer;

- (void)loadPlayer;
- (void)setupProgressBar;
- (void)beginIncrementingProgress;

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
    [self setupProgressBar];
    Beat *song = [self.model getSongForUniqueID:self.songID];
    [self setTitle:song.title];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self playOrPauseSong:nil];
}

- (void)loadPlayer {
    NSURL *resourceUrl = [[self model] getURLForCachedSong:[self songID]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:resourceUrl.path];

    if (!exists) {
        [self handleExistenceError];
    } else {
        NSError *error;
        [self setPlayer:[[AVAudioPlayer alloc] initWithContentsOfURL:resourceUrl error:&error]];
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
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setupProgressBar {
    NSProgress *progress = [[NSProgress alloc] init];
    NSTimeInterval songLength = (NSInteger)([self.player duration] * 100);
    [progress setTotalUnitCount:songLength];
    [self setProgress:progress];
    [self.songProgressBar setObservedProgress:progress];
}

- (IBAction)playOrPauseSong:(id)sender {
    if ([self player].playing) {
        [[self player] stop];
        [self.timer invalidate];
        [self animateButtonToPlayIcon:YES];

    } else {
        [[self player] play];
        NSTimer *progressBarRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(beginIncrementingProgress) userInfo:nil repeats:YES];
        [self setTimer:progressBarRefreshTimer];
        [self animateButtonToPlayIcon:NO];
    }
}

- (void)beginIncrementingProgress {
    if ([self.player isPlaying]) {
        NSTimeInterval currentTime = (NSInteger)([self.player currentTime] * 100);
        [self.progress setCompletedUnitCount:currentTime];
    }
}


// TODO: make this work
- (void)animateButtonToPlayIcon:(BOOL)shouldAnimateToPlayIcon {
    [UIView transitionWithView:self.playButton
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        if (shouldAnimateToPlayIcon) {
            [self.playButton setImage:[UIImage imageNamed:@"icons8-play (1)"] forState:UIControlStateNormal];
        } else {
            [self.playButton setImage:[UIImage imageNamed:@"icons8-play (12)"] forState:UIControlStateNormal];
        }
    }
                    completion:nil];


}

- (void)viewWillDisappear:(BOOL)animated {
    [self.player stop];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
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

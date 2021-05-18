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
@property BLPBeatModel *model;
@property NSManagedObjectID *songID;
@property AVAudioPlayer *player;

- (void)loadPlayer;

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
    [[[self playButton] imageView] setContentMode:UIViewContentModeScaleAspectFit];
    [self loadPlayer];
}

- (void)loadPlayer {
//     NSURL *songUrl = [[self model] getURLForCachedSong:[self songID]];
//    NSString *resourceURL = [[NSBundle mainBundle] pathForResource:@"temp" ofType:@"mp3"];

    NSString *resourceUrl = @"/Users/isaak/Library/Developer/CoreSimulator/Devices/60B08052-9106-472A-BBD6-FBB004BE872E/data/Containers/Data/Application/5F82B57F-A319-4258-8BCD-664B8BAD15A8/Library/Ok.mp3";
    NSURL *url = [[NSURL alloc] initFileURLWithPath:resourceUrl];

    NSError *error;
    [self setPlayer:[[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error]];
    if (error) {
        NSLog(@"Error creating AVAudioPlayer: %@", error);
    }
}

- (IBAction)playOrPauseSong:(id)sender {
    if ([self player].playing) {
        [[self player] stop];
    } else {
        [[self player] play];
    }
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
